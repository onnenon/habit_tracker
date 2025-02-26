defmodule HabitQuest.Repo.Migrations.AddTaskTypeAndPunchCardFields do
  use Ecto.Migration

  def change do
    alter table(:tasks) do
      # Add task_type field
      add :task_type, :string, null: false, default: "one_off"

      # Add punch card related fields
      add :completions_required, :integer  # Number of completions needed for reward
      add :current_completions, :integer, default: 0  # Current number of completions

      # Add weekly schedule fields
      add :schedule_days, {:array, :string}  # Days of the week for weekly recurring tasks
    end
  end
end
