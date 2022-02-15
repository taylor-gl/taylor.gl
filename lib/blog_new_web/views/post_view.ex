defmodule BlogNewWeb.PostView do
  use BlogNewWeb, :view
  alias BlogNew.Blog.Post

  def figure(filename, alt_text, caption_text) do
    webp_filename = filename <> ".webp"
    jpg_filename = filename <> ".jpg"

    Phoenix.View.render_to_string(
      BlogNewWeb.PostView,
      "figure.html",
      alt: alt_text,
      caption: caption_text,
      webp_src: webp_filename,
      jpg_src: jpg_filename
    )
    # remove trailing newline etc. from template
    |> String.trim_trailing()
  end

  def footnote(text, hover) do
    Phoenix.View.render_to_string(BlogNewWeb.PostView, "footnote.html", text: text, hover: hover)
    # remove trailing newline etc. from template
    |> String.trim_trailing()
  end

  def title(view_template_name, assigns) do
    case view_template_name do
      "index.html" ->
        "Taylor G. Lunt's Blog"

      "show.html" ->
        assigns.post.title
    end
  end
end
