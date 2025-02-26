defmodule HabitQuest.Repo.Migrations.AddImageUrlToRewards do
  use Ecto.Migration

  def change do
    alter table(:rewards) do
      add :image_url, :string
    end
  end
end
