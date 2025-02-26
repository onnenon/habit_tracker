defmodule HabitQuest.Rewards do
  @moduledoc """
  The Rewards context.
  """

  import Ecto.Query, warn: false
  alias HabitQuest.Repo
  alias HabitQuest.Rewards.Reward
  alias HabitQuest.Children.Child

  @doc """
  Returns the list of rewards.
  """
  def list_rewards do
    Reward
    |> preload(:children)
    |> Repo.all()
  end

  @doc """
  Gets rewards for a specific child.
  """
  def list_rewards_for_child(%Child{} = child) do
    child
    |> Repo.preload(:rewards)
    |> Map.get(:rewards)
  end

  @doc """
  Gets a single reward.
  """
  def get_reward!(id) do
    Reward
    |> Repo.get!(id)
    |> Repo.preload(:children)
  end

  @doc """
  Creates a reward.
  """
  def create_reward(attrs \\ %{}, child_ids \\ []) do
    %Reward{}
    |> Reward.changeset(attrs)
    |> put_children(child_ids)
    |> Repo.insert()
  end

  @doc """
  Updates a reward.
  """
  def update_reward(%Reward{} = reward, attrs, child_ids \\ []) do
    reward
    |> Reward.changeset(attrs)
    |> put_children(child_ids)
    |> Repo.update()
  end

  @doc """
  Deletes a reward.
  """
  def delete_reward(%Reward{} = reward) do
    Repo.delete(reward)
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking reward changes.
  """
  def change_reward(%Reward{} = reward, attrs \\ %{}) do
    Reward.changeset(reward, attrs)
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
