defmodule HabitQuest.Repo.Migrations.CreatePunchCardCompletions do
  use Ecto.Migration

  def change do
    create table(:punch_card_completions) do
      add :completed_at, :utc_datetime, null: false
      add :task_id, references(:tasks, on_delete: :delete_all), null: false
      add :child_id, references(:children, on_delete: :delete_all), null: false

      timestamps()
    end

    create index(:punch_card_completions, [:task_id])
    create index(:punch_card_completions, [:child_id])
    create index(:punch_card_completions, [:completed_at])
  end
end
