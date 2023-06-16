import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Middleware, Service}
import gleam/map.{Map}
import gleam/list

pub type Route {
  All(String)
  Get(String)
  Post(String)
  Patch(String)
  Put(String)
  Delete(String)
}

pub type Handler(req, res) {
  ServiceHandler(Service(req, res))
  RouterHandler(Router(req, res))
}

pub type Router(req, res) {
  Router(
    middleware: Middleware(req, res, BitString, BitBuilder),
    handlers: Map(Route, Handler(req, res)),
  )
}

pub fn passthrough_middleware() {
  fn(a) { a }
}

pub fn new(middleware: Middleware(req, res, BitString, BitBuilder)) {
  Router(middleware: middleware, handlers: map.new())
}

pub fn get(
  router: Router(req, res),
  route: String,
  handler: Service(req, res),
) -> Router(req, res) {
  let handlers =
    map.insert(router.handlers, Get(route), ServiceHandler(handler))
  Router(..router, handlers: handlers)
}

pub fn post(
  router: Router(req, res),
  route: String,
  handler: Service(req, res),
) -> Router(req, res) {
  let handlers =
    map.insert(router.handlers, Post(route), ServiceHandler(handler))
  Router(..router, handlers: handlers)
}

pub fn router(
  router: Router(req, res),
  route: String,
  subrouter: Router(req, res),
) -> Router(req, res) {
  let handlers =
    map.insert(router.handlers, All(route), RouterHandler(subrouter))
  Router(..router, handlers: handlers)
}

pub fn handle(
  router: Router(req, res),
  req: Request(BitString),
) -> Response(BitBuilder) {
  let route = req_to_route(req)
  let handler = map.get(router.handlers, route)

  case handler {
    Ok(_handler) ->
      response.new(204)
      |> response.set_body(bit_builder.from_string(""))
    Error(_) ->
      404
      |> response.new()
      |> response.set_body(bit_builder.from_string("Not found"))
  }
}

pub fn to_routes(router: Router(req, res)) {
  router.handlers
  |> map.to_list()
  |> list.map(fn(route_handler: #(Route, Handler(req, res))) {
    let #(route, handler) = route_handler
    let method_path = case route {
      All(path) -> #("_", path)
      Get(path) -> #("GET", path)
      Post(path) -> #("POST", path)
      Put(path) -> #("PUT", path)
      Patch(path) -> #("PATCH", path)
      Delete(path) -> #("DELETE", path)
    }
    let service = case handler {
      ServiceHandler(service) -> router.middleware(service)
      RouterHandler(_router) -> todo
    }
    #(method_path, service)
  })
  |> map.from_list()
}

fn req_to_route(req: Request(a)) {
  let path = req.path
  case req.method {
    http.Get -> Get(path)
    http.Post -> Post(path)
    http.Patch -> Patch(path)
    http.Put -> Put(path)
    http.Delete -> Delete(path)
    _ -> Get(path)
  }
}
