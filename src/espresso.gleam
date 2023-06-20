//// This is the base module for starting the http server. It also does things
//// like retrieve the system port and halts but the main thing is the start
//// function.

import espresso/router.{Router, to_routes}
import gleam/erlang/os
import gleam/erlang/process
import cowboy/cowboy
import gleam/int
import gleam/result

/// Returns the port to listen on by reading the
/// "PORT" environtment variable. 
/// 
/// Defaults to 3000.
/// 
pub fn get_port() -> Int {
  "PORT"
  |> os.get_env()
  |> result.unwrap("3000")
  |> int.parse()
  |> result.unwrap(3000)
}

external fn exit(i32) -> Nil =
  "erlang" "halt/1"

/// Starts the server with a router and returns the pid of the process.
/// 
/// ## Example 
/// 
/// ```gleam
/// import espresso
/// import espresso/request.{Request}
/// import espresso/response.{send}
/// import espresso/router.{get}
///
/// pub fn main() {
///   let router =
///     router.new()
///     |> get("/", fn(_req: Request(BitString)) { send(202, "Main Route") })
///
///   espresso.start(router)
/// }
/// ```
/// 
pub fn start(r: Router(req, res)) {
  let port = get_port()
  case cowboy.start(cowboy.router(to_routes(r)), on_port: port) {
    Ok(_) -> process.sleep_forever()
    Error(_) -> exit(1)
  }
}
