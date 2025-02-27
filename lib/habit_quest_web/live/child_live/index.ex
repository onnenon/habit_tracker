defmodule HabitQuestWeb.ChildLive.Index do
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

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Children")
    |> assign(:child, nil)
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Child")
    |> assign(:child, %Child{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    child = Children.get_child!(id)
    |> Child.changeset(%{})
    |> Ecto.Changeset.apply_changes()

    socket
    |> assign(:page_title, "Edit Child")
    |> assign(:child, child)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    child = Children.get_child!(id)
    {:ok, _} = Children.delete_child(child)

    # Refresh the entire children list after deletion
    children = Children.list_children()
    |> Enum.map(fn child ->
      Child.changeset(child, %{})
      |> Ecto.Changeset.apply_changes()
    end)

    {:noreply, stream(socket, :children, children, reset: true)}
  end

  @impl true
  def handle_info({HabitQuestWeb.ChildLive.FormComponent, {:saved, _child}}, socket) do
    # Refresh the entire children list to ensure we have all children
    children = Children.list_children()
    |> Enum.map(fn child ->
      Child.changeset(child, %{})
      |> Ecto.Changeset.apply_changes()
    end)

    {:noreply, stream(socket, :children, children, reset: true)}
  end
end
