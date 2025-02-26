defmodule HabitQuestWeb.ChildLive.Show do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Children
  alias HabitQuest.Tasks
  alias HabitQuest.Tasks.Task
  alias HabitQuest.Children.Child
  import Ecto.Query

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    child = Children.get_child!(id)
    tasks = Tasks.list_tasks_for_child(child)

    # Get this week's task completions starting from Monday
    week_start = Date.utc_today() |> Date.beginning_of_week(:monday)
    week_end = Date.utc_today() |> Date.end_of_week(:monday)

    task_completions = Tasks.list_task_completions_in_range(child.id, week_start, week_end)
    IO.inspect(task_completions, label: "Task Completions")
    {:ok,
     socket
     |> assign(:page_title, child.name)
     |> assign(:child, child)
     |> assign(:tasks, tasks)
     |> assign(:task_completions, task_completions)
     |> assign(:current_week, %{start: week_start, end: week_end})}
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
  def handle_event("complete_task", %{"id" => task_id, "date" => date}, socket) do
    task = Tasks.get_task!(task_id)
    child = socket.assigns.child
    completion_date = Date.from_iso8601!(date)

    case Tasks.complete_task(task, child, completion_date) do
      {:ok, %{task_completion: _completion}} ->
        # Weekly task completed successfully
        week_start = socket.assigns.current_week.start
        week_end = socket.assigns.current_week.end
        task_completions = Tasks.list_task_completions_in_range(child.id, week_start, week_end)

        IO.inspect(task_completions, label: "Task Completions")
        Children.award_points(child, task.points)
        {:noreply,
         socket
         |> assign(:task_completions, task_completions)
         |> put_flash(:info, "Task completed successfully!")}

      {:ok, %{task: _updated_task}} ->
        # Punch card task updated successfully
        if task.current_completions + 1 >= task.completions_required do
          Children.award_points(child, task.points)
        end

        {:noreply,
         socket
         |> put_flash(:info, "Task progress updated!")
         |> assign(:tasks, Tasks.list_tasks_for_child(child))}

      {:error, _, changeset, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error completing task: #{format_errors(changeset)}")}
    end
  end

  def handle_event("complete_task", %{"id" => task_id}, socket) do
    task = Tasks.get_task!(task_id)
    child = socket.assigns.child

    case Tasks.complete_task(task, child) do
      {:ok, %{task_completion: _completion}} ->
        # Weekly task completed successfully
        week_start = socket.assigns.current_week.start
        week_end = socket.assigns.current_week.end
        task_completions = Tasks.list_task_completions_in_range(child.id, week_start, week_end)

        Children.award_points(child, task.points)
        {:noreply,
         socket
         |> assign(:task_completions, task_completions)
         |> put_flash(:info, "Task completed successfully!")}

      {:ok, %{task: _updated_task}} ->
        # Punch card task updated successfully
        if task.current_completions + 1 >= task.completions_required do
          Children.award_points(child, task.points)
        end

        {:noreply,
         socket
         |> put_flash(:info, "Task progress updated!")
         |> assign(:tasks, Tasks.list_tasks_for_child(child))}

      {:error, _, changeset, _} ->
        {:noreply,
         socket
         |> put_flash(:error, "Error completing task: #{format_errors(changeset)}")}
    end
  end

  def can_complete_task?(task, child, date \\ nil) do
    date = date || Date.utc_today()

    case task.task_type do
      "weekly" ->
        day_name = date |> Date.day_of_week() |> day_number_to_name()
        !Tasks.task_completed_on_date?(task, child.id, date) &&
        day_name in (task.schedule_days || [])
      "punch_card" ->
        task.current_completions < task.completions_required
      "one_off" ->
        !task.completed
    end
  end

  def today_name do
    Date.utc_today()
    |> Date.day_of_week()
    |> day_number_to_name()
  end

  def next_available_day(nil), do: "No schedule set"
  def next_available_day([]), do: "No schedule set"
  def next_available_day(schedule_days) do
    today_num = Date.utc_today() |> Date.day_of_week()

    schedule_numbers = Enum.map(schedule_days, &day_name_to_number/1)

    next_day = Enum.find(schedule_numbers, fn day ->
      day > today_num
    end) || List.first(schedule_numbers)

    day_number_to_name(next_day)
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

  defp format_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
    |> Enum.map(fn {k, v} -> "#{k} #{v}" end)
    |> Enum.join(", ")
  end
end
