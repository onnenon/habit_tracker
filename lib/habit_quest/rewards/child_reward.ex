defmodule HabitQuest.Rewards.ChildReward do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "children_rewards" do
    belongs_to :child, HabitQuest.Children.Child, primary_key: true
    belongs_to :reward, HabitQuest.Rewards.Reward, primary_key: true

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(child_reward, attrs) do
    child_reward
    |> cast(attrs, [:child_id, :reward_id])
    |> validate_required([:child_id, :reward_id])
    |> unique_constraint([:child_id, :reward_id])
  end
end
