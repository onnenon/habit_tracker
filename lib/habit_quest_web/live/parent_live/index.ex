defmodule HabitQuestWeb.ParentLive.Index do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Children
  alias HabitQuest.Children.Child

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket,
      children: list_children(),
      page_title: "Parent Management"
    )}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "Add Child")
    |> assign(:child, %Child{})
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Child")
    |> assign(:child, Children.get_child!(id))
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Parent Management")
    |> assign(:child, nil)
  end

  @impl true
  def handle_info({HabitQuestWeb.ParentLive.FormComponent, {:saved, _child}}, socket) do
    {:noreply, assign(socket, :children, list_children())}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    child = Children.get_child!(id)
    {:ok, _} = Children.delete_child(child)

    {:noreply, assign(socket, :children, list_children())}
  end

  defp list_children do
    Children.list_children()
  end
end
