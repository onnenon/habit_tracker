defmodule HabitQuestWeb.PageLive.Index do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Children

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :children, Children.list_children())}
  end
end
