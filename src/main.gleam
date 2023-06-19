import espresso/espresso
import espresso/espresso/request.{Request}
import espresso/espresso/response.{send}
import espresso/espresso/router.{get}
import gleam/option.{Some}
import gleam/pgo
import cat_router

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
    |> get("/", fn(_req: Request(BitString)) { send(202, "Main Route") })
    |> router.router("/cats", cat_router.routes(db))

  espresso.start(router)
}
