defmodule HabitQuest.Repo.Migrations.RemoveCompletedFromTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      remove :completed
    end
  end
end
