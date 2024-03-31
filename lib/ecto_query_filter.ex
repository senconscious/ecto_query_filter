defmodule EctoQueryFilter do
  @moduledoc """
  Documentation for `EctoQueryFilter`.
  """

  @callback by_filter({String.t(), any()}, Ecto.Query.t()) :: Ecto.Query.t()

  @spec by_filters(module(), Ecto.Query.t(), map() | Keyword.t(), Keyword.t()) :: Ecto.Query.t()
  def by_filters(module, query, filters, options) do
    ignored_keys = Keyword.get(options, :ignored_keys, [])

    filters
    |> Stream.map(fn {key, value} -> {stringify_key(key), value} end)
    |> Stream.reject(fn {key, _} -> key in ignored_keys end)
    |> Enum.reduce(query, fn filter, query -> module.by_filter(filter, query) end)
  end

  defp stringify_key(key) when is_atom(key), do: Atom.to_string(key)

  defp stringify_key(key) when is_binary(key), do: key

  defmacro __using__(options) do
    quote do
      @behaviour EctoQueryFilter
      @before_compile EctoQueryFilter

      def by_filters(query, filters) do
        EctoQueryFilter.by_filters(__MODULE__, query, filters, unquote(options))
      end
    end
  end

  defmacro __before_compile__(%{module: module}) do
    quote do
      @impl EctoQueryFilter
      def by_filter({name, value}, query) do
        require Logger
        Logger.warning("#{unquote(module)}: Unhandled filter #{name} with value #{inspect(value)}")
        query
      end
    end
  end
end
