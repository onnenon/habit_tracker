defmodule HabitQuest.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :description, :string
    field :title, :string
    field :points, :integer
    field :recurring, :boolean, default: false
    field :child_id, :id

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [:title, :description, :points, :recurring])
    |> validate_required([:title, :description, :points, :recurring])
  end
end
