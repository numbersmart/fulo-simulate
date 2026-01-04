# financial.R - Financial Calculations Module
#
# This module calculates revenue, costs, profit/loss, and break-even analysis
# from simulation results.
#
# Phase: 5 - Financial & Operational Metrics

#' Calculate Revenue from Orders
#'
#' Calculates total revenue based on orders and pricing configuration,
#' applying subscription discounts and self-check discounts as applicable.
#'
#' @param orders Data frame of orders with service_type, is_subscription, self_check_enabled
#' @param config List containing pricing parameters
#'
#' @return List with detailed revenue breakdown
#' @export
calculate_revenue <- function(orders, config) {

  # Extract pricing parameters
  wash_price <- config$pricing$wash_price
  dry_price <- config$pricing$dry_price
  self_check_discount <- config$pricing$self_check_discount
  subscription_discount_pct <- config$pricing$subscription_discount_pct

  # Calculate base revenue per order based on service type
  orders$base_revenue <- 0

  # Wash + Dry service
  wash_dry_mask <- orders$service_type == "wash_dry"
  orders$base_revenue[wash_dry_mask] <- wash_price + dry_price

  # Wash only service
  wash_only_mask <- orders$service_type == "wash_only"
  orders$base_revenue[wash_only_mask] <- wash_price

  # Dry only service
  dry_only_mask <- orders$service_type == "dry_only"
  orders$base_revenue[dry_only_mask] <- dry_price

  # Apply self-check discount (flat amount)
  orders$self_check_discount_amount <- ifelse(orders$self_check_enabled,
                                               self_check_discount,
                                               0)

  # Calculate revenue after self-check discount
  orders$revenue_after_self_check <- orders$base_revenue - orders$self_check_discount_amount

  # Apply subscription discount (percentage)
  orders$subscription_discount_amount <- ifelse(orders$is_subscription,
                                                 orders$revenue_after_self_check * subscription_discount_pct,
                                                 0)

  # Final revenue per order
  orders$final_revenue <- orders$revenue_after_self_check - orders$subscription_discount_amount

  # Handle refunds if present
  if ("is_refunded" %in% colnames(orders)) {
    orders$final_revenue[orders$is_refunded] <- 0
  }

  # Calculate aggregates
  total_revenue <- sum(orders$final_revenue)
  total_base_revenue <- sum(orders$base_revenue)
  total_discounts <- sum(orders$self_check_discount_amount + orders$subscription_discount_amount)

  # Revenue by service type
  revenue_by_service <- data.frame(
    service_type = c("wash_dry", "wash_only", "dry_only"),
    revenue = c(
      sum(orders$final_revenue[wash_dry_mask]),
      sum(orders$final_revenue[wash_only_mask]),
      sum(orders$final_revenue[dry_only_mask])
    ),
    order_count = c(
      sum(wash_dry_mask),
      sum(wash_only_mask),
      sum(dry_only_mask)
    ),
    stringsAsFactors = FALSE
  )
  revenue_by_service$avg_revenue_per_order <- revenue_by_service$revenue / revenue_by_service$order_count

  # Revenue by customer segment
  revenue_by_segment <- data.frame(
    segment = c("subscription", "non_subscription", "self_check", "non_self_check"),
    revenue = c(
      sum(orders$final_revenue[orders$is_subscription]),
      sum(orders$final_revenue[!orders$is_subscription]),
      sum(orders$final_revenue[orders$self_check_enabled]),
      sum(orders$final_revenue[!orders$self_check_enabled])
    ),
    order_count = c(
      sum(orders$is_subscription),
      sum(!orders$is_subscription),
      sum(orders$self_check_enabled),
      sum(!orders$self_check_enabled)
    ),
    stringsAsFactors = FALSE
  )
  revenue_by_segment$avg_revenue_per_order <- revenue_by_segment$revenue / revenue_by_segment$order_count

  return(list(
    total_revenue = total_revenue,
    total_base_revenue = total_base_revenue,
    total_discounts = total_discounts,
    avg_revenue_per_order = total_revenue / nrow(orders),
    revenue_by_service = revenue_by_service,
    revenue_by_segment = revenue_by_segment,
    orders_with_revenue = orders
  ))
}


#' Calculate Operational Costs
#'
#' Calculates costs for washing, drying, and overhead from simulation results.
#' ASSUMPTION: Costs scale linearly with kg processed
#'
#' @param orders Data frame of orders with kg_estimate and service_type
#' @param config List containing cost parameters
#'
#' @return List with detailed cost breakdown
#' @export
calculate_operational_costs <- function(orders, config) {

  # Extract cost parameters
  cost_per_kg_wash <- config$costs$cost_per_kg_wash
  cost_per_kg_dry <- config$costs$cost_per_kg_dry
  overhead_per_week <- config$costs$overhead_per_week

  # Duration of simulation in weeks
  simulation_duration_days <- config$simulation$duration_days
  simulation_duration_weeks <- simulation_duration_days / 7

  # Calculate washing costs
  wash_mask <- grepl("wash", orders$service_type)
  wash_kg <- sum(orders$kg_estimate[wash_mask])
  wash_cost <- wash_kg * cost_per_kg_wash

  # Calculate drying costs
  dry_mask <- grepl("dry", orders$service_type)
  dry_kg <- sum(orders$kg_estimate[dry_mask])
  dry_cost <- dry_kg * cost_per_kg_dry

  # Overhead (fixed cost)
  overhead_cost <- overhead_per_week * simulation_duration_weeks

  # Total operational cost
  total_operational_cost <- wash_cost + dry_cost + overhead_cost

  return(list(
    wash_cost = wash_cost,
    wash_kg = wash_kg,
    dry_cost = dry_cost,
    dry_kg = dry_kg,
    overhead_cost = overhead_cost,
    total_operational_cost = total_operational_cost,
    cost_per_order = total_operational_cost / nrow(orders)
  ))
}


#' Calculate Delivery Costs
#'
#' Calculates delivery costs based on route metrics including driver time and fuel.
#' Requires capacity_log from simulation results.
#'
#' @param capacity_log Data frame with route assignments and times
#' @param orders Data frame of orders
#' @param config List containing cost parameters
#'
#' @return List with delivery cost breakdown
#' @export
calculate_delivery_costs <- function(capacity_log, orders, config) {

  # Extract cost parameters
  driver_hourly_rate <- config$costs$driver_hourly_rate
  fuel_per_km <- config$costs$fuel_per_km

  # ASSUMPTION: If capacity_log doesn't have route data, estimate from orders
  # This is a simplified calculation - full implementation would use actual route metrics

  # Estimate based on number of orders and average route characteristics
  num_orders <- nrow(orders)

  # ASSUMPTION: Average pickup route has 5 stops, takes 2 hours including driving
  # Average delivery route has 5 stops, takes 2 hours
  avg_stops_per_route <- 5
  num_pickup_routes <- ceiling(num_orders / avg_stops_per_route)
  num_delivery_routes <- num_pickup_routes  # Same number

  hours_per_route <- 2
  total_driver_hours <- (num_pickup_routes + num_delivery_routes) * hours_per_route
  driver_cost <- total_driver_hours * driver_hourly_rate

  # ASSUMPTION: Average route distance is 20km (pickup + delivery round trip)
  km_per_route <- 20
  total_km <- (num_pickup_routes + num_delivery_routes) * km_per_route
  fuel_cost <- total_km * fuel_per_km

  total_delivery_cost <- driver_cost + fuel_cost

  return(list(
    driver_cost = driver_cost,
    driver_hours = total_driver_hours,
    fuel_cost = fuel_cost,
    total_km = total_km,
    total_delivery_cost = total_delivery_cost,
    num_pickup_routes = num_pickup_routes,
    num_delivery_routes = num_delivery_routes,
    cost_per_order = total_delivery_cost / num_orders
  ))
}


#' Calculate Total Costs
#'
#' Aggregates all cost categories into total cost.
#'
#' @param operational_costs List from calculate_operational_costs
#' @param delivery_costs List from calculate_delivery_costs
#'
#' @return List with total cost breakdown
#' @export
calculate_total_costs <- function(operational_costs, delivery_costs) {

  total_costs <- operational_costs$total_operational_cost + delivery_costs$total_delivery_cost

  return(list(
    operational_cost = operational_costs$total_operational_cost,
    delivery_cost = delivery_costs$total_delivery_cost,
    total_cost = total_costs,
    breakdown = list(
      wash = operational_costs$wash_cost,
      dry = operational_costs$dry_cost,
      overhead = operational_costs$overhead_cost,
      driver = delivery_costs$driver_cost,
      fuel = delivery_costs$fuel_cost
    )
  ))
}


#' Calculate Profit and Loss
#'
#' Computes P&L statement from revenue and costs.
#'
#' @param revenue_results List from calculate_revenue
#' @param cost_results List from calculate_total_costs
#'
#' @return List with P&L metrics
#' @export
calculate_profit_loss <- function(revenue_results, cost_results) {

  revenue <- revenue_results$total_revenue
  costs <- cost_results$total_cost

  gross_profit <- revenue - costs
  gross_margin_pct <- (gross_profit / revenue) * 100

  return(list(
    revenue = revenue,
    total_costs = costs,
    gross_profit = gross_profit,
    gross_margin_pct = gross_margin_pct,
    is_profitable = gross_profit > 0
  ))
}


#' Calculate Break-even Analysis
#'
#' Determines break-even point and sensitivity to key parameters.
#' ASSUMPTION: Fixed costs include overhead, variable costs scale with orders
#'
#' @param revenue_results List from calculate_revenue
#' @param cost_results List from calculate_total_costs
#' @param config Configuration list
#'
#' @return List with break-even metrics
#' @export
calculate_breakeven <- function(revenue_results, cost_results, config) {

  num_orders <- nrow(revenue_results$orders_with_revenue)

  # Revenue per order (average)
  revenue_per_order <- revenue_results$avg_revenue_per_order

  # Variable cost per order (wash + dry + delivery)
  operational_cost_per_order <- (cost_results$breakdown$wash + cost_results$breakdown$dry) / num_orders
  delivery_cost_per_order <- (cost_results$breakdown$driver + cost_results$breakdown$fuel) / num_orders
  variable_cost_per_order <- operational_cost_per_order + delivery_cost_per_order

  # Fixed costs (overhead)
  fixed_costs <- cost_results$breakdown$overhead

  # Contribution margin per order
  contribution_margin <- revenue_per_order - variable_cost_per_order

  # Break-even orders
  if (contribution_margin > 0) {
    breakeven_orders <- ceiling(fixed_costs / contribution_margin)

    # Break-even in simulation period
    simulation_duration_days <- config$simulation$duration_days
    breakeven_orders_per_day <- breakeven_orders / simulation_duration_days
  } else {
    breakeven_orders <- Inf
    breakeven_orders_per_day <- Inf
  }

  # Current vs break-even
  orders_per_day <- num_orders / config$simulation$duration_days
  orders_above_breakeven <- num_orders - breakeven_orders

  return(list(
    fixed_costs = fixed_costs,
    variable_cost_per_order = variable_cost_per_order,
    revenue_per_order = revenue_per_order,
    contribution_margin_per_order = contribution_margin,
    contribution_margin_pct = (contribution_margin / revenue_per_order) * 100,
    breakeven_orders = breakeven_orders,
    breakeven_orders_per_day = breakeven_orders_per_day,
    actual_orders = num_orders,
    actual_orders_per_day = orders_per_day,
    orders_above_breakeven = orders_above_breakeven,
    is_above_breakeven = num_orders >= breakeven_orders
  ))
}


#' Calculate Complete Financial Summary
#'
#' Master function that calculates all financial metrics from simulation results.
#'
#' @param simulation_results List from run_simulation
#' @param config Configuration list
#'
#' @return List with complete financial analysis
#' @export
calculate_financial_summary <- function(simulation_results, config) {

  orders <- simulation_results$orders
  capacity_log <- simulation_results$capacity_log

  # Calculate all components
  revenue <- calculate_revenue(orders, config)
  operational_costs <- calculate_operational_costs(orders, config)
  delivery_costs <- calculate_delivery_costs(capacity_log, orders, config)
  total_costs <- calculate_total_costs(operational_costs, delivery_costs)
  profit_loss <- calculate_profit_loss(revenue, total_costs)
  breakeven <- calculate_breakeven(revenue, total_costs, config)

  return(list(
    revenue = revenue,
    operational_costs = operational_costs,
    delivery_costs = delivery_costs,
    total_costs = total_costs,
    profit_loss = profit_loss,
    breakeven = breakeven,
    summary = list(
      total_revenue = revenue$total_revenue,
      total_costs = total_costs$total_cost,
      gross_profit = profit_loss$gross_profit,
      gross_margin_pct = profit_loss$gross_margin_pct,
      breakeven_orders = breakeven$breakeven_orders,
      is_profitable = profit_loss$is_profitable
    )
  ))
}
