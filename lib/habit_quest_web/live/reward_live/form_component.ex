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
      >
        <div class="space-y-6">
          <div class="space-y-4">
            <.input field={@form[:product_url]} type="url" label="Product URL" phx-blur="parse_url" />
            <.input field={@form[:name]} type="text" label="Name" />
            <.input field={@form[:description]} type="textarea" label="Description" />
            <.input field={@form[:cost]} type="number" label="Cost" />
            <.input field={@form[:image_url]} type="url" label="Image URL" />
          </div>

          <label class="text-sm font-semibold leading-6 text-zinc-800">
            Available To
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

  def handle_event("parse_url", %{"reward" => %{"product_url" => url}} = params, socket) when byte_size(url) > 0 do
    parsed_data = parse_product_url(url)

    changeset =
      socket.assigns.reward
      |> Rewards.change_reward(Map.merge(params["reward"], parsed_data))
      |> Map.put(:action, :validate)

    {:noreply, assign_form(socket, changeset)}
  end

  def handle_event("parse_url", _, socket), do: {:noreply, socket}

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

  defp parse_product_url(url) do
    with {:ok, %Finch.Response{body: body, status: 200}} <- Finch.build(:get, url) |> Finch.request(HabitQuestFinch),
         {:ok, document} <- Floki.parse_document(body) do
      %{
        "name" => extract_product_name(document),
        "description" => extract_product_description(document),
        "image_url" => extract_product_image(document, url)
      }
    else
      _ -> %{}
    end
  end

  defp extract_product_name(document) do
    document
    |> Floki.find("meta[property='og:title']")
    |> Floki.attribute("content")
    |> List.first()
    || document
    |> Floki.find("title")
    |> Floki.text()
    |> String.trim()
  end

  defp extract_product_description(document) do
    document
    |> Floki.find("meta[property='og:description']")
    |> Floki.attribute("content")
    |> List.first()
    || document
    |> Floki.find("meta[name='description']")
    |> Floki.attribute("content")
    |> List.first()
    || ""
  end

  defp extract_product_image(document, base_url) do
    image_url = document
    |> Floki.find("meta[property='og:image']")
    |> Floki.attribute("content")
    |> List.first()
    || document
    |> Floki.find("meta[property='product:image']")
    |> Floki.attribute("content")
    |> List.first()

    case image_url do
      nil -> nil
      url ->
        if String.starts_with?(url, ["http://", "https://"]) do
          url
        else
          URI.merge(base_url, url) |> URI.to_string()
        end
    end
  end
end
