defmodule Rona.Cases do
  @moduledoc """
  The Cases context.
  """

  import Ecto.Query, warn: false
  alias Rona.Repo

  alias Rona.Cases.Report

  @doc """
  Files a report for the given location and date. The report values are
  confirmed cases, recovered, and deceased.

  ## Examples

      iex> file_report(location, "2020-03-01", 20, 10, 2)
      %Report{}

  """
  def file_report(location, date, confirmed, recovered, deceased) do
    report =
      Report
      |> where([r], r.location_id == ^location.id and r.date == ^date)
      |> Repo.one()

    if report do
      report
      |> Report.changeset(%{
        confirmed: confirmed,
        recovered: recovered,
        deceased: deceased,
        active: confirmed - recovered - deceased
      })
      |> Repo.update!()
    else
      location
      |> Ecto.build_assoc(:reports, %{
        date: date,
        confirmed: confirmed,
        recovered: recovered,
        deceased: deceased,
        active: confirmed - recovered - deceased
      })
      |> Repo.insert!()
    end
  end
end
