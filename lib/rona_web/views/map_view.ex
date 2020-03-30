defmodule RonaWeb.MapView do
  use RonaWeb, :view

  def label_for(:confirmed), do: "cases"
  def label_for(:confirmed_delta), do: "cases"
  def label_for(:deceased), do: "deaths"
  def label_for(:deceased_delta), do: "deaths"
end
