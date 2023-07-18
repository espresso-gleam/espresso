//// This is the base module for starting the http server. It also does things
//// like retrieve the system port and halts but the main thing is the start
//// function.

import espresso/router.{Router, to_routes}
import espresso/system.{exit, get_port}
import gleam/erlang/process
import cowboy/cowboy

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
///     |> get("/", fn(_req: Request(BitString, assigns, session)) { send(202, "Main Route") })
///
///   espresso.start(router)
/// }
/// ```
/// 
pub fn start(r: Router(req, assigns, session, res)) {
  let port = get_port()
  case cowboy.start(cowboy.router(to_routes(r)), on_port: port) {
    Ok(_) -> process.sleep_forever()
    Error(_) -> exit(1)
  }
}

import espresso/request.{Request}
import espresso/response.{send}
import gleam/io
import gleam/map

pub fn main() {
  let router =
    router.new()
    |> router.post(
      "/",
      fn(req: Request(BitString, assigns, session)) {
        case map.get(req.files, "license") {
          Ok(path) -> {
            send(200, system.read_file(path))
          }
          Error(_) -> send(500, "Error saving file")
        }
      },
    )

  start(router)
}
