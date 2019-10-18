defmodule NameGuess.DateFeedTest do
  use ExUnit.Case, async: true
  alias NameGuess.DataSource
  alias NameGuess.DataSource.BambooHR
  alias NameGuess.DataSource.Local

  test "test datasource source matching", _state do
    source_module = DataSource.get_module_of_source("bamboohr")
    assert source_module == BambooHR
  end

  test "test datasource source matching ... two", _state do
    source_module = DataSource.get_module_of_source("local")
    assert source_module == Local
  end
end
