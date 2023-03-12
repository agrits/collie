defmodule Collie.Bootstrap do
  @moduledoc """
  Bootstraps Elixir libraries
  """

  @doc """
  Adds Elixir libraries do Erlang's code path
  """
  @spec elixir_libs :: true | {:error, :bad_directory}
  def elixir_libs() do
    :code.add_path(String.to_charlist(Application.fetch_env!(:collie, :elixir_ebin)))
  end
end
