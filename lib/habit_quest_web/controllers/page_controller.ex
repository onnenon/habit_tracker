defmodule HabitQuestWeb.PageController do
  use HabitQuestWeb, :controller

  alias HabitQuest.Children

  def home(conn, _params) do
    # Fetch children for the dashboard
    children = Children.list_children()

    # The home page is often custom made,
    # so skip the default app layout.
    render(conn, :home, layout: false, children: children)
  end
end
