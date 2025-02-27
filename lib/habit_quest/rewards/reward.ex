defmodule HabitQuest.Rewards.Reward do
  use Ecto.Schema
  import Ecto.Changeset

  @compile {:no_warn_undefined, HabitQuest.Rewards.ChildReward}

  schema "rewards" do
    field :name, :string
    field :description, :string
    field :points, :integer
    field :image, :string
    field :child_ids, {:array, :integer}, virtual: true

    many_to_many :children, HabitQuest.Children.Child,
      join_through: HabitQuest.Rewards.ChildReward,
      on_replace: :delete,
      on_delete: :delete_all

    has_many :redeemed_rewards, HabitQuest.Rewards.RedeemedReward

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reward, attrs) do
    reward
    |> cast(attrs, [:name, :description, :points, :image])
    |> validate_required([:name, :description, :points])
  end
end
