defmodule HabitQuest.Tasks do
  @moduledoc """
  The Tasks context.
  """

  import Ecto.Query, warn: false
  alias HabitQuest.Repo

  alias HabitQuest.Tasks.Task
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
  def update_task(%Task{} = task, attrs, child_ids \\ nil) do
    task
    |> Task.changeset(attrs)
    |> put_children(child_ids)
    |> Repo.update()
  end

  @doc """
  Deletes a task.
  """
  def delete_task(%Task{} = task) do
    Repo.delete(task)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking task changes.
  """
  def change_task(%Task{} = task, attrs \\ %{}) do
    task
    |> Repo.preload(:children)
    |> Task.changeset(attrs)
  end

  defp put_children(changeset, nil), do: changeset
  defp put_children(changeset, child_ids) when is_list(child_ids) do
    # Ensure we're working with valid integer IDs
    valid_ids = child_ids
    |> Enum.filter(&(&1 != nil))
    |> Enum.map(&to_integer/1)
    |> Enum.filter(&(&1 != nil))

    children = case valid_ids do
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
