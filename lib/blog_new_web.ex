defmodule BlogNewWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use BlogNewWeb, :controller
      use BlogNewWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def static_paths,
    do:
      ~w(assets fonts images favicon.ico apple-touch-icon.png favicon-32x32.png favicon-16x16.png robots.txt pdf rss.xml)

  def controller do
    quote do
      use Phoenix.Controller, namespace: BlogNewWeb

      import Plug.Conn
      import BlogNewWeb.Gettext
      alias BlogNewWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/blog_new_web/templates",
        namespace: BlogNewWeb

      # Import convenience functions from controllers
      import Phoenix.Controller,
        only: [view_module: 1, view_template: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import BlogNewWeb.Gettext
    end
  end

  defp view_helpers do
    quote do
      import Phoenix.HTML
      import Phoenix.HTML.Form
      use PhoenixHTMLHelpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import BlogNewWeb.ErrorHelpers
      import BlogNewWeb.Gettext
      alias BlogNewWeb.Router.Helpers, as: Routes

      unquote(verified_routes())
    end
  end

  def verified_routes do
    quote do
      use Phoenix.VerifiedRoutes,
        endpoint: BlogNewWeb.Endpoint,
        router: BlogNewWeb.Router,
        statics: BlogNewWeb.static_paths()
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
