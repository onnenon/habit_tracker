defmodule HabitQuest.Tasks.ChildTask do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key false
  schema "children_tasks" do
    belongs_to :child, HabitQuest.Children.Child
    belongs_to :task, HabitQuest.Tasks.Task

    timestamps(type: :utc_datetime)
  end

  def changeset(child_task, attrs) do
    child_task
    |> cast(attrs, [:child_id, :task_id])
    |> validate_required([:child_id, :task_id])
    |> unique_constraint([:child_id, :task_id])
  end
end
