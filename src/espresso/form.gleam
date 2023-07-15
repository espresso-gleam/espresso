import gleam/dynamic.{Dynamic}
import gleam/result

pub type FormDecodeError {
  UnexpectedFormat(List(dynamic.DecodeError))
}

/// Parses form encoded data
/// 
/// ### Examples
///
/// ```gleam 
/// pub type Note {
///   Note(id: Int, title: String, content: String)
/// }
/// pub fn decode(body: String) {
///  let decoder =
///    dynamic.decode3(
///      Note,
///      dynamic.field("id", of: dynamic.int),
///      dynamic.field("title", of: dynamic.string),
///      dynamic.field("content", of: dynamic.string),
///    )
///  form.decode(body, decoder)
/// }
/// 
/// ```
/// > decode("id=1&title=Hello&content=World")
/// Ok(Note(1, "Hello", "World"))
/// 
/// You can couple this with a request middleware to parse the body of a request
/// 
/// ```gleam
///pub fn create_decoder(
///  handler: Service(Result(Note, form.FormDecodeError), assigns, session, res),
///) -> Service(BitString, assigns, session, res) {
///  fn(req: Request(BitString, assigns, session)) -> Response(res) {
///    request.map(
///      req,
///      fn(body) {
///        body
///        |> bit_string.to_string()
///        |> result.unwrap("")
///        |> decode()
///      },
///    )
///    |> handler()
///  }
///}
///...
///router.get(
///  "/",
///  {
///    use req: Request(Result(Note, form.FormDecodeError), assigns, session) <- create_decoder
///    case req.body {
///      Ok(note) -> send(202, note.content)
///      t -> {
///        io.debug(t)
///        send(400, "Bad Request")
///      }
///    }
///  },
///)
/// ```
///
pub fn decode(body: String, decoder: dynamic.Decoder(t)) {
  let decoded =
    body
    |> decode_to_dynamic()
    |> dynamic.from()
  decoder(decoded)
  |> result.map_error(UnexpectedFormat)
}

@external(erlang, "gleam_cowboy_native", "parse_query_string")
fn decode_to_dynamic(a: String) -> Result(Dynamic, FormDecodeError)
