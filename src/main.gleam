import cat
import espresso/espresso
import espresso/espresso/response.{json, send}
import espresso/espresso/router.{get, post}
import gleam/http/request.{Request}
import gleam/bit_string
import gleam/list
import gleam/result
import gleam/io

pub fn main() {
  let router =
    router.new()
    |> get("/", fn(_req: Request(BitString)) { send(202, "Main Route") })
    |> get(
      "/bananas",
      fn(_req: Request(BitString)) { send(200, "We're bananas") },
    )
    |> get(
      "/json",
      fn(req: Request(BitString)) {
        let name =
          req
          |> request.get_query()
          |> result.unwrap([])
          |> list.key_find("name")
          |> result.unwrap("")

        name
        |> cat.new()
        |> cat.encode()
        |> json()
      },
    )
    |> post(
      "/json",
      fn(req: Request(BitString)) {
        request.map(
          req,
          fn(body) {
            body
            |> bit_string.to_string()
            |> io.debug()
            |> result.unwrap("")
            |> io.debug()
            |> cat.decode()
            |> io.debug()

            body
          },
        )

        "dummy"
        |> cat.new()
        |> cat.encode()
        |> json()
      },
    )

  espresso.start(router)
}
