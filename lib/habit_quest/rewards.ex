defmodule HabitQuest.Rewards do
  @moduledoc """
  The Rewards context.
  """

  import Ecto.Query, warn: false
  alias HabitQuest.Repo
  alias HabitQuest.Rewards.Reward

  @doc """
  Returns the list of rewards.
  """
  def list_rewards do
    Repo.all(Reward)
  end

  @doc """
  Gets a single reward.
  """
  def get_reward!(id), do: Repo.get!(Reward, id)

  @doc """
  Creates a reward.
  """
  def create_reward(attrs \\ %{}) do
    %Reward{}
    |> Reward.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Updates a reward.
  """
  def update_reward(%Reward{} = reward, attrs) do
    reward
    |> Reward.changeset(attrs)
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
end
