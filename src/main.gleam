import cat
import espresso/espresso
import espresso/espresso/response.{json, send}
import espresso/espresso/router.{get, post}
import gleam/http/request.{Request}
import gleam/list
import gleam/result
import gleam/pgo
import gleam/io
import gleam/option.{Some}
import gleam/json

pub fn main() {
  let db =
    pgo.connect(
      pgo.Config(
        ..pgo.default_config(),
        host: "localhost",
        user: "postgres",
        password: Some("postgres"),
        database: "cat_database_dev",
        pool_size: 2,
      ),
    )

  let router =
    router.new()
    |> get("/", fn(_req: Request(BitString)) { send(202, "Main Route") })
    |> get(
      "/cats",
      fn(_req: Request(BitString)) {
        let sql = "select name, lives, flaws, nicknames from cats"

        case pgo.execute(sql, db, [], cat.from_db()) {
          Ok(result) -> {
            result.rows
            |> json.array(of: cat.encode)
            |> json()
          }

          Error(error) -> {
            io.debug(error)
            send(500, "Invalid cat")
          }
        }
      },
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
