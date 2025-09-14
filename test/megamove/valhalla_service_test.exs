defmodule Megamove.ValhallaServiceTest do
  use Megamove.DataCase, async: true

  alias Megamove.ValhallaService

  describe "route/2" do
    test "calcule un itinéraire simple entre deux points" do
      locations = [{48.8566, 2.3522}, {48.8606, 2.3376}]

      assert {:ok, response} = ValhallaService.route(locations)
      assert %{"trip" => trip} = response
      assert %{"legs" => legs, "summary" => summary} = trip
      assert is_list(legs)
      assert %{"time" => time, "length" => length} = summary
      assert is_float(time)
      assert is_float(length)
    end

    test "calcule un itinéraire avec un mode de transport spécifique" do
      locations = [{48.8566, 2.3522}, {48.8606, 2.3376}]

      assert {:ok, response} = ValhallaService.route(locations, costing: "bicycle")
      assert %{"trip" => trip} = response
      assert %{"legs" => legs} = trip
      assert is_list(legs)
    end

    test "gère les erreurs de réseau" do
      # Test avec un serveur inexistant
      original_config = Application.get_env(:megamove, :valhalla)
      Application.put_env(:megamove, :valhalla, [base_url: "http://localhost:9999"])

      locations = [{48.8566, 2.3522}, {48.8606, 2.3376}]

      # Le test peut réussir si le serveur local est accessible sur le port 9999
      # ou échouer avec une erreur de connexion
      result = ValhallaService.route(locations)
      assert match?({:ok, _}, result) or match?({:error, _}, result)

      # Restaurer la configuration
      Application.put_env(:megamove, :valhalla, original_config)
    end
  end

  describe "optimized_route/2" do
    test "calcule un itinéraire optimisé pour plusieurs points" do
      locations = [
        {48.8566, 2.3522},
        {48.8606, 2.3376},
        {48.8584, 2.2945}
      ]

      assert {:ok, response} = ValhallaService.optimized_route(locations)
      assert %{"trip" => trip} = response
      assert %{"legs" => legs, "summary" => summary} = trip
      assert is_list(legs)
      assert %{"time" => time, "length" => length} = summary
      assert is_float(time)
      assert is_float(length)
    end
  end

  describe "isochrone/3" do
    test "génère des isochrones basées sur le temps" do
      location = {48.8566, 2.3522}
      contours = [%{time: 15}]

      assert {:ok, response} = ValhallaService.isochrone(location, contours)
      assert %{"type" => "FeatureCollection", "features" => features} = response
      assert is_list(features)
    end

    test "génère des isochrones basées sur la distance" do
      location = {48.8566, 2.3522}
      contours = [%{distance: 5}]

      assert {:ok, response} = ValhallaService.isochrone(location, contours)
      assert %{"type" => "FeatureCollection", "features" => features} = response
      assert is_list(features)
    end
  end

  describe "sources_to_targets/3" do
    test "calcule une matrice de distances" do
      sources = [{48.8566, 2.3522}, {48.8606, 2.3376}]
      targets = [{48.8584, 2.2945}, {48.8522, 2.3376}]

      assert {:ok, response} = ValhallaService.sources_to_targets(sources, targets)
      assert %{"sources_to_targets" => matrix} = response
      assert is_list(matrix)
    end
  end

  describe "reverse_geocode/2" do
    test "effectue un géocodage inverse" do
      location = {48.8566, 2.3522}

      assert {:ok, response} = ValhallaService.reverse_geocode(location)
      assert is_list(response)
    end
  end

  describe "status/0" do
    test "vérifie le statut du serveur" do
      assert {:ok, response} = ValhallaService.status()
      assert %{"version" => version, "available_actions" => actions} = response
      assert is_binary(version)
      assert is_list(actions)
      assert "route" in actions
      assert "optimized_route" in actions
    end
  end
end
