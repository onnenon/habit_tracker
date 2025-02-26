defmodule HabitQuest.Repo.Migrations.AddRecurringIntervalToTasks do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      add :recurring_interval, :integer
      add :recurring_period, :string
    end
  end
end
