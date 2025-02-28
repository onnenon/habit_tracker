defmodule HabitQuestWeb.RedeemedRewardLive.Index do
  use HabitQuestWeb, :live_view
  alias HabitQuest.Rewards
  alias HabitQuest.Children

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(:show_fulfilled, false)
     |> assign(:child, nil)
     |> assign(:redeemed_rewards, [])}
  end

  @impl true
  def handle_params(%{"id" => child_id}, _, socket) do
    child = Children.get_child!(child_id)
    redeemed_rewards = list_fulfilled_rewards(child_id)

    {:noreply,
     socket
     |> assign(:child, child)
     |> assign(:page_title, "#{child.name}'s Fulfilled Rewards")
     |> assign(:redeemed_rewards, redeemed_rewards)}
  end

  def handle_params(_, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, "All Redeemed Rewards")
     |> assign(:redeemed_rewards, list_redeemed_rewards(socket.assigns.show_fulfilled))}
  end

  @impl true
  def handle_event("toggle_fulfilled", _params, socket) do
    show_fulfilled = !socket.assigns.show_fulfilled

    {:noreply,
     socket
     |> assign(:show_fulfilled, show_fulfilled)
     |> assign(:redeemed_rewards, list_redeemed_rewards(show_fulfilled))}
  end

  # Handle marking rewards as fulfilled (parent view only)
  @impl true
  def handle_event("mark_fulfilled", %{"id" => id}, socket) do
    redeemed_reward = Rewards.get_redeemed_reward!(id)

    {:ok, _updated_reward} =
      Rewards.update_redeemed_reward(redeemed_reward, %{
        fulfilled: true,
        fulfilled_at: DateTime.utc_now()
      })

    {:noreply,
     socket
     |> put_flash(:info, "Reward marked as fulfilled")
     |> assign(:redeemed_rewards, list_redeemed_rewards(socket.assigns.show_fulfilled))}
  end

  # For child-specific view - show only fulfilled rewards
  defp list_fulfilled_rewards(child_id) when is_binary(child_id) do
    child_id = String.to_integer(child_id)

    Rewards.list_redeemed_rewards(nil)
    |> Enum.filter(&(&1.fulfilled && &1.child_id == child_id))
    |> Enum.sort_by(& &1.fulfilled_at, {:desc, DateTime})
  end

  # For parent view - show all or only unfulfilled based on toggle
  defp list_redeemed_rewards(show_fulfilled) do
    case show_fulfilled do
      true ->
        Rewards.list_redeemed_rewards(nil)

      false ->
        Rewards.list_redeemed_rewards(false)
    end
    |> Enum.sort_by(&{&1.fulfilled, &1.redeemed_at}, :asc)
  end
end
