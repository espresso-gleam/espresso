import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Middleware, Service}
import gleam/map.{Map}

pub type Route {
  Get(String)
  Post(String)
  Patch(String)
  Put(String)
  Delete(String)
}

pub type Router(req, res) {
  Router(
    middleware: Middleware(req, res, BitString, BitBuilder),
    handlers: Map(Route, Service(req, res)),
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
  let handlers = map.insert(router.handlers, Get(route), handler)
  Router(middleware: router.middleware, handlers: handlers)
}

pub fn post(
  router: Router(req, res),
  route: String,
  handler: Service(req, res),
) -> Router(req, res) {
  let handlers = map.insert(router.handlers, Post(route), handler)
  Router(middleware: router.middleware, handlers: handlers)
}

pub fn handle(
  router: Router(req, res),
  req: Request(BitString),
) -> Response(BitBuilder) {
  let route = req_to_route(req)
  let handler = map.get(router.handlers, route)

  case handler {
    Ok(handler) -> router.middleware(handler)(req)
    Error(_) ->
      404
      |> response.new()
      |> response.set_body(bit_builder.from_string("Not found"))
  }
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
