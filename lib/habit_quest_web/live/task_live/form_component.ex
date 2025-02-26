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
        <.input field={@form[:task_type]} type="select" label="Task Type" options={Task.task_type_options()} />

        <div :if={@form[:task_type].value == "punch_card"}>
          <.input
            field={@form[:completions_required]}
            type="number"
            label="Completions Required for Reward"
            min="1"
          />
        </div>

        <div :if={@form[:task_type].value == "weekly"} class="space-y-3">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">
            Schedule Days
          </label>

          <%= for {name, value} <- Task.days_of_week_options() do %>
            <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
              <input
                type="checkbox"
                name="task[schedule_days][]"
                value={value}
                checked={value in (@form[:schedule_days].value || [])}
                class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
              />
              <%= name %>
            </label>
          <% end %>
        </div>

        <div class="space-y-3">
          <label class="block text-sm font-semibold leading-6 text-zinc-800">
            Assign to Children
          </label>

          <%= for {name, id} <- @children_options do %>
            <label class="flex items-center gap-4 text-sm leading-6 text-zinc-600">
              <input
                type="checkbox"
                name="task[child_ids][]"
                value={id}
                checked={id in (@form[:child_ids].value || [])}
                class="rounded border-zinc-300 text-zinc-900 focus:ring-0"
              />
              <%= name %>
            </label>
          <% end %>
        </div>

        <:actions>
          <.button phx-disable-with="Saving...">Save Task</.button>
        </:actions>
      </.simple_form>
    </div>
    """
  end

  @impl true
  def update(%{task: task, children: children} = assigns, socket) do
    child_ids = Enum.map(task.children, & &1.id)

    changeset = Tasks.change_task(task)
    |> Ecto.Changeset.put_change(:child_ids, child_ids)

    children_options = for child <- children, do: {child.name, child.id}

    {:ok,
     socket
     |> assign(assigns)
     |> assign(:children_options, children_options)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"task" => task_params}, socket) do
    changeset =
      socket.assigns.task
      |> Tasks.change_task(task_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  @impl true
  def handle_event("save", %{"task" => task_params}, socket) do
    save_task(socket, socket.assigns.action, task_params)
  end

  defp save_task(socket, :edit, task_params) do
    child_ids = ensure_integer_ids(task_params["child_ids"] || [])
    case Tasks.update_task(socket.assigns.task, task_params, child_ids) do
      {:ok, task} ->
        notify_parent({:saved, task})

        {:noreply,
         socket
         |> put_flash(:info, "Task updated successfully")
         |> push_patch(to: socket.assigns.patch)}

      {:error, %Ecto.Changeset{} = changeset} ->
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
         |> put_flash(:info, "Task created successfully")
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
