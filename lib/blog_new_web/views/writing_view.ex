defmodule BlogNewWeb.WritingView do
  use BlogNewWeb, :view

  def slug(writing) do
    String.replace_suffix(writing.markdown_filename, ".md", "")
  end

  def title(view_template_name, assigns) do
    case view_template_name do
      "index.html" ->
        "Taylor G. Lunt's Creative Writing"
      "show.html" ->
        assigns.writing.title
    end
  end
end
