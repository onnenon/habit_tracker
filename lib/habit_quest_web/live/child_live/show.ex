defmodule HabitQuestWeb.ChildLive.Show do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Children
  alias HabitQuest.Tasks

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    child = Children.get_child!(id)
    tasks = Tasks.list_tasks_for_child(child)

    {:noreply,
     socket
     |> assign(:page_title, "#{child.name}'s Dashboard")
     |> assign(:child, child)
     |> assign(:tasks, tasks)}
  end

  @impl true
  def handle_event("complete_task", %{"id" => task_id}, socket) do
    task = Tasks.get_task!(task_id)
    child = socket.assigns.child

    # TODO: Implement task completion logic here
    # This should:
    # 1. Mark the task as complete
    # 2. Award points to the child
    # 3. If recurring, create a new instance of the task

    {:noreply,
     socket
     |> put_flash(:info, "Task completed successfully!")
     |> assign(:tasks, Tasks.list_tasks_for_child(child))}
  end
end
