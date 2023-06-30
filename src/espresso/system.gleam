import gleam/erlang/os
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

/// Returns the secret used to sign session cookies
/// if this is not set then session encoding/decoding will
/// return a InvalidSecret error.
pub fn get_session_secret() -> Result(String, Nil) {
  os.get_env("ESPRESSO_SIGNING_SECRET")
}

pub external fn exit(i32) -> Nil =
  "erlang" "halt/1"
