defmodule HabitQuestWeb.ChildLive.FormComponent do
  use HabitQuestWeb, :live_component

  alias HabitQuest.Children

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        {@title}
        <:subtitle>Use this form to manage child records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="child-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
        multipart
      >
        <div class="space-y-8">
          <div :if={@form.data.avatar} class="mt-2">
            <img src={@form.data.avatar} alt="" class="w-20 h-20 rounded-full object-cover" />
          </div>

          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:birthday]} type="date" label="Birthday" />
          <.input field={@form[:points]} type="number" label="Points" value="0" />

          <div class="mt-2" phx-drop-target={@uploads.avatar.ref}>
            <.live_file_input upload={@uploads.avatar} class="sr-only" />
            <div class="flex items-center justify-center w-full">
              <label
                for={@uploads.avatar.ref}
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
              <%= for entry <- @uploads.avatar.entries do %>
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

                  <%= for err <- upload_errors(@uploads.avatar, entry) do %>
                    <div class="mt-1 text-sm text-red-600">
                      {error_to_string(err)}
                    </div>
                  <% end %>
                </div>
              <% end %>

              <%= for err <- upload_errors(@uploads.avatar) do %>
                <div class="mt-1 text-sm text-red-600">
                  {error_to_string(err)}
                </div>
              <% end %>
            </div>
          </div>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Child</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{child: child} = assigns, socket) do
    changeset = Children.change_child(child)

    {
      :ok,
      socket
      |> assign(assigns)
      |> assign(:uploaded_files, [])
      |> assign_form(changeset)
      |> allow_upload(:avatar,
        accept: ~w(.jpg .jpeg .png .webp),
        max_entries: 1,
        max_file_size: 5_000_000
      )
    }
  end

  @impl true
  def handle_event("validate", %{"child" => child_params}, socket) do
    changeset =
      socket.assigns.child
      |> Children.change_child(child_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :avatar, ref)}
  end

  def handle_event("save", %{"child" => child_params}, socket) do
    save_child(socket, socket.assigns.action, child_params)
  end

  defp save_child(socket, action, child_params) do
    # Handle file upload
    child_params =
      case uploaded_entries(socket, :avatar) do
        {[_ | _], []} ->
          uploaded_path = Path.join([:code.priv_dir(:habit_quest), "static", "uploads"])
          File.mkdir_p!(uploaded_path)

          {completed, []} = uploaded_entries(socket, :avatar)

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

          Map.put(child_params, "avatar", List.first(urls))

        {[], []} ->
          child_params
      end

    case action do
      :edit ->
        case Children.update_child(socket.assigns.child, child_params) do
          {:ok, child} ->
            notify_parent({:saved, child})

            {:noreply,
             socket
             |> put_flash(:info, "Child updated successfully")
             |> push_patch(to: socket.assigns.patch)}

          {:error, %Ecto.Changeset{} = changeset} ->
            {:noreply, assign_form(socket, changeset)}
        end

      :new ->
        case Children.create_child(child_params) do
          {:ok, child} ->
            notify_parent({:saved, child})

            {:noreply,
             socket
             |> put_flash(:info, "Child created successfully")
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

  defp error_to_string(:too_large), do: "File is too large (max 5MB)"
  defp error_to_string(:too_many_files), do: "You can only upload one image"
  defp error_to_string(:not_accepted), do: "You can only upload images (.jpg, .jpeg, .png, .webp)"
  defp error_to_string(_), do: "Invalid file"
end
