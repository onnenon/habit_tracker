defmodule HabitQuestWeb.PageLive.Index do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Children
  alias HabitQuest.Children.Child

  @impl true
  def mount(_params, _session, socket) do
    children = Children.list_children()
    |> Enum.map(fn child ->
      Child.changeset(child, %{})
      |> Ecto.Changeset.apply_changes()
    end)

    {:ok, stream(socket, :children, children)}
  end
end
