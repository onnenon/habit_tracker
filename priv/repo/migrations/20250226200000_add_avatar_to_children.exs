defmodule HabitQuest.Repo.Migrations.AddAvatarToChildren do
  use Ecto.Migration

  def change do
    alter table(:children) do
      add :avatar, :string
    end
  end
end
