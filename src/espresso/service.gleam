//// Service module that's mostly the same as the one in gleam/http but
//// instead of taking gleam/http request and response it takes espresso versions.
//// 
//// Forked from https://github.com/gleam-lang/http/blob/v3.2.0/src/gleam/http/service.gleam

import espresso/request.{Request}
import espresso/response.{Response}
import gleam/http.{Delete, Patch, Post, Put}
import gleam/list
import gleam/result

/// Services are functions that take a request and return a response.
/// They are the core building block of web applications.
pub type Service(in, out) =
  fn(Request(in)) -> Response(out)

/// Middleware are functions that take a before req/res and return a 
/// new req/res. They are used to transform requests and responses.
pub type Middleware(before_req, before_resp, after_req, after_resp) =
  fn(Service(before_req, before_resp)) -> Service(after_req, after_resp)

/// A middleware that transforms the response body returned by the service using
/// a given function.
///
pub fn map_response_body(
  service: Service(req, a),
  with mapper: fn(a) -> b,
) -> Service(req, b) {
  fn(req) {
    req
    |> service
    |> response.map(mapper)
  }
}

/// A middleware that prepends a header to the request.
///
pub fn prepend_response_header(
  service: Service(req, resp),
  key: String,
  value: String,
) -> Service(req, resp) {
  fn(req) {
    req
    |> service
    |> response.prepend_header(key, value)
  }
}

fn ensure_post(req: Request(a)) {
  case req.method {
    Post -> Ok(req)
    _ -> Error(Nil)
  }
}

fn get_override_method(request: Request(t)) -> Result(http.Method, Nil) {
  use query_params <- result.then(request.get_query(request))
  use method <- result.then(list.key_find(query_params, "_method"))
  use method <- result.then(http.parse_method(method))
  case method {
    Put | Patch | Delete -> Ok(method)
    _ -> Error(Nil)
  }
}

/// A middleware that overrides an incoming POST request with a method given in
/// the request's `_method` query paramerter. This is useful as web browsers
/// typically only support GET and POST requests, but our application may
/// expect other HTTP methods that are more semantically correct.
///
/// The methods PUT, PATCH, and DELETE are accepted for overriding, all others
/// are ignored.
///
/// The `_method` query paramerter can be specified in a HTML form like so:
///
///    <form method="POST" action="/item/1?_method=DELETE">
///      <button type="submit">Delete item</button>
///    </form>
///
pub fn method_override(service: Service(req, resp)) -> Service(req, resp) {
  fn(request) {
    request
    |> ensure_post
    |> result.then(get_override_method)
    |> result.map(request.set_method(request, _))
    |> result.unwrap(request)
    |> service
  }
}
