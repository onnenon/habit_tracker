defmodule HabitQuest.Tasks.TaskCompletion do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "task_completions" do
    field :completed_at, :utc_datetime
    belongs_to :task, HabitQuest.Tasks.Task
    belongs_to :child, HabitQuest.Children.Child

    timestamps()
  end

  @doc false
  def changeset(task_completion, attrs) do
    task_completion
    |> cast(attrs, [:completed_at, :task_id, :child_id])
    |> validate_required([:completed_at, :task_id, :child_id])
    |> foreign_key_constraint(:task_id)
    |> foreign_key_constraint(:child_id)
  end

  def completed_today?(task_id, child_id) do
    from(tc in __MODULE__,
      where: tc.task_id == ^task_id and
             tc.child_id == ^child_id and
             fragment("date(?)", tc.completed_at) == fragment("date('now')")
    )
  end

  def completed_on_date?(task_id, child_id, date) do
    from(tc in __MODULE__,
      where: tc.task_id == ^task_id and
             tc.child_id == ^child_id and
             fragment("date(?)", tc.completed_at) == fragment("date(?)", ^date)
    )
  end
end
