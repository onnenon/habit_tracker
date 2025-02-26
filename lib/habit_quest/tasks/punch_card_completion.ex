defmodule HabitQuest.Tasks.PunchCardCompletion do
  use Ecto.Schema
  import Ecto.Changeset
  import Ecto.Query

  schema "punch_card_completions" do
    field :completed_at, :utc_datetime
    belongs_to :task, HabitQuest.Tasks.Task
    belongs_to :child, HabitQuest.Children.Child

    timestamps()
  end

  @doc false
  def changeset(completion, attrs) do
    completion
    |> cast(attrs, [:completed_at, :task_id, :child_id])
    |> validate_required([:completed_at, :task_id, :child_id])
    |> foreign_key_constraint(:task_id)
    |> foreign_key_constraint(:child_id)
  end

  def completions_for_task(task_id, child_id) do
    from(pc in __MODULE__,
      where: pc.task_id == ^task_id and
             pc.child_id == ^child_id,
      order_by: [desc: :completed_at]
    )
  end
end
