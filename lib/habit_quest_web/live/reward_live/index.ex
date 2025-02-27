defmodule HabitQuestWeb.RewardLive.Index do
  use HabitQuestWeb, :live_view

  alias HabitQuest.Rewards
  alias HabitQuest.Rewards.Reward
  alias HabitQuest.Children

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      {:ok,
       socket
       |> assign(:uploaded_files, [])
       |> stream(:rewards, Rewards.list_rewards())
       |> allow_upload(:reward_image,
         accept: ~w(.jpg .jpeg .png),
         max_entries: 1,
         max_file_size: 5_000_000,
         auto_upload: true,
         progress: &handle_progress/3
       )}
    else
      {:ok, stream(socket, :rewards, Rewards.list_rewards())}
    end
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
  def handle_event("delete", %{"id" => id}, socket) do
    reward = Rewards.get_reward!(id)
    {:ok, _} = Rewards.delete_reward(reward)

    # Refresh the entire rewards list to ensure we have the latest state
    rewards = Rewards.list_rewards()
    {:noreply, stream(socket, :rewards, rewards, reset: true)}
  end

  defp handle_progress(:reward_image, entry, socket) do
    if entry.done? do
      uploaded_path = Path.join([:code.priv_dir(:habit_quest), "static", "uploads"])
      File.mkdir_p!(uploaded_path)

      consume_uploaded_entry(socket, entry, fn %{path: path} ->
        dest = Path.join(uploaded_path, filename(entry))
        File.cp!(path, dest)
        {:ok, "/uploads/#{filename(entry)}"}
      end)

      {:noreply, update(socket, :uploaded_files, &(&1 ++ [entry]))}
    else
      {:noreply, socket}
    end
  end

  defp filename(entry) do
    [ext | _] = MIME.extensions(entry.client_type)
    "#{entry.uuid}.#{ext}"
  end
end
