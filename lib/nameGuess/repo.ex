defmodule NameGuess.Repo do
  use Ecto.Repo,
    otp_app: :nameGuess,
    adapter: Ecto.Adapters.Postgres
end
