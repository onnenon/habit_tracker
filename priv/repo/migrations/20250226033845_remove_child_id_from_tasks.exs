defmodule HabitQuest.Repo.Migrations.RemoveChildIdFromTasks do
  use Ecto.Migration

  def change do
    drop index(:tasks, [:child_id])
    alter table(:tasks) do
      remove :child_id
    end
  end
end
