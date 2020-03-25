defmodule Rona.Repo do
  use Ecto.Repo,
    otp_app: :rona,
    adapter: Ecto.Adapters.Postgres
end
