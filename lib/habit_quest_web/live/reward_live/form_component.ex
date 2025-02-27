defmodule HabitQuestWeb.RewardLive.FormComponent do
  use HabitQuestWeb, :live_component

  alias HabitQuest.Rewards

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
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
            <img src={@reward.image} alt="" class="w-32 h-32 object-cover rounded-lg" />
          </div>

          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:description]} type="text" label="Description" />
          <.input field={@form[:points]} type="number" label="Points" />
          <div class="mt-2" phx-drop-target={@uploads.reward_image.ref}>
            <.live_file_input upload={@uploads.reward_image} class="sr-only" />
            <div class="flex items-center justify-center w-full">
              <label
                for={@uploads.reward_image.ref}
                class="flex flex-col items-center justify-center w-full h-64 border-2 border-zinc-300 border-dashed rounded-lg cursor-pointer bg-zinc-50 hover:bg-zinc-100"
              >
                <div class="flex flex-col items-center justify-center pt-5 pb-6">
                  <svg
                    class="w-8 h-8 mb-4 text-zinc-500"
                    aria-hidden="true"
                    xmlns="http://www.w3.org/2000/svg"
                    fill="none"
                    viewBox="0 0 20 16"
                  >
                    <path
                      stroke="currentColor"
                      stroke-linecap="round"
                      stroke-linejoin="round"
                      stroke-width="2"
                      d="M13 13h3a3 3 0 0 0 0-6h-.025A5.56 5.56 0 0 0 16 6.5 5.5 5.5 0 0 0 5.207 5.021C5.137 5.017 5.071 5 5 5a4 4 0 0 0 0 8h2.167M10 15V6m0 0L8 8m2-2 2 2"
                    />
                  </svg>
                  <p class="mb-2 text-sm text-zinc-500">
                    <span class="font-semibold">Click to upload</span> or drag and drop
                  </p>
                  <p class="text-xs text-zinc-500">PNG, JPG, JPEG, or WebP (MAX. 5MB)</p>
                </div>
              </label>
            </div>

            <div class="mt-4">
              <%= for entry <- @uploads.reward_image.entries do %>
                <div class="mb-4">
                  <div class="flex items-center gap-4">
                    <div class="flex-1">
                      <div class="text-sm text-zinc-600 mb-1">{entry.client_name}</div>
                      <div class="w-full bg-zinc-200 rounded-full h-2.5">
                        <div
                          class="bg-zinc-600 h-2.5 rounded-full transition-all"
                          style={"width: #{entry.progress}%"}
                        >
                        </div>
                      </div>
                    </div>
                    <button
                      type="button"
                      phx-click="cancel-upload"
                      phx-value-ref={entry.ref}
                      phx-target={@myself}
                      class="text-zinc-500 hover:text-zinc-700"
                    >
                      <.icon name="hero-x-mark" class="h-5 w-5" />
                    </button>
                  </div>

                  <%= for err <- upload_errors(@uploads.reward_image, entry) do %>
                    <div class="mt-1 text-sm text-red-600">
                      {error_to_string(err)}
                    </div>
                  <% end %>
                </div>
              <% end %>

              <%= for err <- upload_errors(@uploads.reward_image) do %>
                <div class="mt-1 text-sm text-red-600">
                  {error_to_string(err)}
                </div>
              <% end %>
            </div>
          </div>

          <div class="space-y-2">
            <label class="text-sm font-semibold leading-6 text-zinc-800">Available To</label>
            <%= for {name, id} <- @children_options do %>
              <label class="flex items-center gap-2">
                <input
                  type="checkbox"
                  name="reward[child_ids][]"
                  value={id}
                  checked={id in (@form[:child_ids].value || [])}
                  class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
                />
                <span class="text-sm text-zinc-600">{name}</span>
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
  def update(%{reward: reward, children: children} = assigns, socket) do
    child_ids = Enum.map(reward.children, & &1.id)

    changeset =
      reward
      |> Rewards.change_reward()
      |> Ecto.Changeset.put_change(:child_ids, child_ids)

    children_options = for child <- children, do: {child.name, child.id}

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:children_options, children_options)
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
    child_ids = ensure_integer_ids(reward_params["child_ids"] || [])
    reward_params = Map.put(reward_params, "child_ids", child_ids)

    changeset =
      socket.assigns.reward
      |> Rewards.change_reward(reward_params)
      |> Ecto.Changeset.put_change(:child_ids, child_ids)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :reward_image, ref)}
  end

  @impl true
  def handle_event("save", %{"reward" => reward_params}, socket) do
    save_reward(socket, socket.assigns.action, reward_params)
  end

  defp save_reward(socket, action, reward_params) do
    child_ids = ensure_integer_ids(reward_params["child_ids"] || [])

    # Handle file upload
    reward_params =
      case uploaded_entries(socket, :reward_image) do
        {[_ | _], []} ->
          uploaded_path = Path.join([:code.priv_dir(:habit_quest), "static", "uploads"])
          File.mkdir_p!(uploaded_path)

          {completed, []} = uploaded_entries(socket, :reward_image)

          urls =
            for entry <- completed do
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

  # Add helper function for converting error atoms to user-friendly strings
  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:too_many_files), do: "You can only upload one image"
  defp error_to_string(:not_accepted), do: "You can only upload images (.jpg, .jpeg, .png, .webp)"
  defp error_to_string(_), do: "Invalid file"
end
