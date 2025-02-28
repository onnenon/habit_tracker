defmodule HabitQuestWeb.ChildLive.CompletedTasks do
  use HabitQuestWeb, :live_view
  alias HabitQuest.Tasks
  alias HabitQuest.Children

  def mount(%{"id" => id}, _session, socket) do
    child = Children.get_child!(id)
    completed_tasks = Tasks.list_completed_tasks(child)

    {:ok,
     assign(socket,
       page_title: "#{child.name}'s Completed Tasks",
       child: child,
       completed_tasks: completed_tasks
     )}
  end
end
