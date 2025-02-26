defmodule HabitQuest.Repo.Migrations.CreateTasks do
  use Ecto.Migration

  def change do
    create table(:tasks) do
      add :title, :string
      add :description, :text
      add :points, :integer
      add :recurring, :boolean, default: false, null: false
      add :child_id, references(:children, on_delete: :nothing)

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:child_id])
  end
end
