import gleam/bit_builder.{BitBuilder}
import gleam/http
import espresso/cowboy/cowboy.{
  EspressoMiddleware, EspressoService, RouterRoute, ServiceRoute,
}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/map.{Map}
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
  ServiceHandler(Map(Method, EspressoService(req, res)))
  RouterHandler(Router(req, res))
}

pub type Router(req, res) {
  Router(
    middleware: EspressoMiddleware(req, res, BitString, BitBuilder),
    handlers: Map(String, Handler(req, res)),
  )
}

pub fn passthrough_middleware() {
  fn(a) { a }
}

pub fn new(middleware: EspressoMiddleware(req, res, BitString, BitBuilder)) {
  Router(middleware: middleware, handlers: map.new())
}

fn add_service_handler(
  router: Router(req, res),
  path: String,
  method: Method,
  handler: EspressoService(req, res),
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
  handler: EspressoService(req, res),
) -> Router(req, res) {
  add_service_handler(router, path, GET, handler)
}

pub fn post(
  router: Router(req, res),
  path: String,
  handler: EspressoService(req, res),
) -> Router(req, res) {
  add_service_handler(router, path, POST, handler)
}

pub fn router(
  router: Router(req, res),
  path: String,
  subrouter: Router(req, res),
) -> Router(req, res) {
  let handlers =
    map.update(
      router.handlers,
      path,
      fn(existing_handler) {
        case existing_handler {
          None -> RouterHandler(subrouter)
          // this should be an error
          Some(a) -> a
        }
      },
    )
  Router(..router, handlers: handlers)
}

pub fn handle(
  router: Router(req, res),
  routes: Map(Method, EspressoService(req, res)),
) -> EspressoService(BitString, BitBuilder) {
  fn(req: Request(BitString), params) -> Response(BitBuilder) {
    let method = req_to_method(req)
    let handler = map.get(routes, method)

    case handler {
      Ok(handler) -> router.middleware(handler)(req, params)
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
