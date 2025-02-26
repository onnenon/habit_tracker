defmodule HabitQuestWeb.TaskLive.FormComponent do
  use HabitQuestWeb, :live_component

  alias HabitQuest.Tasks
  alias HabitQuest.Tasks.Task

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Create a new habit for your children to track</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="task-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <.input field={@form[:title]} type="text" label="Title" />
        <.input field={@form[:description]} type="textarea" label="Description" />
        <.input field={@form[:points]} type="number" label="Points" />

        <div class="space-y-4">
          <.input
            field={@form[:recurring]}
            type="checkbox"
            label="Recurring habit?"
          />

          <%= if @show_recurring_fields do %>
            <div class="mt-4 flex gap-4 items-end">
              <div class="flex-1">
                <.input
                  field={@form[:recurring_interval]}
                  type="number"
                  min="1"
                  label="Repeat every"
                />
              </div>
              <div class="flex-1">
                <.input
                  field={@form[:recurring_period]}
                  type="select"
                  options={Task.recurring_period_options()}
                  label="Period"
                />
              </div>
            </div>
          <% end %>
        </div>

        <div class="mt-6">
          <label class="block text-sm font-medium leading-6 text-zinc-800">
            Assign to children
          </label>
          <div class="mt-2 grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-4">
            <%= for {name, id} <- @children_options do %>
              <label class="relative flex items-start">
                <div class="flex h-6 items-center">
                  <input
                    type="checkbox"
                    name="task[child_ids][]"
                    value={id}
                    checked={id in (@form[:child_ids].value || [])}
                    class="h-4 w-4 rounded border-zinc-300 text-zinc-900 focus:ring-0"
                  />
                </div>
                <div class="ml-3 text-sm leading-6">
                  <span class="font-medium text-zinc-900"><%= name %></span>
                </div>
              </label>
            <% end %>
          </div>
          <%= if @children_options == [] do %>
            <p class="mt-1 text-sm text-zinc-600">No children available. Add children first to assign habits.</p>
          <% end %>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Habit</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{task: task, children: children} = assigns, socket) do
    changeset = Tasks.change_task(task)
    children_options = for child <- children, do: {child.name, child.id}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:children_options, children_options)
     |> assign(:show_recurring_fields, task.recurring || false)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    show_recurring = case task_params["recurring"] do
      "true" -> true
      true -> true
      _ -> false
    end

    # Ensure child_ids are properly handled during validation
    task_params = case task_params["child_ids"] do
      nil -> task_params
      ids when is_list(ids) ->
        %{task_params | "child_ids" => ensure_integer_ids(ids)}
      _ -> task_params
    end

    changeset =
      socket.assigns.task
      |> Tasks.change_task(task_params)
      |> Map.put(:action, :validate)

    {:noreply,
     socket
     |> assign(:show_recurring_fields, show_recurring)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("save", %{"task" => task_params}, socket) do
    IO.inspect(task_params, label: "Task params")  # Debug line
    save_task(socket, socket.assigns.action, task_params)
  end

  defp save_task(socket, :edit, task_params) do
    IO.inspect(socket.assigns.task, label: "Current task")  # Debug line
    child_ids = ensure_integer_ids(task_params["child_ids"] || [])
    IO.inspect(child_ids, label: "Child IDs")  # Debug line

    case Tasks.update_task(socket.assigns.task, task_params, child_ids) do
      {:ok, task} ->
        notify_parent({:saved, task})

        {:noreply,
         socket
         |> put_flash(:info, "Habit updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
        IO.inspect(changeset, label: "Error changeset")  # Debug line
        {:noreply, assign_form(socket, changeset)}
    end
  end

  defp save_task(socket, :new, task_params) do
    child_ids = ensure_integer_ids(task_params["child_ids"] || [])
    case Tasks.create_task(task_params, child_ids) do
      {:ok, task} ->
        notify_parent({:saved, task})

        {:noreply,
         socket
         |> put_flash(:info, "Habit created successfully")
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
