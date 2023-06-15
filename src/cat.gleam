import gleam/dynamic
import gleam/json
import gleam/option.{None, Option}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import gleam/bit_string
import gleam/result

pub type Cat {
  Cat(name: String, lives: Int, flaws: Option(String), nicknames: List(String))
}

pub fn new(name: String) -> Cat {
  Cat(name, 9, None, [])
}

pub fn encode(cat: Cat) {
  json.object([
    #("name", json.string(cat.name)),
    #("lives", json.int(cat.lives)),
    #("flaws", json.null()),
    #("nicknames", json.array(cat.nicknames, of: json.string)),
  ])
}

pub fn decode(body: String) {
  let cat_decoder =
    dynamic.decode4(
      Cat,
      dynamic.field("name", of: dynamic.string),
      dynamic.field("lives", of: dynamic.int),
      dynamic.field("flaws", of: dynamic.optional(dynamic.string)),
      dynamic.field("nicknames", of: dynamic.list(dynamic.string)),
    )

  json.decode(from: body, using: cat_decoder)
}

pub fn from_db() {
  dynamic.decode4(
    Cat,
    dynamic.element(0, dynamic.string),
    dynamic.element(1, dynamic.int),
    dynamic.element(2, dynamic.optional(dynamic.string)),
    dynamic.element(3, dynamic.list(dynamic.string)),
  )
}

pub fn decoder(
  handler: Service(Result(Cat, json.DecodeError), a),
) -> Service(BitString, a) {
  fn(req: Request(BitString)) -> Response(a) {
    request.map(
      req,
      fn(body) {
        body
        |> bit_string.to_string()
        |> result.unwrap("")
        |> decode()
      },
    )
    |> handler()
  }
}
