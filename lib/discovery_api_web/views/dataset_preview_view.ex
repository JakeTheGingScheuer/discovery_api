defmodule DiscoveryApiWeb.DatasetPreviewView do
  use DiscoveryApiWeb, :view

  def render("features.json", %{features: features, dataset_name: name}) do
    %{
      name: name,
      features: features,
      type: "FeatureCollection"
    }
  end
end