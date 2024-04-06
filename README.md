# EctoQueryFilter

**Provides utilities to apply filter on Ecto.Query**

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ecto_query_filter` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ecto_query_filter, "~> 0.1.0"}
  ]
end
```

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
