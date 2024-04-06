defmodule EctoQueryFilter do
  @moduledoc """
  Provides utility functions to reduce boilerplate when introducing filtering
  from map/struct.

  ## Basic usage

  ```elixir
  defmodule Acme.Deals.DealQuery do
    use EctoQueryFilter

    def list_deals do
      Deal
      |> with_filters(%{client_budget: 1_000, status: :finished})
      |> Repo.all()
    end

    def with_filter({:status, status}, query) when is_deal_status(status) do
      where(query, [deal], deal.status == ^status)
    end

    def with_filter({:client_budget, client_budget}, query) when is_integer(client_budget) do
      where(query, [deal], deal.client_budget == ^client_budget)
    end

    ...
  ```

  If there is no clause for filter than `Ligger.warning/1` macro will be invoked.

  ## Ignore specific filters

  You can ignore specific filters to avoid receiving warning from Logger like that:

  ```elixir
  use EctoQueryFilter, ignored: [:page, :page_size]
  ```

  ## Optional filters

  You can automatically skip filter if it's value is `nil` with `:optional` option:

  ```elixir
  use EctoQueryFilter, optional: [:action]
  ```

  ## Notice

  Be advised that library is intended to be used only with atom keys. That's is on
  purpose. Never trust user input.
  """

  @callback with_filter({atom(), any()}, Ecto.Query.t()) :: Ecto.Query.t()

  defmacro __using__(opts) do
    ignored = Keyword.get(opts, :ignored)
    optional = Keyword.get(opts, :optional)

    quote do
      @behaviour EctoQueryFilter

      require Logger

      def with_filters(query, filters) when is_struct(filters) do
        with_filters(query, Map.from_struct(filters))
      end

      def with_filters(query, filters) do
        Enum.reduce(filters, query, &with_filter/2)
      end

      if unquote(ignored) do
        def with_filter({filter, _}, query) when filter in unquote(ignored), do: query
      end

      if unquote(optional) do
        def with_filter({filter, nil}, query) when filter in unquote(optional), do: query
      end

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote do
      def with_filter({filter, value}, query) do
        Logger.warning(
          "Unhandled filter #{filter} with value #{inspect(value)} in #{unquote(__MODULE__)}"
        )

        query
      end
    end
  end
end
