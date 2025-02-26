defmodule HabitQuest.Repo do
  use Ecto.Repo,
    otp_app: :habit_quest,
    adapter: Ecto.Adapters.SQLite3
end
