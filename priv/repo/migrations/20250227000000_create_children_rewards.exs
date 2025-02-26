defmodule HabitQuest.Repo.Migrations.CreateChildrenRewards do
  use Ecto.Migration

  def change do
    create table(:children_rewards) do
      add :child_id, references(:children, on_delete: :delete_all)
      add :reward_id, references(:rewards, on_delete: :delete_all)

      timestamps(type: :utc_datetime)
    end

    create index(:children_rewards, [:child_id])
    create index(:children_rewards, [:reward_id])
    create unique_index(:children_rewards, [:child_id, :reward_id])
  end
end
