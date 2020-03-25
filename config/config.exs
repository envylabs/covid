# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
#
# This configuration file is loaded before any dependency and
# is restricted to this project.

# General application configuration
use Mix.Config

config :rona,
  ecto_repos: [Rona.Repo]

# Configures the endpoint
config :rona, RonaWeb.Endpoint,
  url: [host: "localhost"],
  secret_key_base: "cwN4w6zKQbsP/lWTgJA9cRbm7qepf0exoBxTlMWDVlMjUZniuMscDzU65hPDFNUs",
  render_errors: [view: RonaWeb.ErrorView, accepts: ~w(html json)],
  pubsub: [name: Rona.PubSub, adapter: Phoenix.PubSub.PG2]

# Configures Elixir's Logger
config :logger, :console,
  format: "$time $metadata[$level] $message\n",
  metadata: [:request_id]

# Use Jason for JSON parsing in Phoenix
config :phoenix, :json_library, Jason

# Import environment specific config. This must remain at the bottom
# of this file so it overrides the configuration defined above.
import_config "#{Mix.env()}.exs"
