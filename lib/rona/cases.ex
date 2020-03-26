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

  @doc """
  Returns the list of dates for which we have case reports.
  """
  def list_dates do
    Report
    |> select([r], r.date)
    |> order_by([r], r.date)
    |> distinct(true)
    |> Repo.all()
  end

  @doc """
  Returns all the case reports for a given date.
  """
  def for_date(date) do
    Report
    |> where([r], r.date == ^date)
    |> preload(:location)
    |> Repo.all()
  end
end
