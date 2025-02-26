defmodule HabitQuest.Repo.Migrations.CreateChildren do
  use Ecto.Migration

  def change do
    create table(:children) do
      add :name, :string
      add :birthday, :date
      add :points, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
