import gleam/bit_builder.{BitBuilder}
import gleam/http
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/map.{Map}

pub type Route {
  Get(String)
  Post(String)
  Patch(String)
  Put(String)
  Delete(String)
}

pub type Router(a, b) {
  Router(handlers: Map(Route, fn(Request(a)) -> Response(b)))
}

pub fn new() {
  Router(handlers: map.new())
}

pub fn get(
  router: Router(a, b),
  route: String,
  handler: fn(Request(a)) -> Response(b),
) -> Router(a, b) {
  let handlers = map.insert(router.handlers, Get(route), handler)
  Router(handlers: handlers)
}

pub fn post(
  router: Router(a, b),
  route: String,
  handler: fn(Request(a)) -> Response(b),
) -> Router(a, b) {
  let handlers = map.insert(router.handlers, Post(route), handler)
  Router(handlers: handlers)
}

pub fn handle(
  router: Router(BitString, BitBuilder),
  req: Request(BitString),
) -> Response(BitBuilder) {
  let route = req_to_route(req)
  let handler = map.get(router.handlers, route)

  case handler {
    Ok(handler) -> handler(req)
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
