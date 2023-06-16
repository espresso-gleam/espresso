import espresso/espresso/router.{Router, handle}
import gleam/erlang/os
import gleam/erlang/process
import gleam/http/cowboy
import gleam/int
import gleam/result

pub fn get_port() -> Int {
  "PORT"
  |> os.get_env()
  |> result.unwrap("3000")
  |> int.parse()
  |> result.unwrap(3000)
}

pub external fn exit(i32) -> Nil =
  "Elixir.Process" "exit/1"

pub fn start(r: Router(req, res)) {
  let port = get_port()
  case cowboy.start(fn(request) { handle(r, request) }, on_port: port) {
    Ok(_) -> process.sleep_forever()
    Error(_) -> exit(1)
  }
}
