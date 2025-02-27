defmodule HabitQuest.Repo.Migrations.CreateRedeemedRewards do
  use Ecto.Migration

  def change do
    create table(:redeemed_rewards) do
      add :child_id, references(:children, on_delete: :delete_all), null: false
      add :reward_id, references(:rewards, on_delete: :delete_all), null: false
      add :fulfilled, :boolean, default: false, null: false
      add :redeemed_at, :utc_datetime, null: false
      add :fulfilled_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create index(:redeemed_rewards, [:child_id])
    create index(:redeemed_rewards, [:reward_id])
    create index(:redeemed_rewards, [:redeemed_at])
  end
end
