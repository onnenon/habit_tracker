defmodule HabitQuest.Tasks.Task do
  use Ecto.Schema
  import Ecto.Changeset

  schema "tasks" do
    field :description, :string
    field :title, :string
    field :points, :integer
    field :task_type, :string, default: "one_off"
    field :completions_required, :integer
    field :current_completions, :integer, default: 0
    field :schedule_days, {:array, :string}
    field :child_ids, {:array, :integer}, virtual: true

    many_to_many :children, HabitQuest.Children.Child,
      join_through: HabitQuest.Tasks.ChildTask,
      on_replace: :delete,
      on_delete: :delete_all

    has_many :task_completions, HabitQuest.Tasks.TaskCompletion
    has_many :one_off_task_completions, HabitQuest.Tasks.OneOffTaskCompletion

    timestamps(type: :utc_datetime)
  end

  @task_types ~w(one_off punch_card weekly)
  @days_of_week ~w(monday tuesday wednesday thursday friday saturday sunday)

  def task_type_options do
    [
      {"One-off Task", "one_off"},
      {"Punch Card Task", "punch_card"},
      {"Weekly Schedule", "weekly"}
    ]
  end

  def days_of_week_options do
    Enum.map(@days_of_week, &{String.capitalize(&1), &1})
  end

  @doc false
  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :title,
      :description,
      :points,
      :task_type,
      :completions_required,
      :current_completions,
      :schedule_days,
      :child_ids
    ])
    |> validate_required([:title, :description, :points, :task_type])
    |> validate_inclusion(:task_type, @task_types)
    |> validate_task_type_fields()
  end

  defp validate_task_type_fields(changeset) do
    case get_field(changeset, :task_type) do
      "punch_card" ->
        changeset
        |> validate_required([:completions_required])
        |> validate_number(:completions_required, greater_than: 0)
        |> validate_number(:current_completions, greater_than_or_equal_to: 0)

      "weekly" ->
        changeset
        |> validate_required([:schedule_days])
        |> validate_schedule_days()

      _ ->
        changeset
    end
  end

  defp validate_schedule_days(changeset) do
    case get_field(changeset, :schedule_days) do
      nil ->
        changeset

      days ->
        if Enum.all?(days, &(&1 in @days_of_week)) do
          changeset
        else
          add_error(changeset, :schedule_days, "invalid day of week")
        end
    end
  end
end
