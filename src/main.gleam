import cat
import espresso/cowboy/cowboy.{Bindings}
import espresso/espresso
import espresso/espresso/query
import espresso/espresso/response.{json, send}
import espresso/espresso/router.{get, post}
import gleam/http/request.{Request}
import gleam/io
import gleam/json
import gleam/list
import gleam/option.{None, Some}
import gleam/pgo
import gleam/result
import gleam/dynamic

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
    router.new(router.passthrough_middleware())
    |> get(
      "/",
      fn(_req: Request(BitString), _params) { send(202, "Main Route") },
    )
    |> get(
      "/cats",
      fn(req: Request(BitString), _bindings) {
        let name = query.get(req, "name")

        let result = case name {
          Some(name) ->
            pgo.execute(
              "select name, lives, flaws, nicknames from cats where name = $1",
              db,
              [pgo.text(name)],
              cat.from_db(),
            )

          None ->
            pgo.execute(
              "select name, lives, flaws, nicknames from cats",
              db,
              [],
              cat.from_db(),
            )
        }

        case result {
          Ok(result) -> {
            result.rows
            |> json.array(of: cat.encode)
            |> response.json()
          }

          Error(error) -> {
            io.debug(error)
            send(500, "Invalid cat")
          }
        }
      },
    )
    |> post(
      "/cats",
      {
        use req <- cat.decoder
        case req.body {
          Ok(c) -> {
            let sql =
              "insert into cats (name, lives, flaws, nicknames) values ($1, $2, $3, $4) returning *"
            case
              pgo.execute(
                sql,
                db,
                [
                  pgo.text(c.name),
                  pgo.int(c.lives),
                  pgo.nullable(pgo.text, c.flaws),
                  pgo.null(),
                ],
                cat.from_db(),
              )
            {
              Ok(result) ->
                case
                  result.rows
                  |> list.first()
                {
                  Ok(cat) ->
                    cat
                    |> cat.encode()
                    |> response.json()
                  _ -> send(500, "Invalid cat")
                }

              Error(error) -> {
                io.debug(error)
                send(500, "Invalid cat")
              }
            }
          }

          Error(_err) -> send(400, "Invalid cat")
        }
      },
    )
    |> get(
      "/cats/:cat",
      fn(_req: Request(BitString), params: Bindings) {
        let name =
          params
          |> list.key_find("cat")
          |> result.unwrap(dynamic.from(""))
          |> dynamic.string()
          |> result.unwrap("")

        let result =
          pgo.execute(
            "select id, name, lives, flaws, nicknames from cats where name = $1",
            db,
            [pgo.text(name)],
            cat.from_db(),
          )

        case result {
          Ok(result) -> {
            let cat = list.first(result.rows)

            case cat {
              Ok(cat) ->
                cat
                |> cat.encode()
                |> response.json()
              Error(_) -> send(404, "Cat not found")
            }
          }

          Error(error) -> {
            io.debug(error)
            send(500, "Internal Server Error")
          }
        }
      },
    )

  espresso.start(router)
}
