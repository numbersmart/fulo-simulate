# routing.R - Delivery Routing and Logistics Module
#
# This module handles route assignment, distance calculation, travel time
# estimation with traffic and parking difficulty simulation.
#
# Phase: 4 - Order Generation & Randomization

#' Calculate route distance using simplified Manhattan distance
#'
#' Calculates distance between two lat/lon points using Manhattan distance
#' approximation suitable for urban delivery routing.
#' ASSUMPTION: 1 degree latitude ~ 111 km, 1 degree longitude ~ 85 km at Madrid latitude
#'
#' @param lat1 Numeric origin latitude
#' @param lon1 Numeric origin longitude
#' @param lat2 Numeric destination latitude
#' @param lon2 Numeric destination longitude
#'
#' @return Numeric distance in kilometers
calculate_route_distance <- function(lat1, lon1, lat2, lon2) {

  # Madrid latitude factor for longitude distance
  # At 40 degrees latitude, 1 degree lon ~ 85 km
  KM_PER_LAT_DEGREE <- 111
  KM_PER_LON_DEGREE <- 85

  # Manhattan distance (more realistic for urban grid than crow-flies)
  lat_diff_km <- abs(lat2 - lat1) * KM_PER_LAT_DEGREE
  lon_diff_km <- abs(lon2 - lon1) * KM_PER_LON_DEGREE

  # ASSUMPTION: Urban driving distance is ~1.3x Manhattan distance due to one-way streets
  manhattan_distance <- lat_diff_km + lon_diff_km
  driving_distance <- manhattan_distance * 1.3

  return(driving_distance)
}


#' Calculate travel time including traffic and parking
#'
#' Estimates total time for a delivery stop including driving, traffic delays,
#' and parking/walking time based on difficulty.
#'
#' @param distance_km Numeric distance in kilometers
#' @param hour_of_day Numeric 0-23 hour
#' @param parking_difficulty Integer 1-10 scale
#' @param is_pickup Logical, TRUE for pickup stops, FALSE for delivery
#'
#' @return Numeric time in minutes
calculate_travel_time <- function(distance_km, hour_of_day, parking_difficulty, is_pickup = FALSE) {

  # ASSUMPTION: Base speed is 30 km/h in Madrid urban areas
  base_speed_kmh <- 30

  # Apply traffic multiplier based on time of day
  # Rush hours (8-10 AM, 6-8 PM) have 1.5x slower traffic
  # Midday (11-5 PM) has 1.2x slower traffic
  # Late evening/early morning (10 PM - 7 AM) has normal traffic
  traffic_multiplier <- if (hour_of_day >= 8 && hour_of_day < 10) {
    1.5  # Morning rush
  } else if (hour_of_day >= 18 && hour_of_day < 20) {
    1.5  # Evening rush
  } else if (hour_of_day >= 11 && hour_of_day < 17) {
    1.2  # Midday traffic
  } else {
    1.0  # Normal traffic
  }

  # Calculate base driving time
  effective_speed <- base_speed_kmh / traffic_multiplier
  driving_time_min <- (distance_km / effective_speed) * 60

  # Add parking difficulty time
  # ASSUMPTION: Parking difficulty scales from 2 min (easy) to 15 min (very hard)
  # Scale is 1-10, so (difficulty - 1) / 9 * 13 + 2
  parking_time_min <- ((parking_difficulty - 1) / 9) * 13 + 2

  # Pickup stops take longer (need to interact with customer, load items)
  # Delivery stops also require customer interaction
  # ASSUMPTION: Average customer interaction time is 5 minutes
  customer_interaction_min <- 5

  total_time_min <- driving_time_min + parking_time_min + customer_interaction_min

  return(total_time_min)
}


#' Calculate route time for a sequence of stops
#'
#' Calculates total time for a van route visiting multiple stops in sequence.
#' Includes warehouse departure and return.
#'
#' @param stop_lats Vector of latitudes for each stop
#' @param stop_lons Vector of longitudes for each stop
#' @param stop_times Vector of POSIXct times for each stop
#' @param parking_difficulties Vector of parking difficulty for each stop
#' @param is_pickups Vector of logical, TRUE for pickup stops
#' @param warehouse_lat Numeric warehouse latitude
#' @param warehouse_lon Numeric warehouse longitude
#'
#' @return List with total_time_min, total_distance_km, and per_stop details
calculate_route_metrics <- function(stop_lats, stop_lons, stop_times,
                                    parking_difficulties, is_pickups,
                                    warehouse_lat = 40.4168, warehouse_lon = -3.7038) {

  num_stops <- length(stop_lats)

  if (num_stops == 0) {
    return(list(
      total_time_min = 0,
      total_distance_km = 0,
      stop_times = numeric(0),
      stop_distances = numeric(0)
    ))
  }

  # Start from warehouse
  current_lat <- warehouse_lat
  current_lon <- warehouse_lon

  total_time_min <- 0
  total_distance_km <- 0
  stop_times_min <- numeric(num_stops)
  stop_distances_km <- numeric(num_stops)

  # Visit each stop in sequence
  for (i in 1:num_stops) {
    # Calculate distance from current position to this stop
    distance <- calculate_route_distance(current_lat, current_lon,
                                         stop_lats[i], stop_lons[i])

    # Get hour of day for traffic calculation
    hour_of_day <- as.numeric(format(stop_times[i], "%H"))

    # Calculate time including traffic and parking
    time_min <- calculate_travel_time(
      distance_km = distance,
      hour_of_day = hour_of_day,
      parking_difficulty = parking_difficulties[i],
      is_pickup = is_pickups[i]
    )

    # Accumulate totals
    total_time_min <- total_time_min + time_min
    total_distance_km <- total_distance_km + distance
    stop_times_min[i] <- time_min
    stop_distances_km[i] <- distance

    # Update current position
    current_lat <- stop_lats[i]
    current_lon <- stop_lons[i]
  }

  # Return to warehouse
  final_distance <- calculate_route_distance(current_lat, current_lon,
                                             warehouse_lat, warehouse_lon)
  final_time <- (final_distance / 30) * 60  # Base speed, no parking needed

  total_time_min <- total_time_min + final_time
  total_distance_km <- total_distance_km + final_distance

  return(list(
    total_time_min = total_time_min,
    total_distance_km = total_distance_km,
    stop_times_min = stop_times_min,
    stop_distances_km = stop_distances_km
  ))
}


#' Assign orders to routes and vans
#'
#' Groups orders into van routes based on geographic clustering and timing.
#' This is a simplified assignment - production system would use optimization.
#'
#' @param orders Data frame of orders with route_cluster, lat, lon, preferred times
#' @param time_slot POSIXct time for this route (pickup or delivery window)
#' @param available_vans Integer number of vans available
#' @param is_pickup_route Logical, TRUE for pickup routes, FALSE for delivery routes
#'
#' @return List with route_assignments (vector of van IDs) and route_metrics
#'
#' @export
assign_routes <- function(orders, time_slot, available_vans, is_pickup_route = TRUE) {

  if (nrow(orders) == 0) {
    return(list(
      route_assignments = integer(0),
      route_metrics = list()
    ))
  }

  # Sort orders by route cluster to group nearby addresses
  orders <- orders[order(orders$route_cluster), ]

  # ASSUMPTION: Simple round-robin assignment to vans within each cluster
  # Production system would use vehicle routing problem (VRP) optimization

  # Assign van IDs - rotate through available vans
  route_assignments <- rep(1:available_vans, length.out = nrow(orders))

  # Calculate metrics for each van route
  route_metrics <- list()

  for (van_id in 1:available_vans) {
    van_orders <- orders[route_assignments == van_id, ]

    if (nrow(van_orders) > 0) {
      metrics <- calculate_route_metrics(
        stop_lats = van_orders$address_lat,
        stop_lons = van_orders$address_lon,
        stop_times = rep(time_slot, nrow(van_orders)),
        parking_difficulties = van_orders$parking_difficulty,
        is_pickups = rep(is_pickup_route, nrow(van_orders))
      )

      route_metrics[[as.character(van_id)]] <- metrics
    }
  }

  return(list(
    route_assignments = route_assignments,
    route_metrics = route_metrics
  ))
}


#' Calculate delivery cost for a route
#'
#' Computes total cost including driver time and fuel based on route metrics.
#'
#' @param route_metrics List from calculate_route_metrics
#' @param driver_hourly_rate Numeric EUR per hour
#' @param fuel_per_km Numeric EUR per kilometer
#'
#' @return Numeric total cost in EUR
calculate_route_cost <- function(route_metrics, driver_hourly_rate, fuel_per_km) {

  # Driver cost based on time
  time_hours <- route_metrics$total_time_min / 60
  driver_cost <- time_hours * driver_hourly_rate

  # Fuel cost based on distance
  fuel_cost <- route_metrics$total_distance_km * fuel_per_km

  total_cost <- driver_cost + fuel_cost

  return(total_cost)
}


#' Simulate traffic variability
#'
#' Adds random variation to route times to simulate real-world unpredictability.
#' ASSUMPTION: Traffic can vary by +/- 20% from estimated time
#'
#' @param estimated_time_min Numeric estimated time
#' @param random_seed Integer for reproducibility
#'
#' @return Numeric actual time with random variation
simulate_traffic_variability <- function(estimated_time_min, random_seed = NULL) {

  if (!is.null(random_seed)) {
    set.seed(random_seed)
  }

  # Normal distribution with mean=1.0, sd=0.1 gives ~20% variation
  variability_factor <- rnorm(1, mean = 1.0, sd = 0.1)
  variability_factor <- max(0.8, min(1.2, variability_factor))  # Clamp to +/- 20%

  actual_time_min <- estimated_time_min * variability_factor

  return(actual_time_min)
}
