//// Module for interacting and sending HTTP responses.
//// 
//// Forked from: https://github.com/gleam-lang/http/blob/v3.2.0/src/gleam/http/response.gleam

import espresso/html.{Element}
import gleam/bit_builder.{BitBuilder}
import gleam/http.{Header}
import gleam/http/cookie
import gleam/json
import gleam/list
import gleam/option
import gleam/result
import gleam/string

/// Type that represents an HTTP response.
pub type Response(body) {
  Response(status: Int, headers: List(Header), body: body)
}

/// Update the body of a response using a given result returning function.
///
/// If the given function returns an `Ok` value the body is set, if it returns
/// an `Error` value then the error is returned.
///
pub fn try_map(
  response: Response(old_body),
  transform: fn(old_body) -> Result(new_body, error),
) -> Result(Response(new_body), error) {
  use body <- result.then(transform(response.body))
  Ok(set_body(response, body))
}

/// Construct an empty Response.
///
/// The body type of the returned response is `String` and could be set with a
/// call to `set_body`.
///
pub fn new(status: Int) -> Response(BitBuilder) {
  Response(status: status, headers: [], body: bit_builder.from_string(""))
}

/// Get the value for a given header.
///
/// If the response does not have that header then `Error(Nil)` is returned.
///
pub fn get_header(response: Response(body), key: String) -> Result(String, Nil) {
  list.key_find(response.headers, string.lowercase(key))
}

/// Set the header with the given value under the given header key.
///
/// If the response already has that key, it is replaced.
pub fn set_header(
  response: Response(body),
  key: String,
  value: String,
) -> Response(body) {
  let headers = list.key_set(response.headers, key, string.lowercase(value))
  Response(..response, headers: headers)
}

/// Prepend the header with the given value under the given header key.
///
/// Similar to `set_header` except if the header already exists it prepends
/// another header with the same key.
pub fn prepend_header(
  response: Response(body),
  key: String,
  value: String,
) -> Response(body) {
  let headers = [#(string.lowercase(key), value), ..response.headers]
  Response(..response, headers: headers)
}

/// Set the body of the response, overwriting any existing body.
///
pub fn set_body(
  response: Response(old_body),
  body: new_body,
) -> Response(new_body) {
  let Response(status: status, headers: headers, ..) = response
  Response(status: status, headers: headers, body: body)
}

/// Update the body of a response using a given function.
///
pub fn map(
  response: Response(old_body),
  transform: fn(old_body) -> new_body,
) -> Response(new_body) {
  response.body
  |> transform
  |> set_body(response, _)
}

/// Create a response that redirects to the given uri.
///
pub fn redirect(uri: String) -> Response(BitBuilder) {
  Response(
    status: 303,
    headers: [#("location", uri)],
    body: bit_builder.from_string(string.append(
      "You are being redirected to ",
      uri,
    )),
  )
}

/// Fetch the cookies sent in a response. 
///
/// Badly formed cookies will be discarded.
///
pub fn get_cookies(resp) -> List(#(String, String)) {
  let Response(headers: headers, ..) = resp
  headers
  |> list.filter_map(fn(header) {
    let #(name, value) = header
    case name {
      "set-cookie" -> Ok(cookie.parse(value))
      _ -> Error(Nil)
    }
  })
  |> list.flatten()
}

/// Set a cookie value for a client
///
pub fn set_cookie(
  response: Response(t),
  name: String,
  value: String,
  attributes: cookie.Attributes,
) -> Response(t) {
  prepend_header(
    response,
    "set-cookie",
    cookie.set_header(name, value, attributes),
  )
}

/// Expire a cookie value for a client
///
/// Note: The attributes value should be the same as when the response cookie was set.
pub fn expire_cookie(
  response: Response(t),
  name: String,
  attributes: cookie.Attributes,
) -> Response(t) {
  let attrs = cookie.Attributes(..attributes, max_age: option.Some(0))
  set_cookie(response, name, "", attrs)
}

/// Given json data, sends a 200 response with the json data as the body.
/// 
/// # Example
/// 
/// ```gleam
/// import espresso/request.{Request}
/// import espresso/response
/// import cat
/// 
/// fn handler(_req: Request) {
///   Cat(name: "Test") 
///   |> cat.encode()
///   |> response.json()
/// }
/// ```
/// 
pub fn json(data: json.Json) -> Response(BitBuilder) {
  200
  |> new()
  |> set_header("Content-Type", "application/json")
  |> set_body(
    data
    |> json.to_string_builder()
    |> bit_builder.from_string_builder(),
  )
}

/// Similar to `json` but allows you to override more fields in the response.
/// 
/// # Example
/// 
/// ```gleam
/// import espresso/request.{Request}
/// import espresso/response
/// import cat
/// 
/// fn handler(_req: Request) {
///   let cat = Cat(name: "Test") 
///   
///   201
///   |> response.new()
///   |> response.json2(cat.encode(cat))
/// }
/// ```
/// 
pub fn json2(res: Response(a), data: json.Json) -> Response(BitBuilder) {
  res
  |> set_header("Content-Type", "application/json")
  |> set_body(
    data
    |> json.to_string_builder()
    |> bit_builder.from_string_builder(),
  )
}

/// sends a generic response with the given status code and text body.
/// 
/// # Example
/// 
/// ```gleam
/// import espresso/request.{Request}
/// 
/// fn handler(_req: Request) {
///  response.send(200, "Hello World")
/// }
/// ```
pub fn send(status: Int, body: String) -> Response(BitBuilder) {
  status
  |> new()
  |> set_body(bit_builder.from_string(body))
}

/// sends a 200 response code with html rendered by the `html` module
/// 
/// # Example
/// 
/// ```gleam
/// import espresso/request.{Request}
/// import espresso/html.{html, body, head, text}
/// 
/// fn handler(_req: Request) {
///  html([], [head([], []), body([], [text("Hello World")])])
///  |> render()
/// }
/// ```
pub fn render(body: Element) -> Response(BitBuilder) {
  let body = html.to_string(body)

  200
  |> new()
  |> set_body(bit_builder.from_string(body))
}
