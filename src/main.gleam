import cat
import espresso/espresso
import espresso/espresso/response.{json, send}
import espresso/espresso/router.{get, post}
import gleam/http/request.{Request}
import gleam/list
import gleam/result

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
      {
        use req <- cat.decoder
        case req.body {
          Ok(c) ->
            c
            |> cat.encode()
            |> json()
          Error(_err) -> send(400, "Invalid cat")
        }
      },
    )

  espresso.start(router)
}
