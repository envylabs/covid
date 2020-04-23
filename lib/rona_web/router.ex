defmodule RonaWeb.Router do
  use RonaWeb, :router
  import Plug.BasicAuth
  import Phoenix.LiveDashboard.Router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {RonaWeb.LayoutView, :live}
  end

  pipeline :admins_only do
    plug :basic_auth, username: "admin", password: "enviouslabs"
  end

  scope "/" do
    pipe_through [:browser, :admins_only]
    live_dashboard "/dashboard", metrics: RonaWeb.Telemetry
  end

  scope "/", RonaWeb do
    pipe_through :browser

    live "/", PageLive
    live "/:fips", PageLive
  end
end
