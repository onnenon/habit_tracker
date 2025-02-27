defmodule HabitQuest.Rewards.RedeemedReward do
  use Ecto.Schema
  import Ecto.Changeset

  schema "redeemed_rewards" do
    field :fulfilled, :boolean, default: false
    field :redeemed_at, :utc_datetime
    field :fulfilled_at, :utc_datetime

    belongs_to :child, HabitQuest.Children.Child
    belongs_to :reward, HabitQuest.Rewards.Reward

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(redeemed_reward, attrs) do
    redeemed_reward
    |> cast(attrs, [:fulfilled, :redeemed_at, :fulfilled_at, :child_id, :reward_id])
    |> validate_required([:fulfilled, :redeemed_at, :child_id, :reward_id])
  end
end
