// This is a fork of https://github.com/gleam-lang/http/blob/main/src/gleam/http/request.gleam
// it has additional things like "Params"
import espresso/session.{Session}
import gleam/dynamic
import gleam/http.{Get, Header, Method, Scheme}
import gleam/http/cookie
import gleam/list
import gleam/map.{Map}
import gleam/option.{None, Option, Some}
import gleam/result
import gleam/string
import gleam/string_builder
import gleam/uri.{Uri}

pub type Params =
  List(#(String, String))

/// Represents an HTTP request.
/// Contains most of the pieces of a URI but additionally contains
/// the HTTP method, headers, and body. Also contains the params which
/// are the parsed elements of a router path.
pub type Request(body, assigns, session) {
  Request(
    method: Method,
    headers: List(Header),
    body: body,
    scheme: Scheme,
    host: String,
    port: Option(Int),
    path: String,
    query: Option(String),
    params: Params,
    assigns: Option(assigns),
    session: Session(session),
    raw: dynamic.Dynamic,
    files: Map(String, String),
  )
}

/// Utility function to get a router param from the request.
/// 
/// # Examples
/// ```gleam
/// import espresso/request.{Request}
/// import gleam/result
/// 
/// fn handler(req: Request(a)) {
///   let id = req |> request.get_param("id") |> result.unwrap("")
/// }
/// ```
pub fn get_param(
  req: Request(body, assigns, session),
  name: String,
) -> Result(String, Nil) {
  list.key_find(req.params, name)
}

/// Return the uri that a request was sent to.
///
pub fn to_uri(request: Request(body, assigns, session)) -> Uri {
  Uri(
    scheme: option.Some(http.scheme_to_string(request.scheme)),
    userinfo: option.None,
    host: option.Some(request.host),
    port: request.port,
    path: request.path,
    query: request.query,
    fragment: option.None,
  )
}

/// Construct a request from a URI.
///
pub fn from_uri(uri: Uri) -> Result(Request(String, assigns, session), Nil) {
  use scheme <- result.then(
    uri.scheme
    |> option.unwrap("")
    |> http.scheme_from_string,
  )
  use host <- result.then(
    uri.host
    |> option.to_result(Nil),
  )
  let req =
    Request(
      method: Get,
      headers: [],
      body: "",
      scheme: scheme,
      host: host,
      port: uri.port,
      path: uri.path,
      query: uri.query,
      params: [],
      assigns: None,
      session: Error(session.Unset),
      raw: dynamic.from(""),
      files: map.new(),
    )
  Ok(req)
}

/// Get the value for a given header.
///
/// If the request does not have that header then `Error(Nil)` is returned.
///
pub fn get_header(
  request: Request(body, assigns, session),
  key: String,
) -> Result(String, Nil) {
  list.key_find(request.headers, string.lowercase(key))
}

/// Set the header with the given value under the given header key.
///
/// If already present, it is replaced.
pub fn set_header(
  request: Request(body, assigns, session),
  key: String,
  value: String,
) -> Request(body, assigns, session) {
  let headers = list.key_set(request.headers, string.lowercase(key), value)
  Request(..request, headers: headers)
}

/// Prepend the header with the given value under the given header key.
///
/// Similar to `set_header` except if the header already exists it prepends
/// another header with the same key.
pub fn prepend_header(
  request: Request(body, assigns, session),
  key: String,
  value: String,
) -> Request(body, assigns, session) {
  let headers = [#(string.lowercase(key), value), ..request.headers]
  Request(..request, headers: headers)
}

// TODO: record update syntax, which can't be done currently as body type changes
/// Set the body of the request, overwriting any existing body.
///
pub fn set_body(
  req: Request(old_body, assigns, session),
  body: new_body,
) -> Request(new_body, assigns, session) {
  let Request(
    method: method,
    headers: headers,
    scheme: scheme,
    host: host,
    port: port,
    path: path,
    query: query,
    params: params,
    assigns: assigns,
    session: session,
    raw: raw,
    files: files,
    ..,
  ) = req
  Request(
    method: method,
    headers: headers,
    body: body,
    scheme: scheme,
    host: host,
    port: port,
    path: path,
    query: query,
    params: params,
    assigns: assigns,
    session: session,
    raw: raw,
    files: files,
  )
}

/// Update the body of a request using a given function.
///
pub fn map(
  request: Request(old_body, assigns, session),
  transform: fn(old_body) -> new_body,
) -> Request(new_body, assigns, session) {
  request.body
  |> transform
  |> set_body(request, _)
}

/// Return the non-empty segments of a request path.
///
pub fn path_segments(request: Request(body, assigns, session)) -> List(String) {
  request.path
  |> uri.path_segments
}

/// Decode the query of a request.
pub fn get_query(
  request: Request(body, assigns, session),
) -> Result(List(#(String, String)), Nil) {
  case request.query {
    option.Some(query_string) -> uri.parse_query(query_string)
    option.None -> Ok([])
  }
}

// TODO: escape
/// Set the query of the request.
///
pub fn set_query(
  req: Request(body, assigns, session),
  query: List(#(String, String)),
) -> Request(body, assigns, session) {
  let pair = fn(t: #(String, String)) {
    string_builder.from_strings([t.0, "=", t.1])
  }
  let query =
    query
    |> list.map(pair)
    |> list.intersperse(string_builder.from_string("&"))
    |> string_builder.concat
    |> string_builder.to_string
    |> option.Some
  Request(..req, query: query)
}

/// Set the method of the request.
///
pub fn set_method(
  req: Request(body, assigns, session),
  method: Method,
) -> Request(body, assigns, session) {
  Request(..req, method: method)
}

/// A request with commonly used default values. This request can be used as
/// an initial value and then update to create the desired request.
///
pub fn new() -> Request(String, assigns, session) {
  Request(
    method: Get,
    headers: [],
    body: "",
    scheme: http.Https,
    host: "localhost",
    port: None,
    path: "",
    query: None,
    params: [],
    assigns: None,
    session: Error(session.Unset),
    raw: dynamic.from(""),
    files: map.new(),
  )
}

/// Construct a request from a URL string
///
pub fn to(url: String) -> Result(Request(String, assigns, session), Nil) {
  url
  |> uri.parse
  |> result.then(from_uri)
}

/// Set the scheme (protocol) of the request.
///
pub fn set_scheme(
  req: Request(body, assigns, session),
  scheme: Scheme,
) -> Request(body, assigns, session) {
  Request(..req, scheme: scheme)
}

/// Set the method of the request.
///
pub fn set_host(
  req: Request(body, assigns, session),
  host: String,
) -> Request(body, assigns, session) {
  Request(..req, host: host)
}

/// Set the port of the request.
///
pub fn set_port(
  req: Request(body, assigns, session),
  port: Int,
) -> Request(body, assigns, session) {
  Request(..req, port: option.Some(port))
}

/// Set the path of the request.
///
pub fn set_path(
  req: Request(body, assigns, session),
  path: String,
) -> Request(body, assigns, session) {
  Request(..req, path: path)
}

/// Send a cookie with a request
///
/// Multiple cookies are added to the same cookie header.
pub fn set_cookie(
  req: Request(body, assigns, session),
  name: String,
  value: String,
) {
  let new_cookie_string = string.join([name, value], "=")

  let #(cookies_string, headers) = case list.key_pop(req.headers, "cookie") {
    Ok(#(cookies_string, headers)) -> {
      let cookies_string =
        string.join([cookies_string, new_cookie_string], "; ")
      #(cookies_string, headers)
    }
    Error(Nil) -> #(new_cookie_string, req.headers)
  }

  Request(..req, headers: [#("cookie", cookies_string), ..headers])
}

/// Fetch the cookies sent in a request.
///
/// Note badly formed cookie pairs will be ignored.
/// RFC6265 specifies that invalid cookie names/attributes should be ignored.
pub fn get_cookies(req) -> List(#(String, String)) {
  let Request(headers: headers, ..) = req

  headers
  |> list.filter_map(fn(header) {
    let #(name, value) = header
    case name {
      "cookie" -> Ok(cookie.parse(value))
      _ -> Error(Nil)
    }
  })
  |> list.flatten()
}

/// Set the assigns of the request, overwriting any existing assigns.
///
/// # Examples
/// 
/// ```gleam
/// type Assigns {
///  Assigns(authorized: Bool)
/// }
/// 
/// let router =
///    router.new()
///    |> router.middleware(fn(next: Service(BitString, Assigns, BitBuilder)) {
///      fn(req: Request(BitString, Assigns)) {
///        let auth = request.get_header(req, "authorization")
///        case auth {
///          Ok("Basic OnN1cGVyc2VjcmV0") ->
///            req
///            |> assign(Assigns(authorized: True))
///            |> next()
///          _ -> send(401, "Unauthorized")
///       }
///      }
///    })
///    |> get(
///      "/",
///      fn(_req: Request(BitString, Assigns)) { 
///          // req.assigns here will be Some(Assigns(authorized: True))
///          // if the basic auth password is "supersecret"
///          send(202, "Main Route") 
///      }    
///   )
/// ```
pub fn assign(
  req: Request(body, assigns, session),
  assigns: assigns,
) -> Request(body, assigns, session) {
  Request(..req, assigns: Some(assigns))
}

pub fn load_session(
  req: Request(body, assigns, session),
) -> Request(body, assigns, session) {
  case list.key_find(get_cookies(req), session.session_key()) {
    Ok(session) -> {
      let session = session.decode(session)
      Request(..req, session: session)
    }
    _ -> req
  }
}
