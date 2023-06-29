//// Experimental module used to render functions
//// into an io list and turn that list into a string
//// 
//// This module is experimental and may change or be removed
//// 

import gleam/string_builder.{StringBuilder, append, append_builder}
import gleam/list

pub type Attributes =
  List(#(String, String))

pub type Element {
  Text(text: String)
  Element(tag_name: String, attributes: Attributes, children: Children)
}

type Children =
  List(Element)

fn new(tag_name: String, attributes: Attributes, children: Children) -> Element {
  Element(tag_name: tag_name, attributes: attributes, children: children)
}

pub fn render(element: Element) -> StringBuilder {
  case element {
    Text(text) ->
      string_builder.new()
      |> append(text)
    Element(tag_name, attributes, children) -> {
      string_builder.new()
      |> append("<" <> tag_name)
      |> render_attributes(attributes)
      |> append(">")
      |> render_children(children)
      |> append("</" <> tag_name <> ">")
    }
  }
}

fn render_children(builder: StringBuilder, children: Children) -> StringBuilder {
  list.fold(
    children,
    builder,
    fn(builder, child) { append_builder(builder, render(child)) },
  )
}

fn render_attributes(builder: StringBuilder, attributes: Attributes) {
  list.fold(
    attributes,
    builder,
    fn(builder, attribute) {
      let #(key, value) = attribute

      append(builder, " " <> key <> "=\"" <> value <> "\"")
    },
  )
}

pub fn text(text: String) -> Element {
  Text(text)
}

pub fn div(attributes: Attributes, children: Children) -> Element {
  new("div", attributes, children)
}

// Copilot generated the rest of these :O

pub fn span(attributes: Attributes, children: Children) -> Element {
  new("span", attributes, children)
}

pub fn h1(attributes: Attributes, children: Children) -> Element {
  new("h1", attributes, children)
}

pub fn h2(attributes: Attributes, children: Children) -> Element {
  new("h2", attributes, children)
}

pub fn h3(attributes: Attributes, children: Children) -> Element {
  new("h3", attributes, children)
}

pub fn h4(attributes: Attributes, children: Children) -> Element {
  new("h4", attributes, children)
}

pub fn h5(attributes: Attributes, children: Children) -> Element {
  new("h5", attributes, children)
}

pub fn h6(attributes: Attributes, children: Children) -> Element {
  new("h6", attributes, children)
}

pub fn p(attributes: Attributes, children: Children) -> Element {
  new("p", attributes, children)
}

pub fn img(attributes: Attributes, children: Children) -> Element {
  new("img", attributes, children)
}

pub fn ul(attributes: Attributes, children: Children) -> Element {
  new("ul", attributes, children)
}

pub fn ol(attributes: Attributes, children: Children) -> Element {
  new("ol", attributes, children)
}

pub fn li(attributes: Attributes, children: Children) -> Element {
  new("li", attributes, children)
}

pub fn table(attributes: Attributes, children: Children) -> Element {
  new("table", attributes, children)
}

pub fn thead(attributes: Attributes, children: Children) -> Element {
  new("thead", attributes, children)
}

pub fn tbody(attributes: Attributes, children: Children) -> Element {
  new("tbody", attributes, children)
}

pub fn tr(attributes: Attributes, children: Children) -> Element {
  new("tr", attributes, children)
}

pub fn th(attributes: Attributes, children: Children) -> Element {
  new("th", attributes, children)
}

pub fn td(attributes: Attributes, children: Children) -> Element {
  new("td", attributes, children)
}

pub fn code(attributes: Attributes, children: Children) -> Element {
  new("code", attributes, children)
}

pub fn pre(attributes: Attributes, children: Children) -> Element {
  new("pre", attributes, children)
}

pub fn blockquote(attributes: Attributes, children: Children) -> Element {
  new("blockquote", attributes, children)
}

pub fn hr(attributes: Attributes, children: Children) -> Element {
  new("hr", attributes, children)
}

pub fn br(attributes: Attributes, children: Children) -> Element {
  new("br", attributes, children)
}

pub fn em(attributes: Attributes, children: Children) -> Element {
  new("em", attributes, children)
}

pub fn a(attributes: Attributes, children: Children) -> Element {
  new("a", attributes, children)
}

pub fn abbr(attributes: Attributes, children: Children) -> Element {
  new("abbr", attributes, children)
}

pub fn address(attributes: Attributes, children: Children) -> Element {
  new("address", attributes, children)
}

pub fn area(attributes: Attributes, children: Children) -> Element {
  new("area", attributes, children)
}

pub fn article(attributes: Attributes, children: Children) -> Element {
  new("article", attributes, children)
}

pub fn aside(attributes: Attributes, children: Children) -> Element {
  new("aside", attributes, children)
}

pub fn audio(attributes: Attributes, children: Children) -> Element {
  new("audio", attributes, children)
}

pub fn b(attributes: Attributes, children: Children) -> Element {
  new("b", attributes, children)
}

pub fn base(attributes: Attributes, children: Children) -> Element {
  new("base", attributes, children)
}

pub fn bdi(attributes: Attributes, children: Children) -> Element {
  new("bdi", attributes, children)
}

pub fn canvas(attributes: Attributes, children: Children) -> Element {
  new("canvas", attributes, children)
}

pub fn caption(attributes: Attributes, children: Children) -> Element {
  new("caption", attributes, children)
}

pub fn cite(attributes: Attributes, children: Children) -> Element {
  new("cite", attributes, children)
}

pub fn col(attributes: Attributes, children: Children) -> Element {
  new("col", attributes, children)
}

pub fn colgroup(attributes: Attributes, children: Children) -> Element {
  new("colgroup", attributes, children)
}

pub fn data(attributes: Attributes, children: Children) -> Element {
  new("data", attributes, children)
}

pub fn datalist(attributes: Attributes, children: Children) -> Element {
  new("datalist", attributes, children)
}

pub fn dd(attributes: Attributes, children: Children) -> Element {
  new("dd", attributes, children)
}

pub fn del(attributes: Attributes, children: Children) -> Element {
  new("del", attributes, children)
}

pub fn section(attributes: Attributes, children: Children) -> Element {
  new("section", attributes, children)
}

pub fn details(attributes: Attributes, children: Children) -> Element {
  new("details", attributes, children)
}

pub fn html(attributes: Attributes, children: Children) -> Element {
  new("html", attributes, children)
}

pub fn head(attributes: Attributes, children: Children) -> Element {
  new("head", attributes, children)
}

pub fn body(attributes: Attributes, children: Children) -> Element {
  new("body", attributes, children)
}

pub fn dialog(attributes: Attributes, children: Children) -> Element {
  new("dialog", attributes, children)
}

pub fn link(attributes: Attributes, children: Children) -> Element {
  new("link", attributes, children)
}

pub fn script(attributes: Attributes, children: Children) -> Element {
  new("script", attributes, children)
}

pub fn style(attributes: Attributes, children: Children) -> Element {
  new("style", attributes, children)
}

pub fn meta(attributes: Attributes, children: Children) -> Element {
  new("meta", attributes, children)
}

pub fn title(attributes: Attributes, children: Children) -> Element {
  new("title", attributes, children)
}

pub fn doctype() -> StringBuilder {
  string_builder.from_string("<!DOCTYPE html>")
}

/// Renders an HTML element into a string of HTML
/// 
/// # Examples
/// 
/// ```gleam
///  html(
///    [#("lang", "en")],
///    [
///      head(
///        [],
///        [
///          meta(
///            [
///              #("name", "viewport"),
///              #("content", "width=device-width, initial-scale=1"),
///            ],
///            [],
///          ),
///          title([], [text("Rendered with espresso HTML")]),
///          link(
///            [
///              #("rel", "stylesheet"),
///              #("href", "https://fonts.googleapis.com/css?family=Tangerine"),
///            ],
///            [],
///          ),
///          style(
///            [],
///            [
///              text(
///                "
///                body { 
///                  font-family: 'Tangerine', serif; font-size: 48px;
///                }
///                ",
///              ),
///            ],
///          ),
///        ],
///      ),
///      body([], [div([], [text("Hello")])]),
///    ],
///  )
///  |> to_string()
/// ```
pub fn to_string(dom: Element) -> String {
  dom
  |> render()
  |> string_builder.prepend_builder(doctype())
  |> string_builder.to_string()
}
