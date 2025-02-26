defmodule HabitQuest.Scheduler do
  use GenServer
  alias HabitQuest.Tasks

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl true
  def init(state) do
    {:ok, state}
  end
end
