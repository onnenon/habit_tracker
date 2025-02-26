defmodule HabitQuest.Rewards.Reward do
  use Ecto.Schema
  import Ecto.Changeset

  schema "rewards" do
    field :name, :string
    field :description, :string
    field :cost, :integer
    field :image_url, :string
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
    |> cast(attrs, [:name, :description, :cost, :image_url])
    |> validate_required([:name, :description, :cost])
    |> validate_url(:image_url)
  end

  defp validate_url(changeset, field) when is_atom(field) do
    validate_change(changeset, field, fn _, url ->
      if is_nil(url) or valid_url?(url), do: [], else: [{field, "must be a valid URL"}]
    end)
  end

  defp valid_url?(nil), do: true
  defp valid_url?(url) when is_binary(url) do
    uri = URI.parse(url)
    uri.scheme != nil && uri.host != nil
  end
  defp valid_url?(_), do: false
end
