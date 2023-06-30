//// This is the base module for starting the http server. It also does things
//// like retrieve the system port and halts but the main thing is the start
//// function.

import espresso/router.{Router, get, to_routes}
import espresso/request.{Request}
import espresso/response.{redirect, send}
import espresso/session
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

pub type Session {
  Session(username: String)
}

pub fn main() {
  let router =
    router.new()
    |> get(
      "/",
      fn(req: Request(BitString, assigns, Session)) {
        case req.session {
          Ok(Session(username)) -> send(202, "Welcome back " <> username)
          _ -> send(202, "You don't have a session")
        }
      },
    )
    |> get(
      "/login",
      fn(_req: Request(BitString, assigns, Session)) {
        202
        |> send("Logged in")
        |> session.set(Session("your_username_here"))
      },
    )
    |> get(
      "/logout",
      fn(_req: Request(BitString, assigns, Session)) {
        "/"
        |> redirect()
        |> session.clear()
      },
    )

  start(router)
}
