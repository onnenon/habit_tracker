defmodule HabitQuestWeb.Router do
  use HabitQuestWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, html: {HabitQuestWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", HabitQuestWeb do
    pipe_through :browser

    live "/", PageLive.Index, :index

    # Parent management routes
    live "/parents", ParentLive.Index, :index
    live "/parents/new", ParentLive.Index, :new
    live "/parents/:id/edit", ParentLive.Index, :edit

    # Task/Habit management routes (for parents)
    live "/tasks", TaskLive.Index, :index
    live "/tasks/new", TaskLive.Index, :new
    live "/tasks/:id/edit", TaskLive.Index, :edit

    # Child management routes (for parents)
    live "/children", ChildLive.Index, :index
    live "/children/new", ChildLive.Index, :new
    live "/children/:id/edit", ChildLive.Index, :edit
    live "/children/:id", ChildLive.Show, :show

    # Reward management routes
    live "/rewards", RewardLive.Index, :index
    live "/rewards/new", RewardLive.Index, :new
    live "/rewards/:id/edit", RewardLive.Index, :edit

    # Redeemed rewards routes
    live "/redeemed-rewards", RedeemedRewardLive.Index, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", HabitQuestWeb do
  #   pipe_through :api
  # end

  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:habit_quest, :dev_routes) do
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through :browser

      live_dashboard "/dashboard", metrics: HabitQuestWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end
