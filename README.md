
# NameGuess

A company game, matching pictures of employees to names.

(Phoenix LiveView POC)

Demo (with some special colleagues) : https://every-weak-tapaculo.gigalixirapp.com

## Dependencies

  * Elixir (w/ Erlang & OTP)
  * Postgresql
  * Node / Npm
  * ImageMagick

## Install project

1. Configure app_config.exs & ENV.secret.exs in /config based on .dist templates (dev) or env vars (prod)
2. Adapt the datasources [read about datasources](#datasources)

## Init project

 1. mix deps.get
 2. cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development
 3. mix ecto.create
 4. mix ecto.migrate
 5. add at least one entry in the space table

## Start

To start your Phoenix server:

`iex -S mix phx.server` or `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Command

In an iex session:
 * Updating people: NameGuess.Update.people()
 * Updating pictures: NameGuess.Update.pictures()
 * Clean way to stop the server: :init.stop()

Tests: mix test

<a name="datasources"></a>
## Datasources

Datasources are modules in /lib/nameGuess/datasource, implementing the NameGuess.DataSource behaviour.

Three datasource are included, BambooHR, Wikipedia POTUS (demo) and Local. Local uses a json file to import people, an example is included in /priv/data, pictures should go in /priv/pics_local and use the jpeg format.

Datasources are updated by default every night, pictures are updated once a week. These tasks schedule is defined in /config/config.exs.

  
