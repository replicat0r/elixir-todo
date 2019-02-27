defmodule Todo.Database do
  use GenServer

  @db_folder "./persist"

  def start_link do
    IO.inspect("Starting Database")
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def get(key) do
    choose_worker(key)
    |> Todo.DatabaseWorker.get(key)
  end

  def store(key, data) do
    choose_worker(key)
    |> Todo.DatabaseWorker.store(key, data)
  end

  def choose_worker(key) do
    GenServer.call(__MODULE__, {:choose_worker, key})
  end

  # callbacks
  @impl GenServer

  def init(_) do
    worker_map =
      for i <- 0..2, into: %{} do
        {:ok, pid} = Todo.DatabaseWorker.start_link(@db_folder)
        {i, pid}
      end

    {:ok, worker_map}
  end

  @impl GenServer

  def handle_call({:choose_worker, key}, _, workers) do
    worker_key = :erlang.phash2(key, 3)
    pid = Map.get(workers, worker_key)
    {:reply, pid, workers}
  end
end
