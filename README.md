# Rona

To start your Phoenix server:

  * Install dependencies with `mix deps.get`
  * Create and migrate your database with `mix ecto.setup`
  * Install Node.js dependencies with `cd assets && npm install`
  * Start Phoenix endpoint with `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

## Loading initial data

When starting with a clean database, run `iex -S mix` and then enter the following
to load the most recent data. Each of these steps will take a while to run and will
produce a lot of output in your iex console.

```
Rona.Data.load_usa(:ny_times)
Date.range(Date.from_iso8601!("2020-03-22"), Date.utc_today()) |> Enum.each(& Rona.Data.load_usa(:johns_hopkins, &1))
Rona.Data.load_usa(:census)
Rona.Data.update_deltas(Rona.Cases.StateReport)
Rona.Data.update_deltas(Rona.Cases.CountyReport)
```

