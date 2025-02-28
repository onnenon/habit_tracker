defmodule HabitQuest.Repo.Migrations.CreateOneOffTaskCompletions do
  use Ecto.Migration

  def change do
    create table(:one_off_task_completions) do
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :child_id, references(:children, on_delete: :delete_all), null: false
      add :completed_at, :utc_datetime, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:one_off_task_completions, [:task_id, :child_id],
             name: :one_off_task_child_unique_index
           )

    create index(:one_off_task_completions, [:child_id])
  end
end
