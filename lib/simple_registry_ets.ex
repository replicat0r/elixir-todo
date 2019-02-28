defmodule SimpleRegistryEts do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register(key) do
    Process.link(Process.whereis(__MODULE__))

    if :ets.insert_new(__MODULE__, {key, self()}) do
      :ok
    else
      :error
    end
  end

  def whereis(key) do
    case :ets.lookup(__MODULE__, key) do
      [{^key, pid}] -> pid
      [] -> nil
    end
  end

  @impl GenServer
  def init(_) do
    Process.flag(:trap_exit, true)
    :ets.new(__MODULE__, [:named_table, :public, read_concurrency: true, write_concurrency: true])
    {:ok, nil}
  end

  @impl GenServer

  def handle_info({:EXIT, pid, _reason}, state) do
    :ets.match_delete(__MODULE__, {:_, pid})

    {:noreply, state}
  end
end
