defmodule SimpleRegistry do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register(name) do
    GenServer.call(__MODULE__, {:register, name, self()})
  end

  def whereis(name) do
    GenServer.call(__MODULE__, {:register, name})
  end

  @impl GenServer
  def init(_) do
    Process.flag(:trap_exit, true)

    {:ok, %{}}
  end

  @impl GenServer

  def handle_call({:register, key, pid}, _, state) do
    case(Map.get(state, key)) do
      nil ->
        Process.link(pid)
        {:reply, :ok, Map.put(state, key, pid)}

      _ ->
        {:reply, :error, state}
    end
  end

  @impl GenServer

  def handle_call({:whereis, name}, _, state) do
    {:reply, Map.get(state, name), state}
  end

  @impl GenServer

  def handle_info({:EXIT, pid, _reason}, process_registry) do
    {:noreply, deregister_pid(process_registry, pid)}
  end

  defp deregister_pid(process_registry, pid) do
    process_registry
    |> Enum.reject(fn {_key, registered_process} -> registered_process === pid end)
    |> Enum.into(%{})
  end
end
