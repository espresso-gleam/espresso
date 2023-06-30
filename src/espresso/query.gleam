//// Helper module for extracting query parameters from a request.
//// 

import espresso/request.{Request}
import gleam/list
import gleam/result
import gleam/option.{None, Option, Some}

/// Get a query parameter from a request.
/// 
/// # Examples
/// 
/// ```gleam
/// import espresso/request.{Request}
/// import espresso/query
/// 
/// fn handler(req: Request(a)) {
///  let name = query.get(req, "name")
///  case name {
///    Some(name) -> ...
///    None -> ...
///  }
/// }
/// ```
pub fn get(req: Request(body, assigns, session), name: String) -> Option(String) {
  let result =
    req
    |> request.get_query()
    |> result.unwrap([])
    |> list.key_find(name)

  case result {
    Ok(value) -> Some(value)
    Error(_) -> None
  }
}
