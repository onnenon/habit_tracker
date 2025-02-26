defmodule HabitQuest.Repo.Migrations.CreateRewards do
  use Ecto.Migration

  def change do
    create table(:rewards) do
      add :name, :string
      add :description, :text
      add :cost, :integer

      timestamps(type: :utc_datetime)
    end
  end
end
