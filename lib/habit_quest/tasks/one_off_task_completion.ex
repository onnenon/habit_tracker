defmodule HabitQuest.Tasks.OneOffTaskCompletion do
  use Ecto.Schema
  import Ecto.Changeset

  schema "one_off_task_completions" do
    belongs_to :task, HabitQuest.Tasks.Task
    belongs_to :child, HabitQuest.Children.Child
    field :completed_at, :utc_datetime

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(completion, attrs) do
    completion
    |> cast(attrs, [:task_id, :child_id, :completed_at])
    |> validate_required([:task_id, :child_id, :completed_at])
    |> foreign_key_constraint(:task_id)
    |> foreign_key_constraint(:child_id)
    |> unique_constraint([:task_id, :child_id], name: :one_off_task_child_unique_index)
  end
end
