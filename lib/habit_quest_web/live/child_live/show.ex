defmodule HabitQuestWeb.ChildLive.Show do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Children
  alias HabitQuest.Tasks
  alias HabitQuest.Tasks.Task
  alias HabitQuest.Children.Child
  import Ecto.Query

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    child = Children.get_child!(id)
    |> HabitQuest.Repo.preload([tasks: from(task in Task, order_by: [desc: task.inserted_at])])
    |> Child.changeset(%{})
    |> Ecto.Changeset.apply_changes()

    {:noreply,
     socket
     |> assign(:page_title, "#{child.name}'s Dashboard")
     |> assign(:child, child)
     |> assign(:tasks, child.tasks)}
  end

  @impl true
  def handle_event("complete_task", %{"id" => task_id}, socket) do
    task = Tasks.get_task!(task_id)
    child = socket.assigns.child

    case task.task_type do
      "one_off" ->
        # One-off tasks are completed once and removed
        {:ok, _} = Tasks.update_task(task, %{}, [])
        Children.award_points(child, task.points)

      "punch_card" ->
        new_completions = (task.current_completions || 0) + 1
        if new_completions >= task.completions_required do
          # Award points and reset completions when reaching the goal
          {:ok, _} = Tasks.update_task(task, %{current_completions: 0}, task.child_ids)
          Children.award_points(child, task.points)
        else
          # Just increment completions
          {:ok, _} = Tasks.update_task(task, %{current_completions: new_completions}, task.child_ids)
        end

      "weekly" ->
        # Check if task is scheduled for today
        today = today_name()
        if today in (task.schedule_days || []) do
          Children.award_points(child, task.points)
        end
    end

    {:noreply,
     socket
     |> put_flash(:info, "Task completed successfully!")
     |> assign(:tasks, Tasks.list_tasks_for_child(child))}
  end

  def can_complete_task?(task) do
    case task.task_type do
      "one_off" -> true
      "punch_card" -> true
      "weekly" -> today_name() in (task.schedule_days || [])
    end
  end

  def today_name do
    Date.utc_today() |> Date.day_of_week() |> day_number_to_name()
  end

  def next_available_day(nil), do: "No schedule set"
  def next_available_day([]), do: "No schedule set"
  def next_available_day(schedule_days) do
    today_num = Date.utc_today() |> Date.day_of_week()

    schedule_numbers = Enum.map(schedule_days, &day_name_to_number/1)

    next_day = Enum.find(schedule_numbers, fn day ->
      day > today_num
    end) || List.first(schedule_numbers)

    day_number_to_name(next_day) |> String.capitalize()
  end

  defp day_number_to_name(1), do: "monday"
  defp day_number_to_name(2), do: "tuesday"
  defp day_number_to_name(3), do: "wednesday"
  defp day_number_to_name(4), do: "thursday"
  defp day_number_to_name(5), do: "friday"
  defp day_number_to_name(6), do: "saturday"
  defp day_number_to_name(7), do: "sunday"

  defp day_name_to_number("monday"), do: 1
  defp day_name_to_number("tuesday"), do: 2
  defp day_name_to_number("wednesday"), do: 3
  defp day_name_to_number("thursday"), do: 4
  defp day_name_to_number("friday"), do: 5
  defp day_name_to_number("saturday"), do: 6
  defp day_name_to_number("sunday"), do: 7
end
