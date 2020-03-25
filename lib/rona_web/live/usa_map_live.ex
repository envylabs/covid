defmodule RonaWeb.USAMapLive do
  use Phoenix.LiveView

  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  def render(assigns) do
    RonaWeb.MapView.render("usa.html", assigns)
  end
end
