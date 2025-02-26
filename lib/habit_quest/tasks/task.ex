defmodule HabitQuest.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :description, :string
    field :title, :string
    field :points, :integer
    field :recurring, :boolean, default: false
    field :recurring_interval, :integer
    field :recurring_period, :string

    many_to_many :children, HabitQuest.Children.Child,
      join_through: "children_tasks",
      on_replace: :delete,
      defaults: []

    timestamps(type: :utc_datetime)
  end

  @recurring_periods ~w(days weeks months)

  def recurring_period_options do
    Enum.map(@recurring_periods, &{String.capitalize(&1), &1})
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :points, :recurring, :recurring_interval, :recurring_period])
    |> validate_required([:title, :description, :points, :recurring])
    |> validate_recurring_fields()
  end

  defp validate_recurring_fields(changeset) do
    case get_field(changeset, :recurring) do
      true ->
        changeset
        |> validate_required([:recurring_interval, :recurring_period])
        |> validate_inclusion(:recurring_period, @recurring_periods)
        |> validate_number(:recurring_interval, greater_than: 0)
      _ -> changeset
    end
  end
end
