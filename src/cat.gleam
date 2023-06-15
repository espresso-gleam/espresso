import gleam/dynamic
import gleam/json
import gleam/option.{Option}
import gleam/http/request.{Request}
import gleam/http/response.{Response}
import gleam/http/service.{Service}
import gleam/bit_string
import gleam/result

pub type Cat {
  Cat(
    id: Int,
    name: String,
    lives: Int,
    flaws: Option(String),
    nicknames: Option(List(String)),
  )
}

pub fn encode(cat: Cat) {
  json.object([
    #("name", json.string(cat.name)),
    #("lives", json.int(cat.lives)),
    #("flaws", json.null()),
    #(
      "nicknames",
      json.nullable(
        cat.nicknames,
        fn(nicknames) { json.array(nicknames, of: json.string) },
      ),
    ),
  ])
}

pub fn decode(body: String) {
  let cat_decoder =
    dynamic.decode5(
      Cat,
      dynamic.field("id", of: dynamic.int),
      dynamic.field("name", of: dynamic.string),
      dynamic.field("lives", of: dynamic.int),
      dynamic.field("flaws", of: dynamic.optional(dynamic.string)),
      dynamic.field(
        "nicknames",
        of: dynamic.optional(dynamic.list(dynamic.string)),
      ),
    )

  json.decode(from: body, using: cat_decoder)
}

pub fn from_db() {
  dynamic.decode5(
    Cat,
    dynamic.element(0, dynamic.int),
    dynamic.element(1, dynamic.string),
    dynamic.element(2, dynamic.int),
    dynamic.element(3, dynamic.optional(dynamic.string)),
    dynamic.element(4, dynamic.optional(dynamic.list(dynamic.string))),
  )
}

pub fn from_req(body: String) {
  let cat_decoder =
    dynamic.decode5(
      Cat,
      fn(_) { Ok(0) },
      dynamic.field("name", of: dynamic.string),
      dynamic.field("lives", of: dynamic.int),
      dynamic.field("flaws", of: dynamic.optional(dynamic.string)),
      dynamic.field(
        "nicknames",
        of: dynamic.optional(dynamic.list(dynamic.string)),
      ),
    )

  json.decode(from: body, using: cat_decoder)
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
        |> from_req()
      },
    )
    |> handler()
  }
}
