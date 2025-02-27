defmodule HabitQuest.Repo.Migrations.RemoveUnusedTaskRecurringColumns do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      remove :recurring
      remove :recurring_interval
      remove :recurring_period
    end
  end
end
