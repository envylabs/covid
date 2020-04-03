defmodule Rona.Cases do
  @moduledoc """
  The Cases context.
  """

  import Ecto.Query, warn: false
  alias Rona.Repo

  alias Rona.Cases.Report
  alias Rona.Cases.StateReport
  alias Rona.Cases.CountyReport

  @doc """
  Files a report for the given location and date. The report values are
  confirmed cases, recovered, and deceased.

  ## Examples

      iex> file_report(location, "2020-03-01", 20, 10, 2)
      %Report{}

  """
  def file_report(%Rona.Places.Location{} = location, date, confirmed, recovered, deceased) do
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

  def file_report(%Rona.Places.State{} = state, date, confirmed, deceased) do
    report =
      StateReport
      |> where([r], r.state_id == ^state.id and r.date == ^date)
      |> Repo.one()

    if report do
      report
      |> StateReport.changeset(%{
        confirmed: confirmed,
        deceased: deceased
      })
      |> Repo.update!()
    else
      state
      |> Ecto.build_assoc(:reports, %{
        date: date,
        confirmed: confirmed,
        deceased: deceased
      })
      |> Repo.insert!()
    end
  end

  def file_report(%Rona.Places.County{} = county, date, confirmed, deceased) do
    report =
      CountyReport
      |> where([r], r.county_id == ^county.id and r.date == ^date)
      |> Repo.one()

    if report do
      report
      |> CountyReport.changeset(%{
        confirmed: confirmed,
        deceased: deceased
      })
      |> Repo.update!()
    else
      county
      |> Ecto.build_assoc(:reports, %{
        date: date,
        confirmed: confirmed,
        deceased: deceased
      })
      |> Repo.insert!()
    end
  end

  def update_report(%Report{} = report, attrs) do
    report
    |> Report.changeset(attrs)
    |> Repo.update()
  end

  def update_report(%StateReport{} = report, attrs) do
    report
    |> StateReport.changeset(attrs)
    |> Repo.update()
  end

  def update_report(%CountyReport{} = report, attrs) do
    report
    |> CountyReport.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Returns the list of dates for which we have case reports.
  """
  def list_dates(type) do
    type
    |> select([r], r.date)
    |> order_by([r], r.date)
    |> distinct(true)
    |> Repo.all()
  end

  @doc """
  Returns the most recent update timestamp for the given report type.
  """
  def latest_update(type) do
    type
    |> select([r], max(r.updated_at))
    |> Repo.one()
  end

  @doc """
  Returns all the case reports for a given date.
  """
  def for_date(Report, date) do
    Report
    |> where([r], r.date == ^date)
    |> preload(:location)
    |> Repo.all()
  end

  def for_date(StateReport, date) do
    StateReport
    |> where([r], r.date == ^date)
    |> preload(:state)
    |> Repo.all()
  end

  def for_date(CountyReport, date) do
    CountyReport
    |> where([r], r.date == ^date)
    |> join(:left, [r], c in assoc(r, :county))
    |> where([r, c], c.fips != "")
    |> preload(:county)
    |> Repo.all()
  end

  def for_dates(CountyReport, dates) do
    CountyReport
    |> where([r], r.date in ^dates)
    |> join(:left, [r], c in assoc(r, :county))
    |> where([r, c], c.fips != "")
    |> order_by(:date)
    |> preload(:county)
    |> Repo.all()
  end

  def max_confirmed(CountyReport) do
    CountyReport
    |> select([r], max(r.confirmed))
    |> join(:left, [r], c in assoc(r, :county))
    |> where([r, c], c.fips != "")
    |> Repo.one()
  end

  def max_confirmed(StateReport) do
    StateReport
    |> select([r], max(r.confirmed))
    |> join(:left, [r], s in assoc(r, :state))
    |> where([r, s], s.fips != "")
    |> Repo.one()
  end

  def max_confirmed_delta(CountyReport) do
    CountyReport
    |> select([r], max(r.confirmed_delta))
    |> join(:left, [r], c in assoc(r, :county))
    |> where([r, c], c.fips != "")
    |> Repo.one()
  end

  def max_confirmed_delta(StateReport) do
    StateReport
    |> select([r], max(r.confirmed_delta))
    |> join(:left, [r], s in assoc(r, :state))
    |> where([r, s], s.fips != "")
    |> Repo.one()
  end

  def max_deceased(CountyReport) do
    CountyReport
    |> select([r], max(r.deceased))
    |> join(:left, [r], c in assoc(r, :county))
    |> where([r, c], c.fips != "")
    |> Repo.one()
  end

  def max_deceased(StateReport) do
    StateReport
    |> select([r], max(r.deceased))
    |> join(:left, [r], s in assoc(r, :state))
    |> where([r, s], s.fips != "")
    |> Repo.one()
  end
end
