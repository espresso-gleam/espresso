# espresso

_This package is experimental and likely to change. Use at your own risk_

[![Package Version](https://img.shields.io/hexpm/v/espresso)](https://hex.pm/packages/espresso)
[![Hex Docs](https://img.shields.io/badge/hex-docs-ffaff3)](https://hexdocs.pm/espresso/)

A simple to use HTTP server built on top of erlang's cowboy.

```gleam
import espresso
import espresso/request.{Request}
import espresso/response.{send}
import espresso/router.{get}

pub fn main() {
  let router =
    router.new()
    |> get("/", fn(_req: Request(BitString)) { send(202, "Main Route") })

  espresso.start(router)
}
```

## Environment Variables

- PORT: the port to run the service on
- ESPRESSO_SIGNING_SECRET: the secret used to sign the session cookie

## Quick start

```sh
gleam run   # Run the project
gleam test  # Run the tests
gleam shell # Run an Erlang shell
```

## Installation

If available on Hex this package can be added to your Gleam project:

```sh
gleam add espresso
```

and its documentation can be found at <https://hexdocs.pm/espresso>.
