defmodule Megamove.NominatimService do
  @moduledoc """
  Client léger pour le serveur Nominatim local, utilisé pour l'autocomplétion
  d'adresses et la récupération de coordonnées.

  Utilise `Req` comme client HTTP.
  """

  @config Application.compile_env(:megamove, :nominatim, [])
  @base_url Keyword.get(@config, :base_url, "http://localhost:8080")
  @timeout Keyword.get(@config, :timeout, 10_000)

  @type place :: %{
          required(:display_name) => String.t(),
          required(:lat) => float(),
          required(:lon) => float(),
          optional(:osm_id) => integer(),
          optional(:osm_type) => String.t(),
          optional(:type) => String.t()
        }

  @doc """
  Recherche des adresses pour une requête donnée.

  Options supportées:
  - `:limit` (par défaut 5)
  - `:countrycodes` liste de codes pays csv (ex: "fr,be")
  - `:language` langue préférée (ex: "fr")
  """
  @spec search(String.t(), keyword()) :: {:ok, [place()]} | {:error, term()}
  def search(query, opts \\ []) when is_binary(query) do
    limit = Keyword.get(opts, :limit, 5)
    countrycodes = Keyword.get(opts, :countrycodes, nil)
    language = Keyword.get(opts, :language, "fr")

    params =
      [
        format: "json",
        q: query,
        addressdetails: 1,
        limit: limit,
        accept_language: language
      ]
      |> maybe_put(:countrycodes, countrycodes)

    url = @base_url <> "/search"

    case Req.get(url,
           params: params,
           receive_timeout: @timeout,
           retry: :transient
         ) do
      {:ok, %{status: 200, body: body}} when is_list(body) ->
        {:ok, Enum.map(body, &map_place/1)}

      {:ok, %{status: status, body: body}} ->
        {:error, {:http_error, status, body}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  defp maybe_put(list, _key, nil), do: list
  defp maybe_put(list, key, value), do: Keyword.put(list, key, value)

  defp map_place(%{"display_name" => name, "lat" => lat, "lon" => lon} = p) do
    %{
      display_name: name,
      lat: parse_float(lat),
      lon: parse_float(lon),
      osm_id: p["osm_id"],
      osm_type: p["osm_type"],
      type: p["type"]
    }
  end

  defp map_place(other) when is_map(other) do
    %{
      display_name: Map.get(other, "display_name", ""),
      lat: parse_float(Map.get(other, "lat", 0.0)),
      lon: parse_float(Map.get(other, "lon", 0.0)),
      osm_id: Map.get(other, "osm_id"),
      osm_type: Map.get(other, "osm_type"),
      type: Map.get(other, "type")
    }
  end

  defp parse_float(v) when is_float(v), do: v
  defp parse_float(v) when is_integer(v), do: v / 1

  defp parse_float(v) when is_binary(v) do
    case Float.parse(v) do
      {f, _} -> f
      :error -> 0.0
    end
  end
end
