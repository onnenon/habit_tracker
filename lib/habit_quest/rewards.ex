defmodule HabitQuest.Rewards do
  @moduledoc """
  The Rewards context.
  """

  import Ecto.Query, warn: false
  alias HabitQuest.Repo
  alias HabitQuest.Rewards.Reward
  alias HabitQuest.Children.Child
  alias HabitQuest.Rewards.RedeemedReward

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
    reward = Reward
    |> Repo.get!(id)
    |> Repo.preload(:children)

    # Initialize the virtual child_ids field
    Map.put(reward, :child_ids, Enum.map(reward.children, & &1.id))
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

  @doc """
  Creates a redeemed reward entry.
  """
  def create_redeemed_reward(attrs \\ %{}) do
    %RedeemedReward{}
    |> RedeemedReward.changeset(attrs)
    |> Repo.insert()
  end

  @doc """
  Lists all redeemed rewards with preloaded associations.
  Optional parameter to filter by fulfilled status.
  """
  def list_redeemed_rewards(fulfilled \\ nil) do
    RedeemedReward
    |> maybe_filter_by_fulfilled(fulfilled)
    |> order_by([r], desc: r.redeemed_at)
    |> preload([:child, :reward])
    |> Repo.all()
  end

  @doc """
  Updates a redeemed reward's fulfilled status.
  """
  def update_redeemed_reward(%RedeemedReward{} = redeemed_reward, attrs) do
    redeemed_reward
    |> RedeemedReward.changeset(attrs)
    |> Repo.update()
  end

  @doc """
  Gets a single redeemed reward with preloaded associations.
  """
  def get_redeemed_reward!(id) do
    RedeemedReward
    |> Repo.get!(id)
    |> Repo.preload([:child, :reward])
  end

  @doc """
  Cancels a redeemed reward and refunds points to the child.
  Returns {:ok, redeemed_reward} on success or {:error, reason} on failure.
  """
  def cancel_redeemed_reward(%RedeemedReward{} = redeemed_reward) do
    if redeemed_reward.fulfilled do
      {:error, :already_fulfilled}
    else
      Repo.transaction(fn ->
        # Refund points to the child
        child = HabitQuest.Children.get_child!(redeemed_reward.child_id)
        HabitQuest.Children.award_points(child, redeemed_reward.reward.points)

        # Delete the redeemed reward
        Repo.delete!(redeemed_reward)
      end)
    end
  end

  defp put_children(changeset, nil), do: changeset
  defp put_children(changeset, child_ids) when is_list(child_ids) do
    # Ensure we're working with valid integer IDs
    valid_ids = child_ids
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

  # Private helper for filtering by fulfilled status
  defp maybe_filter_by_fulfilled(query, nil), do: query
  defp maybe_filter_by_fulfilled(query, fulfilled) when is_boolean(fulfilled) do
    where(query, [r], r.fulfilled == ^fulfilled)
  end
end
