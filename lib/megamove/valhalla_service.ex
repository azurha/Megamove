defmodule Megamove.ValhallaService do
  @moduledoc """
  Service d'intégration avec l'API Valhalla pour le calcul d'itinéraires et l'optimisation.

  Ce service fournit des fonctions pour :
  - Calcul d'itinéraires simples et optimisés
  - Génération d'isochrones
  - Calcul de matrices de distances
  - Géocodage et géocodage inverse
  """

  @config Application.compile_env(:megamove, :valhalla, [])
  @base_url Keyword.get(@config, :base_url, "http://localhost:8002")
  @timeout Keyword.get(@config, :timeout, 30_000)

  @doc """
  Calcule un itinéraire simple entre deux points ou plus.

  ## Exemples

      iex> Megamove.ValhallaService.route([{48.8566, 2.3522}, {48.8606, 2.3376}])
      {:ok, %{trip: %{legs: [...]}}}

      iex> Megamove.ValhallaService.route([{48.8566, 2.3522}, {48.8606, 2.3376}], costing: "bicycle")
      {:ok, %{trip: %{legs: [...]}}}
  """
  @spec route(list({float(), float()}), keyword()) ::
          {:ok, map()} |
          {:ok, map(), %{url: String.t(), raw: String.t()}} |
          {:error, term()}
  def route(locations, opts \\ []) do
    costing = Keyword.get(opts, :costing, "auto")

    request_body = %{
      locations: Enum.map(locations, fn {lat, lon} -> %{lat: lat, lon: lon} end),
      costing: costing
    }

    make_request("/route", request_body, opts)
  end

  @doc """
  Calcule un itinéraire optimisé pour plusieurs points (TSP - Traveling Salesman Problem).

  ## Exemples

      iex> Megamove.ValhallaService.optimized_route([{48.8566, 2.3522}, {48.8606, 2.3376}, {48.8584, 2.2945}])
      {:ok, %{trip: %{legs: [...]}}}
  """
  @spec optimized_route(list({float(), float()}), keyword()) :: {:ok, map()} | {:error, term()}
  def optimized_route(locations, opts \\ []) do
    costing = Keyword.get(opts, :costing, "auto")

    request_body = %{
      locations: Enum.map(locations, fn {lat, lon} -> %{lat: lat, lon: lon} end),
      costing: costing
    }

    make_request("/optimized_route", request_body, opts)
  end

  @doc """
  Génère des isochrones (zones accessibles en temps ou distance).

  ## Exemples

      iex> Megamove.ValhallaService.isochrone({48.8566, 2.3522}, [%{time: 15}])
      {:ok, %{type: "FeatureCollection", features: [...]}}

      iex> Megamove.ValhallaService.isochrone({48.8566, 2.3522}, [%{distance: 5}], costing: "bicycle")
      {:ok, %{type: "FeatureCollection", features: [...]}}
  """
  @spec isochrone({float(), float()}, list(map()), keyword()) :: {:ok, map()} | {:error, term()}
  def isochrone({lat, lon}, contours, opts \\ []) do
    costing = Keyword.get(opts, :costing, "auto")

    request_body = %{
      locations: [%{lat: lat, lon: lon}],
      costing: costing,
      contours: contours
    }

    make_request("/isochrone", request_body, opts)
  end

  @doc """
  Calcule une matrice de distances entre des sources et des destinations.

  ## Exemples

      iex> sources = [{48.8566, 2.3522}, {48.8606, 2.3376}]
      iex> targets = [{48.8584, 2.2945}, {48.8522, 2.3376}]
      iex> Megamove.ValhallaService.sources_to_targets(sources, targets)
      {:ok, %{sources_to_targets: [...]}}
  """
  @spec sources_to_targets(list({float(), float()}), list({float(), float()}), keyword()) ::
          {:ok, map()} | {:error, term()}
  def sources_to_targets(sources, targets, opts \\ []) do
    costing = Keyword.get(opts, :costing, "auto")

    request_body = %{
      sources: Enum.map(sources, fn {lat, lon} -> %{lat: lat, lon: lon} end),
      targets: Enum.map(targets, fn {lat, lon} -> %{lat: lat, lon: lon} end),
      costing: costing
    }

    make_request("/sources_to_targets", request_body, opts)
  end

  @doc """
  Effectue un géocodage inverse (coordonnées vers adresse).

  ## Exemples

      iex> Megamove.ValhallaService.reverse_geocode({48.8566, 2.3522})
      {:ok, %{address: %{...}}}
  """
  @spec reverse_geocode({float(), float()}, keyword()) :: {:ok, map()} | {:error, term()}
  def reverse_geocode({lat, lon}, _opts \\ []) do
    request_body = %{
      locations: [%{lat: lat, lon: lon}]
    }

    make_request("/locate", request_body, [])
  end

  @doc """
  Vérifie le statut du serveur Valhalla.
  """
  @spec status() :: {:ok, map()} | {:error, term()}
  def status do
    make_request("/status", %{}, [])
  end

  # Fonctions privées

  defp make_request(endpoint, body, opts) do
    url = @base_url <> endpoint
    debug? = Keyword.get(opts, :debug, false)

    if debug? do
      case Req.post(url,
             json: body,
             receive_timeout: @timeout,
             retry: :transient,
             decode_body: false
           ) do
        {:ok, %{status: 200, body: raw_body}} ->
          case Jason.decode(raw_body) do
            {:ok, parsed} -> {:ok, parsed, %{url: url, raw: raw_body}}
            {:error, _} -> {:error, {:decode_error, url, raw_body}}
          end

        {:ok, %{status: status, body: raw_body}} ->
          {:error, {:http_error, status, raw_body, url}}

        {:error, reason} ->
          {:error, reason}
      end
    else
      case Req.post(url,
             json: body,
             receive_timeout: @timeout,
             retry: :transient
           ) do
        {:ok, %{status: 200, body: response}} ->
          {:ok, response}

        {:ok, %{status: status, body: body}} ->
          {:error, {:http_error, status, body}}

        {:error, reason} ->
          {:error, reason}
      end
    end
  end
end
