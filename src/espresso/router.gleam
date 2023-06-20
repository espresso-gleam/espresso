import cowboy/cowboy.{Route, RouterRoute, ServiceRoute, StaticRoute}
import espresso/ordered_map.{OrderedMap}
import espresso/request.{Request}
import espresso/response.{Response}
import espresso/service.{Middleware, Service}
import espresso/static.{Static}
import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/list
import gleam/option.{None, Some}

pub type Method {
  ALL
  GET
  POST
  PATCH
  PUT
  DELETE
  HEAD
  OPTIONS
}

pub type Handler(req, res) {
  ServiceHandler(OrderedMap(Method, Service(req, res)))
  RouterHandler(Router(req, res))
  StaticHandler(String, Static)
}

pub type Router(req, res) {
  Router(
    middleware: Middleware(req, res, BitString, BitBuilder),
    handlers: OrderedMap(String, Handler(req, res)),
  )
}

pub fn new() {
  Router(middleware: fn(x) { x }, handlers: ordered_map.new())
}

fn add_service_handler(
  router: Router(req, res),
  path: String,
  method: Method,
  handler: Service(req, res),
) {
  let handlers =
    ordered_map.update(
      router.handlers,
      path,
      fn(existing_handler) {
        case existing_handler {
          Some(ServiceHandler(routes)) ->
            ServiceHandler(ordered_map.insert(routes, method, handler))
          None -> ServiceHandler([#(method, handler)])
          // this should be an error
          Some(a) -> a
        }
      },
    )
  Router(..router, handlers: handlers)
}

pub fn get(
  router: Router(req, res),
  path: String,
  handler: Service(req, res),
) -> Router(req, res) {
  add_service_handler(router, path, GET, handler)
}

pub fn post(
  router: Router(req, res),
  path: String,
  handler: Service(req, res),
) -> Router(req, res) {
  add_service_handler(router, path, POST, handler)
}

pub fn put(
  router: Router(req, res),
  path: String,
  handler: Service(req, res),
) -> Router(req, res) {
  add_service_handler(router, path, PUT, handler)
}

pub fn patch(
  router: Router(req, res),
  path: String,
  handler: Service(req, res),
) -> Router(req, res) {
  add_service_handler(router, path, PATCH, handler)
}

pub fn delete(
  router: Router(req, res),
  path: String,
  handler: Service(req, res),
) -> Router(req, res) {
  add_service_handler(router, path, DELETE, handler)
}

/// Handles a request for a given path and returns static files
/// Currently only supports File and Directory
/// 
/// # Examples
/// 
/// ```gleam
/// import espresso/router
/// import espreso/static
///
/// // Serves all files in the priv/public directory for any request starting with /public
/// router.new()
/// |> router.static("/public/[...]", static.Dir("priv/public"))
/// 
/// // Serves only the index.html file from the priv/public directory
/// router.new()
/// |> router.static("/", static.File("priv/public/index.html"))
/// ```
/// 
pub fn static(
  router: Router(req, res),
  path: String,
  config: Static,
) -> Router(req, res) {
  let handlers =
    ordered_map.insert(router.handlers, path, StaticHandler(path, config))
  Router(..router, handlers: handlers)
}

pub fn router(
  router: Router(req, res),
  path: String,
  subrouter: Router(req, res),
) -> Router(req, res) {
  Router(..router, handlers: expand(path, router.handlers, subrouter))
}

pub fn expand(
  path: String,
  handlers: OrderedMap(String, Handler(req, res)),
  router: Router(req, res),
) -> OrderedMap(String, Handler(req, res)) {
  ordered_map.fold(
    router.handlers,
    handlers,
    fn(acc, key, value) {
      case value {
        RouterHandler(subrouter) -> {
          expand(path <> key, acc, subrouter)
        }
        ServiceHandler(routes) -> {
          ordered_map.insert(acc, path <> key, ServiceHandler(routes))
        }
        StaticHandler(path, config) -> {
          ordered_map.insert(acc, path <> key, StaticHandler(path, config))
        }
      }
    },
  )
}

pub fn handle(
  router: Router(req, res),
  routes: OrderedMap(Method, Service(req, res)),
) -> Service(BitString, BitBuilder) {
  fn(req: Request(BitString)) -> Response(BitBuilder) {
    let method = req_to_method(req)
    let handler = ordered_map.get(routes, method)

    case handler {
      Some(handler) -> router.middleware(handler)(req)
      None ->
        404
        |> response.new()
        |> response.set_body(bit_builder.from_string("Not found"))
    }
  }
}

pub fn to_routes(router: Router(req, res)) -> OrderedMap(String, Route) {
  router.handlers
  |> list.map(fn(route_handler: #(String, Handler(req, res))) {
    let #(path, handler) = route_handler
    let service = case handler {
      ServiceHandler(routes) -> {
        let r = handle(router, routes)
        ServiceRoute(r)
      }
      RouterHandler(router) -> RouterRoute(to_routes(router))
      StaticHandler(path, config) -> StaticRoute(path, config)
    }
    #(path, service)
  })
}

fn req_to_method(req: Request(a)) {
  case req.method {
    http.Get -> GET
    http.Post -> POST
    http.Patch -> PATCH
    http.Put -> PUT
    http.Delete -> DELETE
    _ -> GET
  }
}
