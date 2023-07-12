//// Module that handles interacting with a session cookie.
//// 
//// The session cookie is a signed erlang term that is base64 encoded. Signatures
//// are performed with gleam/crypto and the secret is read from the environment
//// variable `ESPRESSO_SIGNING_SECRET`.
//// 
//// # Example
//// 
//// ```gleam
//// pub type Session {
////   Session(username: String)
//// }
//// pub fn main() {
////   let router =
////     router.new()
////     |> get(
////       "/",
////       fn(req: Request(BitString, assigns, Session)) {
////         case req.session {
////           Ok(Session(username)) -> send(202, "Welcome back " <> username)
////           _ -> send(202, "You don't have a session")
////         }
////       },
////     )
////     |> get(
////       "/login",
////       fn(_req: Request(BitString, assigns, Session)) {
////         202
////         |> send("Logged in")
////         |> session.set(Session("your_username_here"))
////       },
////     )
////     |> get(
////       "/logout",
////       fn(_req: Request(BitString, assigns, Session)) {
////         "/"
////         |> redirect()
////         |> session.clear()
////       },
////     )
////   start(router)
//// }
//// ```
//// 

import espresso/system.{get_session_secret}
import gleam/crypto.{Sha512, sign_message}
import gleam/bit_string
import espresso/response.{Response, expire_cookie, set_cookie}
import gleam/http/cookie
import gleam/http.{Http}

pub type SessionState {
  EncodeError(String)
  InvalidSignature
  InvalidSecret
  Unset
}

pub type Session(session) =
  Result(session, SessionState)

@external(erlang, "erlang", "term_to_binary")
fn to_binary(a: a) -> BitString

@external(erlang, "erlang", "binary_to_term")
fn to_term(a: BitString) -> a

pub fn encode(session: Session(a)) -> Result(String, SessionState) {
  case session {
    Ok(session) -> {
      case get_session_secret() {
        Ok(secret) -> {
          let erlang_encoded_session = to_binary(session)

          Ok(sign_message(
            erlang_encoded_session,
            bit_string.from_string(secret),
            Sha512,
          ))
        }
        Error(_) -> Error(InvalidSecret)
      }
    }

    Error(error) -> Error(error)
  }
}

pub fn decode(session: String) -> Session(a) {
  case get_session_secret() {
    Ok(secret) -> {
      case
        crypto.verify_signed_message(session, bit_string.from_string(secret))
      {
        Ok(term) -> {
          let decoded_session = to_term(term)
          Ok(decoded_session)
        }
        Error(_) -> Error(InvalidSignature)
      }
    }
    Error(_) -> Error(InvalidSecret)
  }
}

pub fn session_key() -> String {
  "_espresso_session"
}

/// Sets the session cookie on the response based on the session state.
pub fn set(res: Response(r), session: a) -> Response(r) {
  case encode(Ok(session)) {
    Ok(encoded_session) -> {
      // TODO set defaults based on current url host/scheme
      set_cookie(res, session_key(), encoded_session, cookie.defaults(Http))
    }
    Error(_) -> res
  }
}

/// Clears out the session cookie on the response. Subsequent requests will have a session of Error(Unset)
pub fn clear(res: Response(r)) -> Response(r) {
  expire_cookie(res, session_key(), cookie.defaults(Http))
}
