import gleam/erlang/process
import gleam/erlang/os
import gleam/http/cowboy
import gleam/http
import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/bit_builder.{BitBuilder}
import gleam/int
import gleam/result
import gleam/map.{Map}
import gleam/io
import gleam/json
import gleam/list
import cat

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

pub fn get(
  router: Router(a, b),
  route: String,
  handler: fn(Request(a)) -> Response(b),
) -> Router(a, b) {
  let handlers = map.insert(router.handlers, Get(route), handler)
  Router(handlers: handlers)
}

pub fn json(res: Response(a), data: json.Json) -> Response(BitBuilder) {
  res
  |> response.set_header("Content-Type", "application/json")
  |> response.set_body(
    data
    |> json.to_string_builder()
    |> bit_builder.from_string_builder(),
  )
}

pub fn handle(
  router: Router(a, BitBuilder),
  req: Request(a),
) -> Response(BitBuilder) {
  let path = req.path
  let route = case req.method {
    http.Get -> Get(path)
    http.Post -> Post(path)
    http.Patch -> Patch(path)
    http.Put -> Put(path)
    http.Delete -> Delete(path)
    _ -> Get(path)
  }
  let handler = map.get(router.handlers, route)

  case handler {
    Ok(handler) -> handler(req)
    Error(_) ->
      404
      |> response.new()
      |> response.set_body(bit_builder.from_string("Not found"))
  }
}

external fn exit(i32) -> Nil =
  "Elixir.Process" "exit/1"

pub fn main() {
  let port =
    "PORT"
    |> os.get_env()
    |> result.unwrap("3000")
    |> int.parse()
    |> result.unwrap(3000)

  let router =
    Router(handlers: map.new())
    |> get(
      "/",
      fn(req: Request(a)) {
        io.debug(req)
        202
        |> response.new()
        |> response.set_body(bit_builder.from_string("Main route"))
      },
    )
    |> get(
      "/bananas",
      fn(_req: Request(a)) {
        200
        |> response.new()
        |> response.set_body(bit_builder.from_string("We're bananas"))
      },
    )
    |> get(
      "/json",
      fn(req: Request(a)) {
        let name =
          req
          |> request.get_query()
          |> result.unwrap([])
          |> list.key_find("name")
          |> result.unwrap("")

        200
        |> response.new()
        |> json(
          name
          |> cat.new()
          |> cat.encode(),
        )
      },
    )

  case cowboy.start(fn(request) { handle(router, request) }, on_port: port) {
    Ok(_) -> process.sleep_forever()
    Error(_) -> exit(1)
  }
}
