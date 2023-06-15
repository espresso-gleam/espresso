import cat
import express/express
import express/express/response.{json, send}
import express/express/router.{get}
import gleam/http/request.{Request}
import gleam/list
import gleam/result

pub fn main() {
  let router =
    router.new()
    |> get("/", fn(_req: Request(a)) { send(202, "Main Route") })
    |> get("/bananas", fn(_req: Request(a)) { send(200, "We're bananas") })
    |> get(
      "/json",
      fn(req: Request(a)) {
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

  express.start(router)
}
