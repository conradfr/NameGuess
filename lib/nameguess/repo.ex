defmodule NameGuess.Repo do
  use Ecto.Repo,
    otp_app: :nameguess,
    adapter: Ecto.Adapters.Postgres
end
