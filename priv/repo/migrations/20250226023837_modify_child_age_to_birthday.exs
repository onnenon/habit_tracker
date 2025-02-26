defmodule HabitQuest.Repo.Migrations.ModifyChildAgeToBirthday do
  use Ecto.Migration

  def change do
    # Create a temporary table with the new structure
    create table(:children_new) do
      add :name, :string
      add :points, :integer
      add :birthday, :date, null: false
      timestamps(type: :utc_datetime)
    end

    # Copy data to the new table, converting age to birthday
    execute """
    INSERT INTO children_new (name, points, birthday, inserted_at, updated_at)
    SELECT name, points, date('now', '-' || age || ' years', 'start of year'), inserted_at, updated_at
    FROM children
    """

    # Drop the old table
    drop table(:children)

    # Rename the new table using raw SQL since SQLite requires it
    execute "ALTER TABLE children_new RENAME TO children"
  end
end
