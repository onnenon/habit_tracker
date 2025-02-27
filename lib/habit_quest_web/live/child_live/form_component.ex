defmodule HabitQuestWeb.ChildLive.FormComponent do
  use HabitQuestWeb, :live_component

  alias HabitQuest.Children

  @impl true
  def render(assigns) do
    ~H"""
    <div>
      <.header>
        <%= @title %>
        <:subtitle>Use this form to manage child records in your database.</:subtitle>
      </.header>

      <.simple_form
        for={@form}
        id="child-form"
        phx-target={@myself}
        phx-change="validate"
        phx-submit="save"
      >
        <div class="space-y-8">
          <div :if={@form.data.avatar} class="mt-2">
            <img src={@form.data.avatar} alt="" class="w-20 h-20 rounded-full object-cover"/>
          </div>

          <.input field={@form[:name]} type="text" label="Name" />
          <.input field={@form[:birthday]} type="date" label="Birthday" />
          <.input field={@form[:points]} type="number" label="Points" value="0" />
          <.input
            field={@form[:avatar]}
            type="url"
            label="Avatar URL"
            placeholder="https://example.com/avatar.jpg"
          />
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

    {:ok,
     socket
     |> assign(assigns)
     |> assign_form(changeset)}
  end

  @impl true
  def handle_event("validate", %{"child" => child_params}, socket) do
    changeset =
      socket.assigns.child
      |> Children.change_child(child_params)
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("save", %{"child" => child_params}, socket) do
    save_child(socket, socket.assigns.action, child_params)
  end

  defp save_child(socket, :edit, child_params) do
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
  end

  defp save_child(socket, :new, child_params) do
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

  defp assign_form(socket, %Ecto.Changeset{} = changeset) do
    assign(socket, :form, to_form(changeset))
  end

  defp notify_parent(msg), do: send(self(), {__MODULE__, msg})
end
