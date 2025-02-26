defmodule HabitQuest.Repo.Migrations.CreateChildrenTasks do
  use Ecto.Migration

  def change do
    create table(:children_tasks) do
      add :child_id, references(:children, on_delete: :delete_all)
      add :task_id, references(:tasks, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:children_tasks, [:child_id])
    create index(:children_tasks, [:task_id])
    create unique_index(:children_tasks, [:child_id, :task_id])
  end
end
