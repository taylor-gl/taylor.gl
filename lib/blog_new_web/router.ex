defmodule BlogNewWeb.Router do
  use BlogNewWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", BlogNewWeb do
    pipe_through :browser

    get "/", HomeController, :show
    get "/blog", PostController, :index
    get "/blog/:id", PostController, :show
    get "/creative-writing", WritingController, :index
    get "/creative-writing/:slug", WritingController, :show
    # joke url for blog post 15
    get "/phpmyadmin", PostController, :phpmyadmin
    # joke url for blog post 15
    get "/phpmyadmin.", PostController, :phpmyadmin
    get "/resume/", ResumeController, :show
  end

  # Other scopes may use custom stacks.
  # scope "/api", BlogNewWeb do
  #   pipe_through :api
  # end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through :browser
      live_dashboard "/dashboard", metrics: BlogNewWeb.Telemetry
    end
  end
end
