import gleam/erlang/process
import gleam/erlang/os
import gleam/http/cowboy
import gleam/http/response.{Response}
import gleam/http/request.{Request}
import gleam/bit_builder.{BitBuilder}
import gleam/int
import gleam/result
import gleam/map.{Map}

pub type App {
  App(handlers: Map(String, fn(Request(String)) -> Response(BitBuilder)))
}

pub fn get(
  app: App,
  route: String,
  handler: fn(Request(t)) -> Response(BitBuilder),
) -> App {
  app.handlers.insert(route, handler)
  // cowboy.get(route, handler)
}

pub fn api(_request: Request(t)) -> Response(BitBuilder) {
  response.new(200)
  |> response.prepend_header("made-with", "Gleam")
  |> response.set_body(bit_builder.from_string("Hello, world!"))
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

  case cowboy.start(api, on_port: port) {
    Ok(_) -> process.sleep_forever()
    Error(_) -> exit(1)
  }
}
