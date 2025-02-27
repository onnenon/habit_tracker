defmodule HabitQuestWeb.RewardLive.Index do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Rewards
  alias HabitQuest.Rewards.Reward
  alias HabitQuest.Children

  @impl true
  def mount(_params, _session, socket) do
    {:ok, stream(socket, :rewards, Rewards.list_rewards())}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Reward")
    |> assign(:reward, Rewards.get_reward!(id))
    |> assign(:children, Children.list_children())
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Reward")
    |> assign(:reward, %Reward{children: []})
    |> assign(:children, Children.list_children())
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Rewards")
    |> assign(:reward, nil)
  end

  @impl true
  def handle_info({HabitQuestWeb.RewardLive.FormComponent, {:saved, _reward}}, socket) do
    # Refresh the entire rewards list to ensure we have the latest state
    rewards = Rewards.list_rewards()
    {:noreply, stream(socket, :rewards, rewards, reset: true)}
  end

  @impl true
  def handle_event("parse_url", params, socket) do
    if socket.assigns.live_action in [:new, :edit] do
      send_update(HabitQuestWeb.RewardLive.FormComponent,
        id: socket.assigns.reward.id || :new,
        event: "parse_url",
        params: params
      )
    end
    {:noreply, socket}
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    reward = Rewards.get_reward!(id)
    {:ok, _} = Rewards.delete_reward(reward)

    # Refresh the entire rewards list to ensure we have the latest state
    rewards = Rewards.list_rewards()
    {:noreply, stream(socket, :rewards, rewards, reset: true)}
  end
end
