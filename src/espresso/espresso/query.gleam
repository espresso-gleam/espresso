import gleam/http/request.{Request}
import gleam/list
import gleam/result
import gleam/option.{None, Option, Some}

pub fn get(req: Request(a), name: String) -> Option(String) {
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
