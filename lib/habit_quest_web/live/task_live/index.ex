defmodule HabitQuestWeb.TaskLive.Index do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Tasks
  alias HabitQuest.Tasks.Task
  alias HabitQuest.Children

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      tasks: list_tasks(),
      children: list_children()
    )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Habit")
    |> assign(:task, %Task{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Manage Habits")
    |> assign(:task, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Habit")
    |> assign(:task, Tasks.get_task!(id))
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, _} = Tasks.delete_task(task)

    {:noreply, assign(socket, :tasks, list_tasks())}
  end

  defp list_tasks do
    Tasks.list_tasks()
  end

  defp list_children do
    Children.list_children()
  end
end
