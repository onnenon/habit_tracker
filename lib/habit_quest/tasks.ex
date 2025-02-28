defmodule HabitQuest.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias HabitQuest.Repo

  alias HabitQuest.Tasks.{Task, TaskCompletion, PunchCardCompletion, OneOffTaskCompletion}
  alias HabitQuest.Children.Child

  @doc """
  Returns the list of tasks.
  """
  def list_tasks do
    Task
    |> preload(:children)
    |> Repo.all()
  end

  @doc """
  Gets tasks for a specific child.
  """
  def list_tasks_for_child(%Child{} = child) do
    child
    |> Repo.preload(:tasks)
    |> Map.get(:tasks)
  end

  @doc """
  Gets a single task.
  """
  def get_task!(id) do
    Task
    |> Repo.get!(id)
    |> Repo.preload(:children)
  end

  @doc """
  Creates a task.
  """
  def create_task(attrs \\ %{}, child_ids \\ []) do
    %Task{}
    |> Task.changeset(attrs)
    |> put_children(child_ids)
    |> Repo.insert()
  end

  @doc """
  Updates a task.
  """
  def update_task(%Task{} = task, attrs, child_ids) do
    task
    |> Task.changeset(attrs)
    |> put_children(child_ids)
    |> Repo.update()
  end

  @doc """
  Completes a task for a child on a specific date.
  For weekly tasks, this creates a task completion record.
  For punch card tasks, this increments the completion counter.
  For one-off tasks, this marks them as completed.
  """
  def complete_task(%Task{} = task, %Child{} = child, completion_date \\ nil) do
    case task.task_type do
      "one_off" ->
        # For one-off tasks, just create a completion record
        completed_at = (completion_date || DateTime.utc_now()) |> DateTime.truncate(:second)

        Ecto.Multi.new()
        |> Ecto.Multi.insert(:one_off_completion, %OneOffTaskCompletion{
          task_id: task.id,
          child_id: child.id,
          completed_at: completed_at
        })
        |> Repo.transaction()

      "weekly" ->
        # For weekly tasks, create a completion record for the specific date
        Ecto.Multi.new()
        |> maybe_create_task_completion(task, child, completion_date)
        |> Repo.transaction()

      "punch_card" ->
        # For punch cards, update the counter and create completion record if fully completed
        Ecto.Multi.new()
        |> maybe_update_punch_card(task, child)
        |> Repo.transaction()
    end
  end

  defp maybe_create_task_completion(
         multi,
         %Task{task_type: "weekly"} = task,
         child,
         completion_date
       ) do
    completed_at =
      if completion_date do
        completion_date
        |> DateTime.new!(~T[12:00:00], "Etc/UTC")
      else
        DateTime.utc_now()
      end
      |> DateTime.truncate(:second)

    case Repo.exists?(TaskCompletion.completed_on_date?(task.id, child.id, completed_at)) do
      true ->
        multi

      false ->
        multi
        |> Ecto.Multi.insert(:task_completion, %TaskCompletion{
          task_id: task.id,
          child_id: child.id,
          completed_at: completed_at
        })
    end
  end

  # For punch cards, we don't create completion records until fully completed
  defp maybe_create_task_completion(
         multi,
         %Task{task_type: "punch_card"},
         _child,
         _completion_date
       ),
       do: multi

  defp maybe_create_task_completion(multi, _task, _child, _completion_date), do: multi

  defp maybe_update_punch_card(multi, %Task{task_type: "punch_card"} = task, child) do
    # Only count current completions, don't use PunchCardCompletion table yet
    new_completions = (task.current_completions || 0) + 1

    if new_completions >= task.completions_required do
      # When they complete the punch card, reset counter and create a completion record
      completed_at = DateTime.utc_now() |> DateTime.truncate(:second)

      multi
      |> Ecto.Multi.insert(:punch_card_completion, %PunchCardCompletion{
        task_id: task.id,
        child_id: child.id,
        completed_at: completed_at
      })
      |> Ecto.Multi.update(:task, Task.changeset(task, %{current_completions: 0}))
    else
      # Just increment the counter
      multi
      |> Ecto.Multi.update(:task, Task.changeset(task, %{current_completions: new_completions}))
    end
  end

  defp maybe_update_punch_card(multi, _task, _child), do: multi

  def task_completed_today?(%Task{task_type: "weekly"} = task, child_id) do
    Repo.exists?(TaskCompletion.completed_today?(task.id, child_id))
  end

  def task_completed_today?(_task, _child_id), do: false

  def list_task_completions_in_range(child_id, start_date, end_date) do
    from(tc in TaskCompletion,
      where:
        tc.child_id == ^child_id and
          fragment("date(?)", tc.completed_at) >= ^start_date and
          fragment("date(?)", tc.completed_at) <= ^end_date,
      select: {tc.task_id, fragment("date(?)", tc.completed_at)}
    )
    |> Repo.all()
    |> Enum.group_by(&elem(&1, 0), &elem(&1, 1))
  end

  def task_completed_on_date?(task, child_id, date) do
    Repo.exists?(
      from tc in TaskCompletion,
        where:
          tc.task_id == ^task.id and
            tc.child_id == ^child_id and
            fragment("date(?)", tc.completed_at) == ^date
    )
  end

  @doc """
  Deletes a task.
  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Deletes a task completion record for a specific task, child, and date.
  Returns {:ok, deleted_record} if successful, {:error, :not_found} if no matching record exists.
  """
  def delete_task_completion(task_id, child_id, date) do
    query = TaskCompletion.completed_on_date?(task_id, child_id, date)

    case Repo.one(query) do
      nil -> {:error, :not_found}
      completion -> Repo.delete(completion)
    end
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.
  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    # Make sure we always have children loaded for proper form handling
    task = if Ecto.assoc_loaded?(task.children), do: task, else: Repo.preload(task, :children)

    task
    |> Task.changeset(attrs)
  end

  @doc """
  Returns the status of a task for a specific child.

  Returns:
    - :completed - Task is completed (for the day or fully completed for punch cards)
    - :in_progress - Task is in progress (for punch cards only)
    - :not_started - Task is not started
  """
  def get_task_status(%Task{} = task, child_id) do
    case task.task_type do
      "weekly" ->
        if task_completed_today?(task, child_id), do: :completed, else: :not_started

      "punch_card" ->
        cond do
          # Reset to 0 means it was just completed fully
          task.current_completions == 0 and task.completions_required > 0 -> :completed
          # In progress if there are some completions but not all required ones
          task.current_completions > 0 -> :in_progress
          # Not started yet
          true -> :not_started
        end

      "one_off" ->
        if one_off_task_completed?(task, child_id), do: :completed, else: :not_started

      _ ->
        :not_started
    end
  end

  @doc """
  Returns the number of times a child has fully completed a punch card task
  """
  def count_punch_card_completions(task_id, child_id) do
    from(pc in PunchCardCompletion,
      where:
        pc.task_id == ^task_id and
          pc.child_id == ^child_id,
      select: count(pc.id)
    )
    |> Repo.one()
  end

  @doc """
  Returns whether a one-off task has been completed by a child
  """
  def one_off_task_completed?(%Task{task_type: "one_off"} = task, child_id) do
    Repo.exists?(
      from oc in OneOffTaskCompletion,
        where:
          oc.task_id == ^task.id and
            oc.child_id == ^child_id
    )
  end

  def one_off_task_completed?(_task, _child_id), do: false

  defp put_children(changeset, nil), do: changeset

  defp put_children(changeset, child_ids) when is_list(child_ids) do
    # Ensure we're working with valid integer IDs
    valid_ids =
      child_ids
      |> Enum.filter(&(&1 != nil))
      |> Enum.map(&to_integer/1)
      |> Enum.filter(&(&1 != nil))

    children =
      case valid_ids do
        [] -> []
        ids -> Repo.all(from c in Child, where: c.id in ^ids)
      end

    Ecto.Changeset.put_assoc(changeset, :children, children)
  end

  defp to_integer(val) when is_integer(val), do: val

  defp to_integer(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, ""} -> int
      _ -> nil
    end
  end

  defp to_integer(_), do: nil
end
