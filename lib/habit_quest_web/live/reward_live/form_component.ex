defmodule HabitQuestWeb.RewardLive.FormComponent do
  use HabitQuestWeb, :live_component

  alias HabitQuest.Rewards

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage reward records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="reward-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        multipart
      >
        <div class="space-y-8">
          <div :if={@reward.image} class="mt-2">
            <img src={@reward.image} alt="" class="w-32 h-32 object-cover rounded-lg"/>
          </div>

          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:description]} type="text" label="Description" />
          <.input field={@form[:points]} type="number" label="Points" />
          <div class="mt-2" phx-drop-target={@uploads.reward_image.ref}>
            <.live_file_input upload={@uploads.reward_image} class="sr-only" />
            <div class="flex items-center justify-center w-full">
              <label for={@uploads.reward_image.ref} class="flex flex-col items-center justify-center w-full h-64 border-2 border-zinc-300 border-dashed rounded-lg cursor-pointer bg-zinc-50 hover:bg-zinc-100">
                <div class="flex flex-col items-center justify-center pt-5 pb-6">
                  <svg class="w-8 h-8 mb-4 text-zinc-500" aria-hidden="true" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 20 16">
                    <path stroke="currentColor" stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 13h3a3 3 0 0 0 0-6h-.025A5.56 5.56 0 0 0 16 6.5 5.5 5.5 0 0 0 5.207 5.021C5.137 5.017 5.071 5 5 5a4 4 0 0 0 0 8h2.167M10 15V6m0 0L8 8m2-2 2 2"/>
                  </svg>
                  <p class="mb-2 text-sm text-zinc-500"><span class="font-semibold">Click to upload</span> or drag and drop</p>
                  <p class="text-xs text-zinc-500">PNG, JPG, JPEG, or WebP (MAX. 5MB)</p>
                </div>
              </label>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-semibold leading-6 text-zinc-800">Available To</label>
            <%= for child <- @children do %>
              <label class="flex items-center gap-2">
                <input
                  type="checkbox"
                  name="reward[child_ids][]"
                  value={child.id}
                  checked={child.id in (@reward.child_ids || [])}
                  class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
                />
                <span class="text-sm text-zinc-600"><%= child.name %></span>
              </label>
            <% end %>
          </div>
        </div>
        <:actions>
          <.button phx-disable-with="Saving...">Save Reward</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{reward: reward} = assigns, socket) do
    reward = Map.put(reward, :child_ids, Enum.map(reward.children, & &1.id))
    changeset = Rewards.change_reward(reward)

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:uploaded_files, [])
      |> assign_form(changeset)
      |> allow_upload(:reward_image,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 5_000_000
      )
    }
  end

  @impl true
  def handle_event("validate", %{"reward" => reward_params}, socket) do
    changeset =
      socket.assigns.reward
      |> Rewards.change_reward(reward_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"reward" => reward_params}, socket) do
    save_reward(socket, socket.assigns.action, reward_params)
  end

  defp save_reward(socket, action, reward_params) do
    child_ids =
      (reward_params["child_ids"] || [])
      |> Enum.reject(&(&1 == ""))
      |> Enum.map(&String.to_integer/1)

    # Handle file upload
    reward_params = case uploaded_entries(socket, :reward_image) do
      {[_|_], []} ->
        uploaded_path = Path.join([:code.priv_dir(:habit_quest), "static", "uploads"])
        File.mkdir_p!(uploaded_path)

        {completed, []} = uploaded_entries(socket, :reward_image)
        urls = for entry <- completed do
          consume_uploaded_entry(socket, entry, fn %{path: path} ->
            ext = Path.extname(entry.client_name)
            filename = "#{entry.uuid}#{ext}"
            dest = Path.join(uploaded_path, filename)
            File.cp!(path, dest)
            {:ok, "/uploads/#{filename}"}
          end)
        end
        Map.put(reward_params, "image", List.first(urls))
      {[], []} ->
        reward_params
    end

    case action do
      :edit ->
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

      :new ->
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
  end

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
