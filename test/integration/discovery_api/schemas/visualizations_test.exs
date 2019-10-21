defmodule DiscoveryApi.Schemas.VisualizationsTest do
  use ExUnit.Case
  use Divo, services: [:redis, :"ecto-postgres", :zookeeper, :kafka]
  use DiscoveryApi.DataCase

  alias DiscoveryApi.Repo
  alias DiscoveryApi.Schemas.{Generators, Users, Visualizations}
  alias DiscoveryApi.Schemas.Visualizations.Visualization
  alias DiscoveryApi.Schemas.Users.User

  describe "get/1" do
    test "given an existing visualizaiton, it returns an :ok tuple with it" do
      {:ok, owner} = Users.create_or_update("me|you", %{email: "bob@example.com"})

      {:ok, %{id: saved_id, public_id: saved_public_id}} =
        Visualizations.create(%{query: "select * from turtles", owner: owner, title: "My first visualization"})

      assert {:ok, %{id: ^saved_id}} = Visualizations.get_visualization(saved_public_id)
    end

    test "given a non-existing visualizaiton, it returns an :error tuple" do
      hopefully_unique_id = Generators.generate_public_id(32)

      assert {:error, _} = Visualizations.get_visualization(hopefully_unique_id)
    end
  end

  describe "create/1" do
    test "given all required attributes, it creates a visualization" do
      query = "select * from turtles"
      title = "My first visualization"
      {:ok, owner} = Users.create_or_update("me|you", %{email: "bob@example.com"})

      assert {:ok, saved} = Visualizations.create(%{query: query, owner: owner, title: title})

      actual = Repo.get(Visualization, saved.id)
      assert query == actual.query
    end

    test "given a missing query, it fails to create a visualization" do
      title = "My first visualization"
      {:ok, owner} = Users.create_or_update("me|you", %{email: "bob@example.com"})

      assert {:error, _} = Visualizations.create(%{owner: owner, title: title})
    end

    test "given a missing title, it fails to create a visualization" do
      query = "select * from turtles"
      {:ok, owner} = Users.create_or_update("me|you", %{email: "bob@example.com"})

      assert {:error, _} = Visualizations.create(%{query: query, owner: owner})
    end

    test "given a missing owner, it fails to create a visualization" do
      query = "select * from turtles"
      title = "My first visualization"

      assert {:error, _} = Visualizations.create(%{query: query, title: title})
    end

    test "given an invalid owner, it fails to create a visualization" do
      query = "select * from turtles"
      title = "My first visualization"
      owner = %User{id: 100, subject_id: "you|them"}

      assert_raise Postgrex.Error, fn ->
        Visualizations.create(%{query: query, title: title, owner: owner})
      end
    end

    test "given a non-existent owner, it creates the visualization and the owner" do
      query = "select * from turtles"
      title = "My first visualization"
      owner = %User{subject_id: "you|them", email: "bob@example.com"}

      assert {:ok, _} = Visualizations.create(%{query: query, title: title, owner: owner})
      assert {:ok, _} = Users.get_user("you|them")
    end
  end
end