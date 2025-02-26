defmodule HabitQuest.Children.Child do
  use Ecto.Schema
  import Ecto.Changeset

  schema "children" do
    field :name, :string
    field :birthday, :date
    field :points, :integer, default: 0
    field :age, :integer, virtual: true

    many_to_many :tasks, HabitQuest.Tasks.Task,
      join_through: HabitQuest.Tasks.ChildTask,
      on_replace: :delete,
      on_delete: :delete_all

    timestamps(type: :utc_datetime)
  end

  @doc false
  def changeset(child, attrs) do
    child
    |> cast(attrs, [:name, :birthday, :points])
    |> validate_required([:name, :birthday])
    |> compute_age()
  end

  defp compute_age(changeset) do
    case get_field(changeset, :birthday) do
      nil -> changeset
      birthday ->
        today = Date.utc_today()
        age = age_from_dates(birthday, today)
        put_change(changeset, :age, age)
    end
  end

  defp age_from_dates(birthday, today) do
    years = today.year - birthday.year
    # Compare month and day to determine if birthday has occurred this year
    had_birthday_this_year = case Date.compare(
      %{today | year: birthday.year},
      birthday
    ) do
      :gt -> true   # Birthday has passed this year
      :eq -> true   # It's their birthday today
      :lt -> false  # Birthday hasn't occurred yet this year
    end
    if had_birthday_this_year, do: years, else: years - 1
  end
end
