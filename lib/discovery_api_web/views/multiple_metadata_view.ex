defmodule DiscoveryApiWeb.MultipleMetadataView do
  use DiscoveryApiWeb, :view
  alias DiscoveryApi.Data.Model
  alias DiscoveryApi.Schemas.Organizations

  def accepted_formats() do
    ["json"]
  end

  def render("search_dataset_summaries.json", %{
        models: models,
        facets: facets,
        sort: sort_by,
        offset: offset,
        limit: limit
      }) do
    datasets =
      models
      |> DiscoveryApiWeb.Utilities.ModelSorter.sort_models(sort_by)
      |> Enum.map(&translate_to_dataset/1)

    paginated_datasets = paginate(datasets, offset, limit)

    %{
      "metadata" => %{
        "totalDatasets" => Enum.count(datasets),
        "facets" => facets,
        "limit" => limit,
        "offset" => offset
      },
      "results" => paginated_datasets
    }
  end

  def render("get_data_json.json", %{models: models, organizations: organizations}) do
    translate_to_open_data_schema(models, organizations)
  end

  defp translate_to_open_data_schema(models, organizations) do
    %{
      conformsTo: "https://project-open-data.cio.gov/v1.1/schema",
      "@context": "https://project-open-data.cio.gov/v1.1/schema/catalog.jsonld",
      dataset: Enum.map(models, &translate_to_open_dataset(&1, organizations))
    }
  end

  defp translate_to_open_dataset(%Model{} = model, organizations) do
    organization_name =
      organizations
      # TODO - what if this isn't found?
      |> Enum.find(fn org -> org.org_id == model.organization_id end)
      |> Map.get(:title, "")

    %{
      "@type" => "dcat:Dataset",
      "identifier" => model.id,
      "title" => model.title,
      "description" => model.description,
      "keyword" => val_or_optional(model.keywords),
      "modified" => model.modifiedDate,
      "publisher" => %{
        "@type" => "org:Organization",
        "name" => organization_name
      },
      "contactPoint" => %{
        "@type" => "vcard:Contact",
        "fn" => model.contactName,
        "hasEmail" => "mailto:" <> model.contactEmail
      },
      "accessLevel" => model.accessLevel,
      "license" => val_or_optional(model.license),
      "rights" => val_or_optional(model.rights),
      "spatial" => val_or_optional(model.spatial),
      "temporal" => val_or_optional(model.temporal),
      "distribution" => [
        %{
          "@type" => "dcat:Distribution",
          "accessURL" => "#{DiscoveryApiWeb.Endpoint.url()}/api/v1/dataset/#{model.id}/download?_format=json",
          "mediaType" => "application/json"
        },
        %{
          "@type" => "dcat:Distribution",
          "accessURL" => "#{DiscoveryApiWeb.Endpoint.url()}/api/v1/dataset/#{model.id}/download?_format=csv",
          "mediaType" => "text/csv"
        }
      ],
      "accrualPeriodicity" => val_or_optional(model.publishFrequency),
      "conformsTo" => val_or_optional(model.conformsToUri),
      "describedBy" => val_or_optional(model.describedByUrl),
      "describedByType" => val_or_optional(model.describedByMimeType),
      "isPartOf" => val_or_optional(model.parentDataset),
      "issued" => val_or_optional(model.issuedDate),
      "language" => val_or_optional(model.language),
      "landingPage" => val_or_optional(model.homepage),
      "references" => val_or_optional(model.referenceUrls),
      "theme" => val_or_optional(model.categories)
    }
    |> remove_optional_values()
  end

  defp remove_optional_values(map) do
    map
    |> Enum.filter(fn {_key, value} ->
      value != :optional
    end)
    |> Enum.into(Map.new())
  end

  defp val_or_optional(nil), do: :optional
  defp val_or_optional(val), do: val

  defp translate_to_dataset(%Model{} = model) do
    # TODO: should this be looked up in the controller?
    # also what if we don't find an organization?
    organization = Organizations.get_organization(model.organization_id)

    %{
      id: model.id,
      name: model.name,
      title: model.title,
      keywords: model.keywords,
      systemName: model.systemName,
      organization_title: organization.title,
      organization_name: organization.name,
      organization_image_url: organization.logo_url,
      modified: model.modifiedDate,
      fileTypes: model.fileTypes,
      description: model.description,
      sourceType: model.sourceType,
      sourceUrl: model.sourceUrl,
      lastUpdatedDate: model.lastUpdatedDate
    }
  end

  defp paginate(models, offset, limit) do
    Enum.slice(models, offset, limit)
  end
end
