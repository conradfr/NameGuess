
# NameGuess

Phoenix LiveView POC

Company game, matching pictures of employees to names.

## Dependencies

  * Elixir (w/ Erlang & OTP)
  * Postgresql
  * Node / Npm
  * ImageMagick

## Install project

1. Configure app_config.exs & ENV.secret.exs in /config based on .dist templates
2. Adapt the datasources [read about datasources](#datasources)

## Init project

 1. mix deps.get
 2. cd assets && npm install && node node_modules/webpack/bin/webpack.js --mode development
 3. mix ecto.create
 4. mix ecto.migrate

## Start

To start your Phoenix server:

`iex -S mix phx.server` or `mix phx.server`

Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.

Ready to run in production? Please [check our deployment guides](https://hexdocs.pm/phoenix/deployment.html).

## Command

On an iex session:
 * Updating people from BambooHR: NameGuess.Update.people()
 * Updating pictures from BambooHR: NameGuess.Update.pictures()
 * Clean way to stop the server: :init.stop()

Tests: mix test

<a name="datasources"></a>
## Datasources

Datasources are modules in /lib/nameGuess/datasource, using the NameGuess.DataSource behavior.

Two datasource are included, BambooHR and Local. Local use a json file to import people, an example is included in /priv/data, pictures should go in /priv/pics_local and use the jpeg format.

Datasources are updated by default every night, pictures are updated once a week. These tasks schedule is defined in /config/config.exs.

## Learn more about Phoenix

  * Official website: http://www.phoenixframework.org/
  * LiveView: https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html
  * Guides: https://hexdocs.pm/phoenix/overview.html
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
  
