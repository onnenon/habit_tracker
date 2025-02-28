defmodule HabitQuestWeb.TaskLive.Index do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Tasks
  alias HabitQuest.Tasks.Task
  alias HabitQuest.Children

  @impl true
  def mount(_params, _session, socket) do
    tasks = list_tasks()
    children = list_children()

    {:ok,
     socket
     |> stream(:tasks, tasks)
     |> assign(:children, children)
     |> assign(:selected_tab, "habits")}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = Map.get(params, "tab", "habits")
    tasks = list_tasks()
    filtered_tasks = filter_tasks(tasks, tab)

    socket =
      socket
      |> assign(:selected_tab, tab)
      |> stream(:tasks, filtered_tasks, reset: true)

    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Habit")
    |> assign(:task, %Task{children: []})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Manage Habits")
    |> assign(:task, nil)
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    task =
      Tasks.get_task!(id)
      # Ensure children are preloaded
      |> HabitQuest.Repo.preload(:children)

    socket
    |> assign(:page_title, "Edit Habit")
    |> assign(:task, task)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, _} = Tasks.delete_task(task)

    # Refresh tasks with current filter
    tasks = list_tasks()
    filtered_tasks = filter_tasks(tasks, socket.assigns.selected_tab)
    {:noreply, stream(socket, :tasks, filtered_tasks, reset: true)}
  end

  @impl true
  def handle_info({HabitQuestWeb.TaskLive.FormComponent, {:saved, _task}}, socket) do
    # Refresh tasks with current filter
    tasks = list_tasks()
    filtered_tasks = filter_tasks(tasks, socket.assigns.selected_tab)
    {:noreply, stream(socket, :tasks, filtered_tasks, reset: true)}
  end

  defp list_tasks do
    Tasks.list_tasks()
  end

  defp list_children do
    Children.list_children()
  end

  defp filter_tasks(tasks, "one-off") do
    Enum.filter(tasks, fn task -> task.task_type == "one_off" end)
  end

  defp filter_tasks(tasks, "habits") do
    Enum.filter(tasks, fn task -> task.task_type in ["weekly", "punch_card"] end)
  end

  defp filter_tasks(tasks, _), do: tasks
end
