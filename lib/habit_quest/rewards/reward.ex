defmodule HabitQuest.Rewards.Reward do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rewards" do
    field :name, :string
    field :description, :string
    field :cost, :integer
    field :child_ids, {:array, :integer}, virtual: true

    many_to_many :children, HabitQuest.Children.Child,
      join_through: HabitQuest.Rewards.ChildReward,
      on_replace: :delete,
      on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(reward, attrs) do
    reward
    |> cast(attrs, [:name, :description, :cost])
    |> validate_required([:name, :description, :cost])
  end
end
