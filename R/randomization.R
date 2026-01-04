# randomization.R - Order Generation and Randomization Module
#
# This module generates realistic order patterns based on configuration parameters
# including demand scenarios, time-based patterns, and price elasticity.
#
# Phase: 4 - Order Generation & Randomization

#' Generate orders for simulation period
#'
#' Creates realistic order data based on configuration parameters including
#' demand scenario, peak hours, price elasticity, and regional characteristics.
#'
#' @param config List containing all simulation configuration parameters
#' @param random_seed Integer seed for reproducibility (default: 42)
#'
#' @return data.frame with columns:
#'   - order_id: Unique identifier
#'   - placement_time: POSIXct timestamp when order placed
#'   - preferred_pickup_time: POSIXct customer's preferred pickup window start
#'   - preferred_delivery_time: POSIXct customer's preferred delivery window start
#'   - service_type: "wash_only", "dry_only", or "wash_dry"
#'   - kg_estimate: Numeric estimated weight in kg
#'   - is_subscription: Logical whether customer has subscription
#'   - self_check_enabled: Logical whether customer does self-check
#'   - complexity_factor: Numeric 0.8-1.2 multiplier for processing time
#'   - route_cluster: Integer geographic cluster assignment (1-5)
#'   - address_lat: Numeric latitude for routing
#'   - address_lon: Numeric longitude for routing
#'   - parking_difficulty: Integer 1-10 from config
#'
#' @export
generate_orders <- function(config, random_seed = 42) {
  set.seed(random_seed)

  # Extract key parameters
  start_date <- as.POSIXct(config$simulation$start_date, tz = "UTC")
  duration_days <- config$simulation$duration_days
  time_slot_hours <- config$simulation$time_slot_hours

  # Calculate total number of orders based on demand scenario
  base_orders_per_day <- calculate_base_demand(config)
  total_orders <- round(base_orders_per_day * duration_days)

  message(sprintf("Generating %d orders over %d days (%.1f orders/day)",
                  total_orders, duration_days, base_orders_per_day))

  # Generate placement times with realistic distribution
  placement_times <- generate_placement_times(
    start_date = start_date,
    duration_days = duration_days,
    num_orders = total_orders,
    peak_start = config$randomization$peak_hours_start,
    peak_end = config$randomization$peak_hours_end,
    peak_multiplier = config$randomization$peak_hour_multiplier
  )

  # Generate order characteristics
  service_types <- generate_service_types(
    num_orders = total_orders,
    self_check_rate = config$elasticity$self_check_adoption_rate,
    subscription_ratio = config$elasticity$subscription_ratio
  )

  # Generate order sizes with price elasticity
  kg_estimates <- generate_order_sizes(
    num_orders = total_orders,
    price_elasticity = config$elasticity$price_elasticity,
    wash_price = config$pricing$wash_price,
    dry_price = config$pricing$dry_price
  )

  # Generate complexity factors (some orders take longer due to delicate items, etc.)
  complexity_factors <- rnorm(total_orders, mean = 1.0, sd = 0.1)
  complexity_factors <- pmax(0.8, pmin(1.2, complexity_factors))  # Clamp to [0.8, 1.2]

  # Generate geographic distribution
  geographic_data <- generate_geographic_distribution(
    num_orders = total_orders,
    density = config$regional$geographic_density,
    parking_difficulty = config$regional$parking_difficulty
  )

  # Generate pickup and delivery preferences (24-48 hour windows)
  time_preferences <- generate_time_preferences(
    placement_times = placement_times,
    time_slot_hours = time_slot_hours
  )

  # Assemble final data frame
  orders <- data.frame(
    order_id = sprintf("ORD_%06d", 1:total_orders),
    placement_time = placement_times,
    preferred_pickup_time = time_preferences$pickup,
    preferred_delivery_time = time_preferences$delivery,
    service_type = service_types$service_type,
    kg_estimate = kg_estimates,
    is_subscription = service_types$is_subscription,
    self_check_enabled = service_types$self_check_enabled,
    complexity_factor = complexity_factors,
    route_cluster = geographic_data$cluster,
    address_lat = geographic_data$lat,
    address_lon = geographic_data$lon,
    parking_difficulty = config$regional$parking_difficulty,
    stringsAsFactors = FALSE
  )

  # Sort by placement time for chronological processing
  orders <- orders[order(orders$placement_time), ]
  rownames(orders) <- NULL

  message(sprintf("Generated %d orders with %d wash_dry, %d wash_only, %d dry_only",
                  nrow(orders),
                  sum(orders$service_type == "wash_dry"),
                  sum(orders$service_type == "wash_only"),
                  sum(orders$service_type == "dry_only")))

  return(orders)
}


#' Calculate base daily demand based on scenario
#'
#' Uses demographic data and demand scenario to estimate daily order volume.
#' ASSUMPTION: Market penetration rates based on Fulo Madrid operations
#'
#' @param config Configuration list
#' @return Numeric average orders per day
calculate_base_demand <- function(config) {
  dwellings <- config$regional$dwellings
  population <- config$regional$population

  # ASSUMPTION: Base market penetration of 0.5% of dwellings per week in realistic scenario
  # This is conservative based on early-stage laundry service adoption
  base_penetration_weekly <- 0.005

  # Apply demand scenario multiplier
  demand_scenario <- config$randomization$demand_scenario

  scenario_multiplier <- switch(
    demand_scenario,
    "pessimistic" = 0.6,   # 40% lower demand
    "realistic" = 1.0,     # Base case
    "optimistic" = 1.5,    # 50% higher demand
    1.0  # Default to realistic if not specified
  )

  orders_per_week <- dwellings * base_penetration_weekly * scenario_multiplier
  orders_per_day <- orders_per_week / 7

  # Apply price elasticity adjustment
  # Higher prices reduce demand, lower prices increase it
  # Reference price: EUR7 wash + EUR8 dry = EUR15 for wash_dry service
  reference_price <- 15
  actual_avg_price <- config$pricing$wash_price + config$pricing$dry_price
  price_ratio <- actual_avg_price / reference_price

  # Elasticity formula: % change in quantity = -elasticity * % change in price
  price_elasticity <- config$elasticity$price_elasticity
  demand_adjustment <- (1 / price_ratio) ^ price_elasticity

  adjusted_orders_per_day <- orders_per_day * demand_adjustment

  return(adjusted_orders_per_day)
}


#' Generate order placement times with realistic patterns
#'
#' Creates timestamps following realistic daily patterns with peak hours.
#' Most orders placed in evenings when people are home from work.
#'
#' @param start_date POSIXct simulation start
#' @param duration_days Integer number of days
#' @param num_orders Integer total orders to generate
#' @param peak_start Character time string "HH:MM"
#' @param peak_end Character time string "HH:MM"
#' @param peak_multiplier Numeric multiplier for peak hour probability
#'
#' @return Vector of POSIXct timestamps
generate_placement_times <- function(start_date, duration_days, num_orders,
                                     peak_start, peak_end, peak_multiplier) {

  # Parse peak hours
  peak_start_hour <- as.numeric(strsplit(peak_start, ":")[[1]][1])
  peak_end_hour <- as.numeric(strsplit(peak_end, ":")[[1]][1])

  # Generate uniform distribution across days first
  day_offsets <- runif(num_orders, min = 0, max = duration_days)

  # Generate hour of day with peak hour bias
  hours <- numeric(num_orders)

  for (i in 1:num_orders) {
    # Decide if this order is in peak hours
    if (runif(1) < (peak_multiplier / (peak_multiplier + 1))) {
      # Peak hour order
      hours[i] <- runif(1, min = peak_start_hour, max = peak_end_hour)
    } else {
      # Off-peak order (distributed across remaining hours)
      # ASSUMPTION: Service available 6 AM to 11 PM (17 hours)
      available_hours <- c(6:peak_start_hour, peak_end_hour:23)
      hours[i] <- sample(available_hours, 1) + runif(1)
    }
  }

  # Combine day offset and hour to create full timestamps
  timestamps <- start_date + day_offsets * 86400 + hours * 3600

  return(timestamps)
}


#' Generate service types and customer attributes
#'
#' Determines service type (wash/dry/both) and customer characteristics
#' (subscription, self-check) based on adoption rates.
#'
#' @param num_orders Integer number of orders
#' @param self_check_rate Numeric proportion using self-check (0-1)
#' @param subscription_ratio Numeric proportion with subscription (0-1)
#'
#' @return data.frame with service_type, is_subscription, self_check_enabled
generate_service_types <- function(num_orders, self_check_rate, subscription_ratio) {

  # ASSUMPTION: Service type distribution based on Fulo Madrid data
  # Most customers want both wash and dry (70%), some only wash (20%), few only dry (10%)
  service_type_probs <- c(
    "wash_dry" = 0.70,
    "wash_only" = 0.20,
    "dry_only" = 0.10
  )

  service_types <- sample(
    names(service_type_probs),
    size = num_orders,
    replace = TRUE,
    prob = service_type_probs
  )

  # Subscription status (random assignment based on ratio)
  is_subscription <- runif(num_orders) < subscription_ratio

  # Self-check adoption (random assignment based on rate)
  # ASSUMPTION: Self-check users are more likely to be subscribers (correlation)
  self_check_base_prob <- ifelse(is_subscription,
                                 self_check_rate * 1.5,  # 50% higher for subscribers
                                 self_check_rate * 0.7)  # 30% lower for non-subscribers
  self_check_base_prob <- pmin(1.0, self_check_base_prob)  # Cap at 100%

  self_check_enabled <- runif(num_orders) < self_check_base_prob

  return(data.frame(
    service_type = service_types,
    is_subscription = is_subscription,
    self_check_enabled = self_check_enabled,
    stringsAsFactors = FALSE
  ))
}


#' Generate order sizes in kg
#'
#' Creates realistic order sizes based on service type.
#' ASSUMPTION: Average household laundry load is 6-8 kg
#'
#' @param num_orders Integer number of orders
#' @param price_elasticity Numeric elasticity coefficient
#' @param wash_price Numeric price per wash
#' @param dry_price Numeric price per dry
#'
#' @return Numeric vector of kg estimates
generate_order_sizes <- function(num_orders, price_elasticity, wash_price, dry_price) {

  # Base sizes: wash_dry has more items, wash_only and dry_only are smaller
  # ASSUMPTION: Normal distribution around typical household loads

  base_sizes <- numeric(num_orders)

  # Simple approach: Most orders are medium (6-8kg), some small (3-5kg), few large (9-12kg)
  size_category <- sample(c("small", "medium", "large"),
                          size = num_orders,
                          replace = TRUE,
                          prob = c(0.20, 0.60, 0.20))

  base_sizes[size_category == "small"] <- rnorm(sum(size_category == "small"), mean = 4, sd = 0.8)
  base_sizes[size_category == "medium"] <- rnorm(sum(size_category == "medium"), mean = 7, sd = 1.0)
  base_sizes[size_category == "large"] <- rnorm(sum(size_category == "large"), mean = 10, sd = 1.2)

  # Clamp to reasonable ranges
  base_sizes <- pmax(2, pmin(15, base_sizes))

  # Note: Price elasticity primarily affects order volume (handled in calculate_base_demand)
  # Individual order sizes are less affected by price

  return(round(base_sizes, 1))
}


#' Generate geographic distribution
#'
#' Creates realistic address distribution with clustering for route optimization.
#' Uses a simplified grid model for the service area.
#'
#' @param num_orders Integer number of orders
#' @param density Character "urban", "suburban", or "rural"
#' @param parking_difficulty Integer 1-10 scale
#'
#' @return data.frame with cluster, lat, lon
generate_geographic_distribution <- function(num_orders, density, parking_difficulty) {

  # ASSUMPTION: Service area is roughly 5km x 5km centered on warehouse
  # Madrid coordinates (example): warehouse at 40.4168 N, 3.7038 W
  warehouse_lat <- 40.4168
  warehouse_lon <- -3.7038

  # Assign orders to geographic clusters (for route optimization)
  # ASSUMPTION: 5 route clusters of roughly equal size
  num_clusters <- 5
  clusters <- sample(1:num_clusters, size = num_orders, replace = TRUE)

  # Generate coordinates around cluster centers
  # Each cluster is offset from warehouse in a different direction
  cluster_offsets <- data.frame(
    cluster = 1:5,
    lat_offset = c(0.02, 0.02, -0.02, -0.02, 0) / 1.5,  # ~2km radius
    lon_offset = c(0.02, -0.02, 0.02, -0.02, 0) / 1.5
  )

  # Density affects how spread out addresses are within clusters
  spread_factor <- switch(
    density,
    "urban" = 0.3,      # More concentrated
    "suburban" = 0.6,   # Medium spread
    "rural" = 1.0,      # More spread out
    0.5  # Default
  )

  # Generate individual addresses around cluster centers
  lats <- numeric(num_orders)
  lons <- numeric(num_orders)

  for (i in 1:num_orders) {
    cluster_id <- clusters[i]
    cluster_center_lat <- warehouse_lat + cluster_offsets$lat_offset[cluster_id]
    cluster_center_lon <- warehouse_lon + cluster_offsets$lon_offset[cluster_id]

    # Add random offset within cluster
    lats[i] <- cluster_center_lat + rnorm(1, mean = 0, sd = 0.008 * spread_factor)
    lons[i] <- cluster_center_lon + rnorm(1, mean = 0, sd = 0.008 * spread_factor)
  }

  return(data.frame(
    cluster = clusters,
    lat = lats,
    lon = lons,
    stringsAsFactors = FALSE
  ))
}


#' Generate customer time preferences
#'
#' Creates preferred pickup and delivery windows based on placement time.
#' ASSUMPTION: Customers prefer pickup within 24-48 hours, delivery 24-72 hours after pickup
#'
#' @param placement_times Vector of POSIXct placement timestamps
#' @param time_slot_hours Numeric hours per time slot
#'
#' @return List with pickup and delivery POSIXct vectors
generate_time_preferences <- function(placement_times, time_slot_hours) {

  num_orders <- length(placement_times)

  # Pickup preferences: 24-48 hours after placement
  # ASSUMPTION: Most customers flexible within this window
  pickup_delay_hours <- runif(num_orders, min = 24, max = 48)
  preferred_pickup <- placement_times + pickup_delay_hours * 3600

  # Round to nearest time slot boundary
  slot_seconds <- time_slot_hours * 3600
  preferred_pickup <- as.POSIXct(
    round(as.numeric(preferred_pickup) / slot_seconds) * slot_seconds,
    origin = "1970-01-01",
    tz = "UTC"
  )

  # Delivery preferences: 24-72 hours after preferred pickup
  # ASSUMPTION: Customers generally want laundry back within 1-3 days
  delivery_delay_hours <- runif(num_orders, min = 24, max = 72)
  preferred_delivery <- preferred_pickup + delivery_delay_hours * 3600

  # Round to nearest time slot boundary
  preferred_delivery <- as.POSIXct(
    round(as.numeric(preferred_delivery) / slot_seconds) * slot_seconds,
    origin = "1970-01-01",
    tz = "UTC"
  )

  return(list(
    pickup = preferred_pickup,
    delivery = preferred_delivery
  ))
}


#' Apply randomization effects to orders
#'
#' Simulates real-world randomness: some orders refunded, some deliveries failed, etc.
#' This modifies the order data frame in place after simulation.
#'
#' @param orders data.frame of orders (with status column from simulation)
#' @param config Configuration list
#' @param random_seed Integer seed for reproducibility
#'
#' @return Modified orders data.frame with refund and failure flags
#'
#' @export
apply_randomization_effects <- function(orders, config, random_seed = 42) {
  set.seed(random_seed + 1000)  # Different seed than generation

  num_orders <- nrow(orders)

  # Apply refund rate (customer cancellations, quality issues, etc.)
  refund_rate <- config$randomization$refund_rate
  orders$is_refunded <- runif(num_orders) < refund_rate

  # Apply failed delivery rate (customer not home, address issues, etc.)
  failed_delivery_rate <- config$randomization$failed_delivery_rate
  orders$delivery_failed <- runif(num_orders) < failed_delivery_rate

  # Refunds happen at various stages (some early, some late)
  # For simplicity, mark them but don't change status in this function
  # The simulation engine will handle refund logic

  message(sprintf("Applied randomization: %d refunds (%.1f%%), %d failed deliveries (%.1f%%)",
                  sum(orders$is_refunded), 100 * refund_rate,
                  sum(orders$delivery_failed), 100 * failed_delivery_rate))

  return(orders)
}
