# operations.R - Operational Metrics Module
#
# This module calculates operational metrics including capacity utilization,
# bottleneck identification, and efficiency measures.
#
# Phase: 5 - Financial & Operational Metrics

#' Calculate Resource Utilization
#'
#' Calculates utilization metrics for all resource types (vans, drivers, machines).
#'
#' @param capacity_log Data frame from simulation with resource usage history
#' @param config Configuration list with capacity parameters
#' @param simulation_results Full simulation results
#'
#' @return List with utilization metrics by resource type
#' @export
calculate_resource_utilization <- function(capacity_log, config, simulation_results) {

  # Extract capacity configuration
  num_vans <- config$capacity$num_vans
  num_drivers <- config$capacity$num_drivers
  num_wash_machines <- config$capacity$num_wash_machines
  num_dry_machines <- config$capacity$num_dry_machines
  operating_hours_per_day <- config$capacity$operating_hours_per_day
  simulation_duration_days <- config$simulation$duration_days

  # Total available capacity (resource-hours)
  total_operating_hours <- operating_hours_per_day * simulation_duration_days

  van_capacity_hours <- num_vans * total_operating_hours
  driver_capacity_hours <- num_drivers * total_operating_hours
  wash_capacity_hours <- num_wash_machines * total_operating_hours
  dry_capacity_hours <- num_dry_machines * total_operating_hours

  # Calculate actual usage from orders
  orders <- simulation_results$orders

  # ASSUMPTION: Simplified utilization based on order counts and estimates
  # Full implementation would track exact resource reservation times from capacity_log

  # Van and driver utilization (based on delivery estimates from Phase 4)
  num_orders <- nrow(orders)
  avg_stops_per_route <- 5
  num_routes <- ceiling(num_orders / avg_stops_per_route) * 2  # pickup + delivery
  hours_per_route <- 2
  van_hours_used <- num_routes * hours_per_route
  driver_hours_used <- van_hours_used  # Same as van hours

  van_utilization_pct <- (van_hours_used / van_capacity_hours) * 100
  driver_utilization_pct <- (driver_hours_used / driver_capacity_hours) * 100

  # Washing machine utilization
  wash_orders <- sum(grepl("wash", orders$service_type))
  avg_wash_time_hours <- 1.0  # ASSUMPTION: ~1 hour average per load
  wash_hours_used <- wash_orders * avg_wash_time_hours
  wash_utilization_pct <- (wash_hours_used / wash_capacity_hours) * 100

  # Drying machine utilization
  dry_orders <- sum(grepl("dry", orders$service_type))
  avg_dry_time_hours <- 1.2  # ASSUMPTION: ~1.2 hours average per load
  dry_hours_used <- dry_orders * avg_dry_time_hours
  dry_utilization_pct <- (dry_hours_used / dry_capacity_hours) * 100

  return(list(
    van = list(
      capacity_hours = van_capacity_hours,
      used_hours = van_hours_used,
      utilization_pct = van_utilization_pct,
      num_resources = num_vans
    ),
    driver = list(
      capacity_hours = driver_capacity_hours,
      used_hours = driver_hours_used,
      utilization_pct = driver_utilization_pct,
      num_resources = num_drivers
    ),
    wash_machine = list(
      capacity_hours = wash_capacity_hours,
      used_hours = wash_hours_used,
      utilization_pct = wash_utilization_pct,
      num_resources = num_wash_machines
    ),
    dry_machine = list(
      capacity_hours = dry_capacity_hours,
      used_hours = dry_hours_used,
      utilization_pct = dry_utilization_pct,
      num_resources = num_dry_machines
    ),
    summary = data.frame(
      resource_type = c("Van", "Driver", "Wash Machine", "Dry Machine"),
      utilization_pct = c(van_utilization_pct, driver_utilization_pct,
                          wash_utilization_pct, dry_utilization_pct),
      capacity_hours = c(van_capacity_hours, driver_capacity_hours,
                        wash_capacity_hours, dry_capacity_hours),
      used_hours = c(van_hours_used, driver_hours_used,
                    wash_hours_used, dry_hours_used),
      stringsAsFactors = FALSE
    )
  ))
}


#' Identify Bottlenecks
#'
#' Analyzes capacity utilization to identify bottlenecks and constraints.
#' A bottleneck is defined as a resource with >80% utilization.
#'
#' @param utilization List from calculate_resource_utilization
#'
#' @return List with bottleneck analysis
#' @export
identify_bottlenecks <- function(utilization) {

  # Threshold for bottleneck identification
  BOTTLENECK_THRESHOLD_PCT <- 80

  summary <- utilization$summary

  # Identify bottlenecks
  bottlenecks <- summary[summary$utilization_pct >= BOTTLENECK_THRESHOLD_PCT, ]

  # Identify underutilized resources (< 50%)
  UNDERUTILIZED_THRESHOLD_PCT <- 50
  underutilized <- summary[summary$utilization_pct < UNDERUTILIZED_THRESHOLD_PCT, ]

  # Overall system bottleneck (highest utilization)
  max_utilization_idx <- which.max(summary$utilization_pct)
  primary_bottleneck <- summary$resource_type[max_utilization_idx]
  primary_bottleneck_pct <- summary$utilization_pct[max_utilization_idx]

  # Capacity headroom
  summary$headroom_pct <- 100 - summary$utilization_pct

  return(list(
    bottlenecks = bottlenecks,
    underutilized = underutilized,
    primary_bottleneck = primary_bottleneck,
    primary_bottleneck_utilization = primary_bottleneck_pct,
    has_bottlenecks = nrow(bottlenecks) > 0,
    capacity_headroom = summary[, c("resource_type", "headroom_pct")],
    bottleneck_threshold = BOTTLENECK_THRESHOLD_PCT
  ))
}


#' Calculate Service Level Metrics
#'
#' Calculates service level metrics including on-time delivery, completion rate.
#'
#' @param orders Data frame of orders with timing information
#'
#' @return List with service level metrics
#' @export
calculate_service_metrics <- function(orders) {

  total_orders <- nrow(orders)

  # Completion rate (orders that reached delivered status)
  if ("status" %in% colnames(orders)) {
    completed_orders <- sum(orders$status == "delivered", na.rm = TRUE)
    completion_rate_pct <- (completed_orders / total_orders) * 100
  } else {
    completed_orders <- total_orders
    completion_rate_pct <- 100
  }

  # Failed orders (if failure tracking exists)
  if ("delivery_failed" %in% colnames(orders)) {
    failed_orders <- sum(orders$delivery_failed, na.rm = TRUE)
    failure_rate_pct <- (failed_orders / total_orders) * 100
  } else {
    failed_orders <- 0
    failure_rate_pct <- 0
  }

  # Refunded orders
  if ("is_refunded" %in% colnames(orders)) {
    refunded_orders <- sum(orders$is_refunded, na.rm = TRUE)
    refund_rate_pct <- (refunded_orders / total_orders) * 100
  } else {
    refunded_orders <- 0
    refund_rate_pct <- 0
  }

  # On-time delivery (within preferred window)
  # ASSUMPTION: If delivery_actual_time is within 4 hours of preferred, it's on-time
  if ("delivery_actual_time" %in% colnames(orders) &&
      "preferred_delivery_time" %in% colnames(orders)) {
    time_diff_hours <- as.numeric(difftime(
      orders$delivery_actual_time,
      orders$preferred_delivery_time,
      units = "hours"
    ))
    on_time_orders <- sum(abs(time_diff_hours) <= 4, na.rm = TRUE)
    on_time_pct <- (on_time_orders / total_orders) * 100
  } else {
    on_time_orders <- NA
    on_time_pct <- NA
  }

  return(list(
    total_orders = total_orders,
    completed_orders = completed_orders,
    completion_rate_pct = completion_rate_pct,
    failed_orders = failed_orders,
    failure_rate_pct = failure_rate_pct,
    refunded_orders = refunded_orders,
    refund_rate_pct = refund_rate_pct,
    on_time_orders = on_time_orders,
    on_time_delivery_pct = on_time_pct
  ))
}


#' Calculate Operational Efficiency Metrics
#'
#' Calculates efficiency metrics including throughput, cycle time, and productivity.
#'
#' @param orders Data frame of orders
#' @param config Configuration list
#' @param simulation_results Full simulation results
#'
#' @return List with efficiency metrics
#' @export
calculate_efficiency_metrics <- function(orders, config, simulation_results) {

  num_orders <- nrow(orders)
  simulation_duration_days <- config$simulation$duration_days

  # Throughput (orders per day)
  orders_per_day <- num_orders / simulation_duration_days
  orders_per_week <- orders_per_day * 7

  # Average cycle time (placement to delivery)
  if ("placement_time" %in% colnames(orders) && "delivery_actual_time" %in% colnames(orders)) {
    cycle_times_hours <- as.numeric(difftime(
      orders$delivery_actual_time,
      orders$placement_time,
      units = "hours"
    ))
    avg_cycle_time_hours <- mean(cycle_times_hours, na.rm = TRUE)
    median_cycle_time_hours <- median(cycle_times_hours, na.rm = TRUE)
  } else {
    avg_cycle_time_hours <- NA
    median_cycle_time_hours <- NA
  }

  # Orders per resource
  num_vans <- config$capacity$num_vans
  num_drivers <- config$capacity$num_drivers
  num_wash_machines <- config$capacity$num_wash_machines
  num_dry_machines <- config$capacity$num_dry_machines

  orders_per_van <- num_orders / num_vans
  orders_per_driver <- num_orders / num_drivers
  orders_per_wash_machine <- sum(grepl("wash", orders$service_type)) / num_wash_machines
  orders_per_dry_machine <- sum(grepl("dry", orders$service_type)) / num_dry_machines

  # Total kg processed
  total_kg_processed <- sum(orders$kg_estimate)
  kg_per_day <- total_kg_processed / simulation_duration_days

  return(list(
    throughput = list(
      orders_per_day = orders_per_day,
      orders_per_week = orders_per_week,
      total_orders = num_orders
    ),
    cycle_time = list(
      avg_hours = avg_cycle_time_hours,
      median_hours = median_cycle_time_hours
    ),
    productivity = list(
      orders_per_van = orders_per_van,
      orders_per_driver = orders_per_driver,
      orders_per_wash_machine = orders_per_wash_machine,
      orders_per_dry_machine = orders_per_dry_machine
    ),
    volume = list(
      total_kg = total_kg_processed,
      kg_per_day = kg_per_day,
      avg_kg_per_order = total_kg_processed / num_orders
    )
  ))
}


#' Calculate Complete Operational Summary
#'
#' Master function that calculates all operational metrics from simulation results.
#'
#' @param simulation_results List from run_simulation
#' @param config Configuration list
#'
#' @return List with complete operational analysis
#' @export
calculate_operational_summary <- function(simulation_results, config) {

  orders <- simulation_results$orders
  capacity_log <- simulation_results$capacity_log

  # Calculate all components
  utilization <- calculate_resource_utilization(capacity_log, config, simulation_results)
  bottlenecks <- identify_bottlenecks(utilization)
  service_metrics <- calculate_service_metrics(orders)
  efficiency <- calculate_efficiency_metrics(orders, config, simulation_results)

  return(list(
    utilization = utilization,
    bottlenecks = bottlenecks,
    service_metrics = service_metrics,
    efficiency = efficiency,
    summary = list(
      primary_bottleneck = bottlenecks$primary_bottleneck,
      bottleneck_utilization = bottlenecks$primary_bottleneck_utilization,
      completion_rate = service_metrics$completion_rate_pct,
      orders_per_day = efficiency$throughput$orders_per_day,
      avg_cycle_time_hours = efficiency$cycle_time$avg_hours
    )
  ))
}


#' Compare Multiple Scenarios
#'
#' Compares financial and operational metrics across different simulation scenarios.
#'
#' @param scenario_results List of lists, each containing simulation results and config
#'   Each element should have: list(results = simulation_results, config = config, name = "scenario_name")
#'
#' @return Data frame comparing scenarios
#' @export
compare_scenarios <- function(scenario_results) {

  num_scenarios <- length(scenario_results)

  # Initialize comparison data frame
  comparison <- data.frame(
    scenario = character(num_scenarios),
    revenue = numeric(num_scenarios),
    costs = numeric(num_scenarios),
    profit = numeric(num_scenarios),
    margin_pct = numeric(num_scenarios),
    orders = numeric(num_scenarios),
    orders_per_day = numeric(num_scenarios),
    breakeven_orders = numeric(num_scenarios),
    primary_bottleneck = character(num_scenarios),
    bottleneck_utilization = numeric(num_scenarios),
    stringsAsFactors = FALSE
  )

  # Calculate metrics for each scenario
  for (i in 1:num_scenarios) {
    scenario <- scenario_results[[i]]
    results <- scenario$results
    config <- scenario$config
    name <- scenario$name

    # Calculate financial and operational metrics
    financial <- calculate_financial_summary(results, config)
    operational <- calculate_operational_summary(results, config)

    # Populate comparison
    comparison$scenario[i] <- name
    comparison$revenue[i] <- financial$summary$total_revenue
    comparison$costs[i] <- financial$summary$total_costs
    comparison$profit[i] <- financial$summary$gross_profit
    comparison$margin_pct[i] <- financial$summary$gross_margin_pct
    comparison$orders[i] <- nrow(results$orders)
    comparison$orders_per_day[i] <- operational$summary$orders_per_day
    comparison$breakeven_orders[i] <- financial$summary$breakeven_orders
    comparison$primary_bottleneck[i] <- operational$summary$primary_bottleneck
    comparison$bottleneck_utilization[i] <- operational$summary$bottleneck_utilization
  }

  # Add delta columns (difference from first scenario)
  if (num_scenarios > 1) {
    comparison$revenue_delta_pct <- ((comparison$revenue / comparison$revenue[1]) - 1) * 100
    comparison$profit_delta_pct <- ((comparison$profit / comparison$profit[1]) - 1) * 100
    comparison$orders_delta_pct <- ((comparison$orders / comparison$orders[1]) - 1) * 100
  }

  return(comparison)
}
