defmodule HabitQuest.Repo.Migrations.AddCompletedTodayToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :completed_today, :boolean, default: false
    end
  end
end
