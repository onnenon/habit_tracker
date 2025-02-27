defmodule HabitQuest.Repo.Migrations.AddCompletedToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :completed, :boolean, default: false
    end
  end
end
