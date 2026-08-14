defmodule NatureWorld.CitizenSupervisor do
  use DynamicSupervisor

  @stats_table :nature_world_citizen_stats
  @positions_table :nature_world_citizen_positions

  def start_link(opts \\ []) do
    ensure_stats_table()
    ensure_positions_table()

    DynamicSupervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    ensure_stats_table()
    ensure_positions_table()

    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_citizen(attrs) do
    ensure_stats_table()

    child = {NatureWorld.Citizen, attrs}

    DynamicSupervisor.start_child(__MODULE__, child)
  end

  def positions do
    ensure_positions_table()
    :ets.tab2list(@positions_table)
  end

  def put_position(id, x, y) do
    ensure_positions_table()
    :ets.insert(@positions_table, {id, x, y})
  end

  def delete_position(id) do
    ensure_positions_table()
    :ets.delete(@positions_table, id)
  end

  defp ensure_positions_table do
    case :ets.whereis(@positions_table) do
      :undefined ->
        :ets.new(@positions_table, [:named_table, :public, :set])

      _ ->
        :ok
    end
  end

  def record_start(id) do
    ensure_stats_table()
    :ets.update_counter(@stats_table, id, {2, 1}, {id, 0})
  end

  def running_count do
    %{active: active} = DynamicSupervisor.count_children(__MODULE__)
    active
  end

  def restart_count do
    ensure_stats_table()

    @stats_table
    |> :ets.tab2list()
    |> Enum.reduce(0, fn {_id, starts}, acc ->
      acc + max(starts - 1, 0)
    end)
  end

  def stats do
    %{
      running_citizens: running_count(),
      restart_count: restart_count()
    }
  end

  defp ensure_stats_table do
    case :ets.whereis(@stats_table) do
      :undefined ->
        :ets.new(@stats_table, [:named_table, :public, :set])

      _ ->
        :ok
    end
  end
end
