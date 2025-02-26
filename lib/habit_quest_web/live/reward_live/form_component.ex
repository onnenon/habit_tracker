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

        <div class="space-y-3">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">
            Available to Children
          </label>

          <%= for {name, id} <- @children_options do %>
            <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
              <input
                type="checkbox"
                name="reward[child_ids][]"
                value={id}
                checked={id in (@form[:child_ids].value || [])}
                class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
              />
              <%= name %>
            </label>
          <% end %>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Reward</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{reward: reward, children: children} = assigns, socket) do
    child_ids = Enum.map(reward.children, & &1.id)

    changeset = Rewards.change_reward(reward)
    |> Ecto.Changeset.put_change(:child_ids, child_ids)

    children_options = for child <- children, do: {child.name, child.id}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:children_options, children_options)
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
    child_ids = ensure_integer_ids(reward_params["child_ids"] || [])
    case Rewards.update_reward(socket.assigns.reward, reward_params, child_ids) do
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
    child_ids = ensure_integer_ids(reward_params["child_ids"] || [])
    case Rewards.create_reward(reward_params, child_ids) do
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

  defp ensure_integer_ids(ids) when is_list(ids) do
    Enum.map(ids, &safe_to_integer/1)
    |> Enum.filter(&(&1 != nil))
  end
  defp ensure_integer_ids(_), do: []

  defp safe_to_integer(val) when is_integer(val), do: val
  defp safe_to_integer(val) when is_binary(val) do
    case Integer.parse(val) do
      {int, ""} -> int
      _ -> nil
    end
  end
  defp safe_to_integer(_), do: nil
end
