defmodule Bridge.Web.Router do
  use Bridge.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :validate_host
    plug :extract_subdomain
  end

  pipeline :team do
    plug :fetch_team
    plug :fetch_current_user_by_session
    plug :authenticate_user
  end

  pipeline :browser_api do
    plug :accepts, ["json"]
    plug :fetch_session
    plug :protect_from_forgery
    plug :put_secure_browser_headers
    plug :validate_host
    plug :extract_subdomain
  end

  pipeline :graphql do
    plug :validate_host
    plug :extract_subdomain
    plug :fetch_team
    plug :authenticate_with_token
  end

  # GraphQL API
  scope "/" do
    pipe_through :graphql
    forward "/graphql", Absinthe.Plug, schema: Bridge.Web.Schema
  end

  # Launcher-scoped routes
  scope "/", Bridge.Web, host: "launch." do
    pipe_through :browser # Use the default browser stack

    get "/", TeamSearchController, :new
    post "/", TeamSearchController, :create
    resources "/teams", TeamController, only: [:new, :create]
  end

  # Team-scoped routes not requiring authentication
  scope "/", Bridge.Web do
    pipe_through :browser

    get "/login", SessionController, :new
    post "/login", SessionController, :create
  end

  # GraphQL explorer
  scope "/" do
    pipe_through [:browser, :team]
    forward "/graphiql", Absinthe.Plug.GraphiQL, schema: Bridge.Web.Schema
  end

  # Team-scoped routes requiring authentication
  scope "/", Bridge.Web do
    pipe_through [:browser, :team]

    get "/", ThreadController, :index
  end

  # RESTful API endpoints authenticated via browser cookies
  scope "/api", Bridge.Web.API do
    pipe_through :browser_api

    resources "/teams", TeamController, only: [:create]
    post "/signup/errors", SignupErrorsController, :index

    resources "/user_tokens", UserTokenController, only: [:create]
  end
end
