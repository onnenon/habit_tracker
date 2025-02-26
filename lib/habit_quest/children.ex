defmodule HabitQuest.Children do
  @moduledoc """
  The Children context.
  """

  import Ecto.Query, warn: false
  alias HabitQuest.Repo

  alias HabitQuest.Children.Child

  @doc """
  Returns the list of children.
  """
  def list_children do
    Repo.all(Child)
  end

  @doc """
  Gets a single child.
  """
  def get_child!(id), do: Repo.get!(Child, id)

  @doc """
  Creates a child.
  """
  def create_child(attrs \\ %{}) do
    %Child{}
    |> Child.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a child.
  """
  def update_child(%Child{} = child, attrs) do
    child
    |> Child.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Deletes a child.
  """
  def delete_child(%Child{} = child) do
    Repo.delete(child)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking child changes.
  """
  def change_child(%Child{} = child, attrs \\ %{}) do
    Child.changeset(child, attrs)
  end

  @doc """
  Awards points to a child and saves the updated points to the database.
  """
  def award_points(%Child{} = child, points) when is_integer(points) do
    child
    |> Child.changeset(%{points: child.points + points})
    |> Repo.update()
  end
end
