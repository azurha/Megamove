defmodule Megamove.Valhalla.Types do
  @moduledoc """
  Types et structures de données pour les réponses de l'API Valhalla.
  """

  @type coordinate :: {float(), float()}
  @type location :: %{lat: float(), lon: float()}
  @type costing :: String.t()

  @type maneuver_type :: 
    :start | :start_right | :start_left | :destination | :destination_right | 
    :destination_left | :becomes | :continue | :slight_right | :right | 
    :sharp_right | :uturn_right | :uturn_left | :sharp_left | :left | 
    :slight_left | :ramp_straight | :ramp_right | :ramp_left | :exit_right | 
    :exit_left | :stay_straight | :stay_right | :stay_left | :merge | 
    :roundabout_enter | :roundabout_exit | :ferry_enter | :ferry_exit | 
    :transit | :transit_transfer | :transit_remain_on | :transit_connection_start | 
    :transit_connection_transfer | :transit_connection_destination | :post_transit_connection_destination

  @type maneuver :: %{
    type: maneuver_type(),
    instruction: String.t(),
    verbal_succinct_transition_instruction: String.t(),
    verbal_pre_transition_instruction: String.t(),
    verbal_post_transition_instruction: String.t(),
    street_names: [String.t()],
    bearing_before: integer(),
    bearing_after: integer(),
    time: float(),
    length: float(),
    cost: float(),
    begin_shape_index: integer(),
    end_shape_index: integer(),
    travel_mode: String.t(),
    travel_type: String.t()
  }

  @type leg_summary :: %{
    has_time_restrictions: boolean(),
    has_toll: boolean(),
    has_highway: boolean(),
    has_ferry: boolean(),
    min_lat: float(),
    min_lon: float(),
    max_lat: float(),
    max_lon: float(),
    time: float(),
    length: float(),
    cost: float()
  }

  @type leg :: %{
    maneuvers: [maneuver()],
    summary: leg_summary(),
    shape: String.t()
  }

  @type trip_location :: %{
    type: String.t(),
    lat: float(),
    lon: float(),
    original_index: integer(),
    side_of_street: String.t() | nil
  }

  @type trip_summary :: leg_summary()

  @type trip :: %{
    locations: [trip_location()],
    legs: [leg()],
    summary: trip_summary(),
    status_message: String.t(),
    status: integer(),
    units: String.t(),
    language: String.t()
  }

  @type route_response :: %{
    trip: trip()
  }

  @type contour :: %{
    time: integer() | nil,
    distance: integer() | nil,
    color: String.t() | nil
  }

  @type isochrone_response :: %{
    type: String.t(),
    features: [map()]
  }

  @type source_target :: %{
    lat: float(),
    lon: float(),
    date_time: String.t() | nil,
    type: String.t()
  }

  @type sources_to_targets_response :: %{
    sources_to_targets: [map()]
  }

  @type reverse_geocode_response :: %{
    address: map()
  }

  @type status_response :: %{
    version: String.t(),
    tileset_last_modified: integer(),
    available_actions: [String.t()]
  }

  @type valhalla_response :: 
    route_response() | 
    isochrone_response() | 
    sources_to_targets_response() | 
    reverse_geocode_response() | 
    status_response()

  @type valhalla_error :: 
    {:http_error, integer(), map()} | 
    {:network_error, term()} | 
    {:timeout, term()}

  @type valhalla_result :: {:ok, valhalla_response()} | {:error, valhalla_error()}
end
