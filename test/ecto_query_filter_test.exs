defmodule EctoQueryFilterTest do
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  defmodule DealQuery do
    use EctoQueryFilter, ignored_keys: ["page"]

    import Ecto.Query

    def list_all_query(filters) do
      "deals"
      |> by_filters(filters)
      |> select([:id, :name])
    end

    @impl EctoQueryFilter
    def by_filter({"name", name}, query) when is_binary(name) do
      where(query, name: ^name)
    end
  end

  test "no filters applied" do
    assert query = DealQuery.list_all_query(%{})
    assert query.wheres == []
  end

  test "filter applied" do
    assert %{wheres: [%{expr: filter}]} = DealQuery.list_all_query(%{"name" => "beautiful_name"})
    assert Macro.to_string(filter) == "&0.name() == ^0"

    assert %{wheres: [%{expr: filter}]} = DealQuery.list_all_query(%{name: "beautiful_name"})
    assert Macro.to_string(filter) == "&0.name() == ^0"
  end

  test "filter has no clause" do
    assert log = capture_log(fn -> DealQuery.list_all_query(%{"name" => nil}) end)

    assert String.contains?(
             log,
             "[warning] Elixir.EctoQueryFilterTest.DealQuery: Unhandled filter name with value nil"
           )
  end

  test "ignored key" do
    assert %{wheres: []} = DealQuery.list_all_query(%{"page" => 1})
    assert capture_log(fn -> DealQuery.list_all_query(%{"page" => 1}) end) == ""
  end
end
