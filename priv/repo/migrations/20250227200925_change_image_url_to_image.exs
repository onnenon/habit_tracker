defmodule HabitQuest.Repo.Migrations.RenameRewardImageUrl do
  use Ecto.Migration

  def change do
    alter table(:rewards) do
      remove :image_url
      add :image, :string
    end
  end
end
