defmodule HabitQuest.Rewards.ChildReward do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "children_rewards" do
    belongs_to :child, HabitQuest.Children.Child
    belongs_to :reward, HabitQuest.Rewards.Reward

    timestamps(type: :utc_datetime)
  end

  def changeset(child_reward, attrs) do
    child_reward
    |> cast(attrs, [:child_id, :reward_id])
    |> validate_required([:child_id, :reward_id])
    |> unique_constraint([:child_id, :reward_id])
  end
end
