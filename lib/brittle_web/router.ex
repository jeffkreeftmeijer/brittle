defmodule BrittleWeb.Router do
  use BrittleWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  scope "/", BrittleWeb do
    pipe_through :browser # Use the default browser stack

  end
end
