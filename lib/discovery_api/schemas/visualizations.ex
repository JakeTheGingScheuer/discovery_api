defmodule DiscoveryApi.Schemas.Visualizations do
  @moduledoc """
  Interface for reading and writing the Visualization schema.
  """
  alias DiscoveryApi.Repo
  alias Ecto.Changeset
  alias DiscoveryApi.Schemas.Visualizations.Visualization

  def list_visualizations do
    Repo.all(Visualization)
  end

  def create_visualization(visualization_attributes) do
    %Visualization{}
    |> Visualization.changeset(visualization_attributes)
    |> Repo.insert()
  end

  def get_visualization_by_id(public_id) do
    case Repo.get_by(Visualization, public_id: public_id) do
      nil -> {:error, "#{public_id} not found"}
      visualization -> {:ok, visualization |> Repo.preload(:owner)}
    end
  end

  def update_visualization_by_id(id, visualization_changes, user, opts \\ []) do
    {:ok, existing_visualization} = get_visualization_by_id(id)

    if user.id == existing_visualization.owner_id do
      existing_visualization
      |> Visualization.changeset_update(visualization_changes)
      |> Repo.update(opts)
    else
      {:error, "Visualization failed to update"}
    end
  end
end
