defmodule HabitQuestWeb.TaskLive.Index do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Tasks
  alias HabitQuest.Tasks.Task
  alias HabitQuest.Children

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> stream(:tasks, [])
     |> assign(:children, list_children())
     |> assign(:selected_tab, "habits")
     |> assign(:show_completed_tasks, false)}
  end

  @impl true
  def handle_params(params, _url, socket) do
    tab = Map.get(params, "tab", "habits")
    tasks = list_tasks_with_completions()

    socket =
      socket
      |> assign(:selected_tab, tab)
      |> handle_task_grouping(tasks, tab)

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
      |> HabitQuest.Repo.preload(:children)

    socket
    |> assign(:page_title, "Edit Habit")
    |> assign(:task, task)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    task = Tasks.get_task!(id)
    {:ok, _} = Tasks.delete_task(task)

    tasks = list_tasks_with_completions()
    {:noreply, handle_task_grouping(socket, tasks, socket.assigns.selected_tab)}
  end

  @impl true
  def handle_event("toggle-completed", _, socket) do
    {:noreply,
     socket
     |> assign(:show_completed_tasks, !socket.assigns.show_completed_tasks)
     |> handle_task_grouping(list_tasks_with_completions(), socket.assigns.selected_tab)}
  end

  @impl true
  def handle_info({HabitQuestWeb.TaskLive.FormComponent, {:saved, _task}}, socket) do
    tasks = list_tasks_with_completions()
    {:noreply, handle_task_grouping(socket, tasks, socket.assigns.selected_tab)}
  end

  defp list_tasks_with_completions do
    Tasks.list_tasks()
    |> HabitQuest.Repo.preload([
      :children,
      one_off_task_completions: [:child],
      task_completions: [:child]
    ])
  end

  defp list_children do
    Children.list_children()
  end

  defp handle_task_grouping(socket, tasks, "one-off") do
    one_off_tasks = Enum.filter(tasks, fn task -> task.task_type == "one_off" end)

    {completed, incomplete} =
      Enum.split_with(one_off_tasks, fn task ->
        children_count = length(task.children)
        completions_count = length(task.one_off_task_completions)
        children_count > 0 && completions_count == children_count
      end)

    visible_tasks =
      if socket.assigns.show_completed_tasks do
        incomplete ++ completed
      else
        incomplete
      end

    socket
    |> stream(:tasks, visible_tasks, reset: true)
  end

  defp handle_task_grouping(socket, tasks, "habits") do
    habit_tasks = Enum.filter(tasks, fn task -> task.task_type in ["weekly", "punch_card"] end)

    socket
    |> stream(:tasks, habit_tasks, reset: true)
  end

  defp handle_task_grouping(socket, _tasks, _), do: socket
end
