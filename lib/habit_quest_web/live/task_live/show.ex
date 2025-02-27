defmodule HabitQuestWeb.TaskLive.Show do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Tasks

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "Show Task")
     |> assign(:task, Tasks.get_task!(id))}
  end
end