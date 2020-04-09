defmodule RonaWeb.MapView do
  use RonaWeb, :view

  def label_for(:confirmed), do: "cases"
  def label_for(:confirmed_delta), do: "cases"
  def label_for(:deceased), do: "deaths"
  def label_for(:deceased_delta), do: "deaths"

  def legend_title_for(:confirmed), do: "Total Cases"
  def legend_title_for(:confirmed_delta), do: "New Cases"
  def legend_title_for(:deceased), do: "Total Deaths"
  def legend_title_for(:deceased_delta), do: "New Deaths"
end
