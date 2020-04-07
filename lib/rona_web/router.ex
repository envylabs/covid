defmodule RonaWeb.Router do
  use RonaWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :put_root_layout, {RonaWeb.LayoutView, :live}
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", RonaWeb do
    pipe_through :browser

    live "/", PageLive
    live "/:fips", PageLive
  end
end
