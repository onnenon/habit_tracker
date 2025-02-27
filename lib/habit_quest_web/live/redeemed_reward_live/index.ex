defmodule HabitQuestWeb.RedeemedRewardLive.Index do
  use HabitQuestWeb, :live_view
  alias HabitQuest.Rewards

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:show_fulfilled, false)
     |> assign(:redeemed_rewards, list_redeemed_rewards(false))}
  end

  @impl true
  def handle_event("toggle_fulfilled", _params, socket) do
    show_fulfilled = !socket.assigns.show_fulfilled
    {:noreply,
     socket
     |> assign(:show_fulfilled, show_fulfilled)
     |> assign(:redeemed_rewards, list_redeemed_rewards(if show_fulfilled, do: nil, else: false))}
  end

  @impl true
  def handle_event("mark_fulfilled", %{"id" => id}, socket) do
    redeemed_reward = Rewards.get_redeemed_reward!(id)
    {:ok, updated_reward} = Rewards.update_redeemed_reward(redeemed_reward, %{
      fulfilled: true,
      fulfilled_at: DateTime.utc_now()
    })

    {:noreply,
     socket
     |> put_flash(:info, "Reward marked as fulfilled")
     |> assign(:redeemed_rewards, list_redeemed_rewards(if socket.assigns.show_fulfilled, do: nil, else: false))}
  end

  defp list_redeemed_rewards(fulfilled) do
    Rewards.list_redeemed_rewards(fulfilled)
  end
end
