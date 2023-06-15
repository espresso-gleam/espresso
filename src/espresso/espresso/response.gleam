import gleam/bit_builder.{BitBuilder}
import gleam/http/response.{Response}
import gleam/json

pub fn json(data: json.Json) -> Response(BitBuilder) {
  200
  |> response.new()
  |> response.set_header("Content-Type", "application/json")
  |> response.set_body(
    data
    |> json.to_string_builder()
    |> bit_builder.from_string_builder(),
  )
}

pub fn json2(res: Response(a), data: json.Json) -> Response(BitBuilder) {
  res
  |> response.set_header("Content-Type", "application/json")
  |> response.set_body(
    data
    |> json.to_string_builder()
    |> bit_builder.from_string_builder(),
  )
}

pub fn send(status: Int, body: String) -> Response(BitBuilder) {
  status
  |> response.new()
  |> response.set_body(bit_builder.from_string(body))
}
