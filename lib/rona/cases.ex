defmodule Rona.Cases do
  @moduledoc """
  The Cases context.
  """

  import Ecto.Query, warn: false
  alias Rona.Repo

  alias Rona.Cases.StateReport
  alias Rona.Cases.CountyReport

  def file_report(%Rona.Places.State{} = state, date, confirmed, deceased) do
    remove_duplicate_report(state, date)

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
    remove_duplicate_report(county, date)

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

  def file_report(
        %Rona.Places.State{} = state,
        date,
        tested,
        testing_rate,
        confirmed,
        positive_rate,
        hospitalized,
        hospitalization_rate,
        deceased,
        death_rate
      ) do
    remove_duplicate_report(state, date)

    report =
      StateReport
      |> where([r], r.state_id == ^state.id and r.date == ^date)
      |> Repo.one()

    if report do
      report
      |> StateReport.changeset(%{
        tested: tested,
        testing_rate: testing_rate,
        confirmed: confirmed,
        positive_rate: positive_rate,
        hospitalized: hospitalized,
        hospitalization_rate: hospitalization_rate,
        deceased: deceased,
        death_rate: death_rate
      })
      |> Repo.update!()
    else
      state
      |> Ecto.build_assoc(:reports, %{
        date: date,
        tested: tested,
        testing_rate: testing_rate,
        confirmed: confirmed,
        positive_rate: positive_rate,
        hospitalized: hospitalized,
        hospitalization_rate: hospitalization_rate,
        deceased: deceased,
        death_rate: death_rate
      })
      |> Repo.insert!()
    end
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

  def remove_duplicate_report(%Rona.Places.County{} = county, date) do
    reports =
      CountyReport
      |> where([r], r.county_id == ^county.id and r.date == ^date)
      |> Repo.all()

    if length(reports) > 1 do
      [_ | rest] = reports

      Enum.each(rest, fn report ->
        Repo.delete(report)
      end)
    end
  end

  def remove_duplicate_report(%Rona.Places.State{} = state, date) do
    reports =
      StateReport
      |> where([r], r.state_id == ^state.id and r.date == ^date)
      |> Repo.all()

    if length(reports) > 1 do
      [_ | rest] = reports

      Enum.each(rest, fn report ->
        Repo.delete(report)
      end)
    end
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

  def max_confirmed(CountyReport, county) do
    CountyReport
    |> select([r], max(r.confirmed))
    |> join(:left, [r], c in assoc(r, :county))
    |> where([r, c], c.fips == ^county.fips)
    |> Repo.one()
  end

  def max_confirmed(StateReport, state) do
    StateReport
    |> select([r], max(r.confirmed))
    |> join(:left, [r], s in assoc(r, :state))
    |> where([r, s], s.fips == ^state.fips)
    |> Repo.one()
  end

  def max_confirmed_delta(StateReport, from_date) do
    query =
      if from_date,
        do: StateReport |> where([r], r.date >= ^from_date),
        else: StateReport

    query
    |> select([r], max(r.confirmed_delta))
    |> join(:left, [r], s in assoc(r, :state))
    |> where([r, s], s.fips != "")
    |> Repo.one()
  end

  def max_confirmed_delta(StateReport, state, from_date) do
    query =
      if from_date,
        do: StateReport |> where([r], r.date >= ^from_date),
        else: StateReport

    query
    |> select([r], max(r.confirmed_delta))
    |> join(:left, [r], s in assoc(r, :state))
    |> where([r, s], s.fips == ^state.fips)
    |> Repo.one()
  end

  def max_confirmed_delta(CountyReport, state, from_date) do
    query =
      if from_date,
        do: CountyReport |> where([r], r.date >= ^from_date),
        else: CountyReport

    query
    |> select([r], max(r.confirmed_delta))
    |> join(:left, [r], c in assoc(r, :county))
    |> where([r, c], c.fips != "")
    |> where([r, c], c.state == ^state)
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

  def max_deceased(CountyReport, county) do
    CountyReport
    |> select([r], max(r.deceased))
    |> join(:left, [r], c in assoc(r, :county))
    |> where([r, c], c.fips == ^county.fips)
    |> Repo.one()
  end

  def max_deceased(StateReport, state) do
    StateReport
    |> select([r], max(r.deceased))
    |> join(:left, [r], s in assoc(r, :state))
    |> where([r, s], s.fips == ^state.fips)
    |> Repo.one()
  end
end
