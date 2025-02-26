defmodule HabitQuestWeb.RewardLive.FormComponent do
  use HabitQuestWeb, :live_component

  alias HabitQuest.Rewards

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage rewards.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="reward-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:name]} type="text" label="Name" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:cost]} type="number" label="Cost (points)" min="0" />

        <:actions>
          <.button phx-disable-with="Saving...">Save Reward</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{reward: reward} = assigns, socket) do
    changeset = Rewards.change_reward(reward)

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"reward" => reward_params}, socket) do
    changeset =
      socket.assigns.reward
      |> Rewards.change_reward(reward_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"reward" => reward_params}, socket) do
    save_reward(socket, socket.assigns.action, reward_params)
  end

  defp save_reward(socket, :edit, reward_params) do
    case Rewards.update_reward(socket.assigns.reward, reward_params) do
      {:ok, reward} ->
        notify_parent({:saved, reward})

        {:noreply,
         socket
         |> put_flash(:info, "Reward updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_reward(socket, :new, reward_params) do
    case Rewards.create_reward(reward_params) do
      {:ok, reward} ->
        notify_parent({:saved, reward})

        {:noreply,
         socket
         |> put_flash(:info, "Reward created successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
