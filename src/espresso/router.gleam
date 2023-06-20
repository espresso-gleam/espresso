import cowboy/cowboy.{RouterRoute, ServiceRoute}
import espresso/request.{Request}
import espresso/response.{Response}
import espresso/service.{Middleware, Service}
import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/list
import gleam/map.{Map}
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
  ServiceHandler(Map(Method, Service(req, res)))
  RouterHandler(Router(req, res))
}

pub type Router(req, res) {
  Router(
    middleware: Middleware(req, res, BitString, BitBuilder),
    handlers: Map(String, Handler(req, res)),
  )
}

pub fn new(middleware: Middleware(req, res, BitString, BitBuilder)) {
  Router(middleware: middleware, handlers: map.new())
}

fn add_service_handler(
  router: Router(req, res),
  path: String,
  method: Method,
  handler: Service(req, res),
) {
  let handlers =
    map.update(
      router.handlers,
      path,
      fn(existing_handler) {
        case existing_handler {
          Some(ServiceHandler(routes)) ->
            ServiceHandler(map.insert(routes, method, handler))
          None -> ServiceHandler(map.from_list([#(method, handler)]))
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

pub fn router(
  router: Router(req, res),
  path: String,
  subrouter: Router(req, res),
) -> Router(req, res) {
  Router(..router, handlers: expand(path, router.handlers, subrouter))
}

pub fn expand(
  path: String,
  handlers: Map(String, Handler(req, res)),
  router: Router(req, res),
) -> Map(String, Handler(req, res)) {
  map.fold(
    router.handlers,
    handlers,
    fn(acc, key, value) {
      case value {
        RouterHandler(subrouter) -> {
          expand(path <> key, acc, subrouter)
        }
        ServiceHandler(routes) -> {
          map.insert(acc, path <> key, ServiceHandler(routes))
        }
      }
    },
  )
}

pub fn handle(
  router: Router(req, res),
  routes: Map(Method, Service(req, res)),
) -> Service(BitString, BitBuilder) {
  fn(req: Request(BitString)) -> Response(BitBuilder) {
    let method = req_to_method(req)
    let handler = map.get(routes, method)

    case handler {
      Ok(handler) -> router.middleware(handler)(req)
      Error(_) ->
        404
        |> response.new()
        |> response.set_body(bit_builder.from_string("Not found"))
    }
  }
}

pub fn to_routes(router: Router(req, res)) {
  router.handlers
  |> map.to_list()
  |> list.map(fn(route_handler: #(String, Handler(req, res))) {
    let #(path, handler) = route_handler
    let service = case handler {
      ServiceHandler(routes) -> {
        let r = handle(router, routes)
        ServiceRoute(r)
      }
      RouterHandler(router) -> RouterRoute(to_routes(router))
    }
    #(path, service)
  })
  |> map.from_list()
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
