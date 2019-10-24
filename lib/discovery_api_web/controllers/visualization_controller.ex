defmodule DiscoveryApiWeb.VisualizationController do
  require Logger
  use DiscoveryApiWeb, :controller

  alias DiscoveryApi.Schemas.Users
  alias DiscoveryApi.Schemas.Visualizations
  alias DiscoveryApi.Schemas.Visualizations.Visualization

  plug(:accepts, DiscoveryApiWeb.VisualizationView.accepted_formats())

  def show(conn, %{"id" => id}) do
    render_authorized_visualization(conn, Visualizations.get_visualization(id))
  end

  defp render_authorized_visualization(conn, {:error, _}), do: render_error(conn, 404, "Not Found")

  defp render_authorized_visualization(conn, {:ok, visualization}), do: render(conn, :visualization, %{visualization: visualization})

  def create(conn, %{"query" => query, "title" => title}) do
    with {:ok, user} <- Users.get_user(conn.assigns.current_user),
         {:ok, visualization} <- Visualizations.create(%{query: query, title: title, owner: user}) do
      conn
      |> put_status(:created)
      |> render(:visualization, %{visualization: visualization})
    else
      _ -> render_error(conn, 400, "Bad Request")
    end
  end

  def update(conn, %{"id" => id, "query" => query, "title" => title} = attribute_changes) do
    with {:ok, user} <- Users.get_user(conn.assigns.current_user),
         {:ok, existing_visualization} <- Visualizations.get_visualization(id),
         {:ok, visualization_changeset} <- Visualization.changeset(existing_visualization, attribute_changes),
         {:ok, visualization} <- Visualizations.update(visualization_changeset) do
      conn
      |> put_status(:accepted)
      |> render(:visualization, %{visualization: visualization})
    else
      _ -> render_error(conn, 400, "Bad Request")
    end
  end
end
