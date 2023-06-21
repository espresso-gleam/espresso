/// The type of static file to serve. Either dir for directory
/// or file for a single file.
/// 
/// # Examples
/// 
/// ```gleam
/// File("priv/index.html")
/// Dir("priv")
/// ```
/// 
/// https://ninenines.eu/docs/en/cowboy/2.10/manual/cowboy_static/
pub type Static {
  File(String)
  Dir(String)
}
