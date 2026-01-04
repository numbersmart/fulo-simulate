#' Core Simulation Engine for Fulo Operations
#'
#' This module contains the core simulation logic that models the complete
#' order lifecycle from placement through delivery.
#'
#' Key workflow stages:
#' 1. Order Placement
#' 2. Pickup Scheduling
#' 3. Pickup Execution
#' 4. Intake/Scanning at laundromat
#' 5. Washing
#' 6. Drying
#' 7. Folding
#' 8. Delivery Scheduling
#' 9. Delivery Execution
#'
#' @author Fulo Simulate Team
#' @date 2026-01-02

library(dplyr)
library(lubridate)

# Constants ----

# Time constants (in minutes)
# ASSUMPTION: Based on industry standards for commercial laundry operations
PICKUP_TIME_PER_STOP_MIN <- 15       # Average time per pickup stop
DELIVERY_TIME_PER_STOP_MIN <- 15     # Average time per delivery stop
INTAKE_TIME_PER_ITEM_MIN <- 2        # Time to scan and process each item
WASH_TIME_BASE_MIN <- 30             # Minimum washing time
WASH_TIME_PER_KG_MIN <- 3            # Additional time per kg
DRY_TIME_BASE_MIN <- 40              # Minimum drying time
DRY_TIME_PER_KG_MIN <- 2             # Additional time per kg
FOLDING_TIME_PER_KG_MIN <- 1.5       # Time to fold per kg

# Capacity constants
ITEMS_PER_WASH_LOAD <- 15            # Typical items per washing machine load
ITEMS_PER_DRY_LOAD <- 15             # Typical items per dryer load


# Main Simulation Function ----

#' Run Complete Simulation
#'
#' Executes the full simulation workflow: generate orders, process through
#' lifecycle, calculate metrics, identify bottlenecks.
#'
#' This is the main entry point for running a simulation. It coordinates
#' all subsystems and returns comprehensive results.
#'
#' ASSUMPTIONS:
#' - Orders must complete within 24-48 hour window
#' - Capacity constraints are strictly enforced (no overbooking)
#' - Processing happens in FIFO (first-in-first-out) order within each queue
#'
#' @param config List containing all configuration parameters
#' @param random_seed Integer random seed for reproducibility
#'
#' @return List containing:
#'   - orders: Data frame of all orders with complete lifecycle
#'   - capacity_log: History of capacity utilization
#'   - bottlenecks: Identified bottlenecks and constraints
#'   - summary_stats: High-level statistics
#' @export
#'
#' @examples
#' config <- load_config("configs/realistic.json")
#' results <- run_simulation(config, random_seed = 42)
#' print(results$summary_stats)
run_simulation <- function(config, random_seed = 42) {
  message("Starting simulation...")
  message("  Random seed: ", random_seed)
  set.seed(random_seed)

  # Initialize capacity state
  capacity_state <- initialize_capacity_state(config)

  # Generate orders using realistic demand modeling with capacity-aware booking
  booking_result <- generate_orders(config, random_seed)
  orders <- booking_result$booked_orders
  message("  Booked ", nrow(orders), " orders (", booking_result$orders_missed, " missed)")

  # Initialize order tracking columns
  # Pre-initialize ALL columns that will be used during simulation to avoid column mismatch
  orders$status <- "placed"
  orders$current_stage_start <- orders$placement_time
  orders$pickup_time_actual <- as.POSIXct(NA)
  orders$assigned_van <- NA_integer_
  orders$assigned_driver <- NA_integer_
  orders$pickup_completed_time <- as.POSIXct(NA)
  orders$wash_start_time <- as.POSIXct(NA)
  orders$wash_end_time <- as.POSIXct(NA)
  orders$assigned_wash_machine <- NA_integer_
  orders$dry_start_time <- as.POSIXct(NA)
  orders$dry_end_time <- as.POSIXct(NA)
  orders$assigned_dry_machine <- NA_integer_
  orders$folding_end_time <- as.POSIXct(NA)
  orders$delivery_time_scheduled <- as.POSIXct(NA)
  orders$delivery_time_actual <- as.POSIXct(NA)
  orders$total_time_hours <- NA_real_

  # Create event queue (all events to be processed)
  event_queue <- create_initial_event_queue(orders)

  # Process events chronologically
  processed_orders <- process_event_queue(
    event_queue,
    orders,
    capacity_state,
    config
  )

  # Identify bottlenecks
  bottlenecks <- identify_bottlenecks(capacity_state, config)

  # Calculate summary statistics
  summary_stats <- calculate_summary_stats(processed_orders, capacity_state)

  message("Simulation complete!")
  message("  Orders processed: ", nrow(processed_orders))
  message("  Bottlenecks found: ", length(bottlenecks))
  message("  Demand capture: ", booking_result$orders_booked, "/", booking_result$total_demand,
          " (", sprintf("%.1f%%", (1 - booking_result$abandonment_rate) * 100), " conversion)")

  return(list(
    orders = processed_orders,
    capacity_log = capacity_state$log,
    bottlenecks = bottlenecks,
    summary_stats = summary_stats,
    # Booking statistics (missed orders / demand capture)
    booking_stats = list(
      total_demand = booking_result$total_demand,
      orders_booked = booking_result$orders_booked,
      orders_missed = booking_result$orders_missed,
      abandonment_rate = booking_result$abandonment_rate,
      abandonment_reasons = booking_result$abandonment_reasons,
      missed_orders = booking_result$missed_orders
    )
  ))
}


# Capacity Management ----

#' Initialize Capacity State
#'
#' Creates the initial capacity tracking structure for all resources.
#'
#' @param config List containing capacity configuration
#'
#' @return List tracking available capacity for all resources
initialize_capacity_state <- function(config) {
  list(
    vans_available = config$capacity$num_vans,
    vans_total = config$capacity$num_vans,
    drivers_available = config$capacity$num_drivers,
    drivers_total = config$capacity$num_drivers,
    wash_machines_available = config$capacity$num_wash_machines,
    wash_machines_total = config$capacity$num_wash_machines,
    dry_machines_available = config$capacity$num_dry_machines,
    dry_machines_total = config$capacity$num_dry_machines,

    # Track when resources become available again
    van_availability = rep(as.POSIXct(Sys.time()), config$capacity$num_vans),
    driver_availability = rep(as.POSIXct(Sys.time()), config$capacity$num_drivers),
    wash_availability = rep(as.POSIXct(Sys.time()), config$capacity$num_wash_machines),
    dry_availability = rep(as.POSIXct(Sys.time()), config$capacity$num_dry_machines),

    # Logging for analysis
    log = list(),
    queue_log = list()
  )
}


#' Check Resource Availability
#'
#' Checks if a specific resource is available at a given time.
#'
#' @param capacity_state List tracking current capacity
#' @param resource_type Character: "van", "driver", "wash", or "dry"
#' @param required_time POSIXct time when resource is needed
#'
#' @return List with available (logical), resource_id (if available), and next_available_time
check_resource_availability <- function(capacity_state, resource_type, required_time) {
  availability_vec <- switch(resource_type,
    van = capacity_state$van_availability,
    driver = capacity_state$driver_availability,
    wash = capacity_state$wash_availability,
    dry = capacity_state$dry_availability
  )

  # Find first resource that's available before required_time
  available_idx <- which(availability_vec <= required_time)

  if (length(available_idx) > 0) {
    return(list(
      available = TRUE,
      resource_id = available_idx[1],
      next_available_time = NULL
    ))
  } else {
    # Return when the earliest resource will be available
    earliest_time <- min(availability_vec)
    return(list(
      available = FALSE,
      resource_id = NA,
      next_available_time = earliest_time
    ))
  }
}


#' Reserve Resource
#'
#' Marks a resource as in-use until a specified end time.
#'
#' @param capacity_state List tracking current capacity
#' @param resource_type Character: "van", "driver", "wash", or "dry"
#' @param resource_id Integer ID of specific resource
#' @param end_time POSIXct when resource will be available again
#'
#' @return Updated capacity_state
reserve_resource <- function(capacity_state, resource_type, resource_id, end_time) {
  if (resource_type == "van") {
    capacity_state$van_availability[resource_id] <- end_time
  } else if (resource_type == "driver") {
    capacity_state$driver_availability[resource_id] <- end_time
  } else if (resource_type == "wash") {
    capacity_state$wash_availability[resource_id] <- end_time
  } else if (resource_type == "dry") {
    capacity_state$dry_availability[resource_id] <- end_time
  }

  # Log reservation
  capacity_state$log[[length(capacity_state$log) + 1]] <- list(
    time = Sys.time(),
    resource_type = resource_type,
    resource_id = resource_id,
    available_until = end_time
  )

  return(capacity_state)
}


# Event Queue Processing ----

#' Create Initial Event Queue
#'
#' Creates the initial event queue from orders.
#'
#' @param orders Data frame of orders
#'
#' @return Data frame of events to be processed
create_initial_event_queue <- function(orders) {
  # Each order starts with a "schedule_pickup" event
  events <- data.frame(
    event_time = orders$preferred_pickup_time,
    event_type = "schedule_pickup",
    order_id = orders$order_id,
    stringsAsFactors = FALSE
  )

  # Sort by time
  events <- events[order(events$event_time), ]
  rownames(events) <- NULL

  return(events)
}


#' Process Event Queue
#'
#' Main simulation loop that processes events chronologically.
#'
#' @param event_queue Data frame of events to process
#' @param orders Data frame of orders
#' @param capacity_state List tracking capacity
#' @param config Configuration list
#'
#' @return Updated orders data frame with complete lifecycle
process_event_queue <- function(event_queue, orders, capacity_state, config) {
  message("Processing ", nrow(event_queue), " initial events...")

  MAX_ITERATIONS <- 100000  # Safety limit to prevent infinite loops
  iteration <- 0
  progress_interval <- 1000

  while (nrow(event_queue) > 0) {
    iteration <- iteration + 1

    # Safety check for infinite loops
    if (iteration > MAX_ITERATIONS) {
      warning(sprintf("Reached maximum iteration limit (%d). Possible infinite loop detected.", MAX_ITERATIONS))
      warning(sprintf("Remaining events in queue: %d", nrow(event_queue)))
      break
    }

    # Progress reporting
    if (iteration %% progress_interval == 0) {
      message(sprintf("  Processed %d events, %d remaining in queue", iteration, nrow(event_queue)))
    }

    # Get next event
    event <- event_queue[1, ]
    event_queue <- event_queue[-1, , drop = FALSE]

    # Process based on event type
    result <- process_event(event, orders, capacity_state, config)

    # Update orders and capacity
    orders <- result$orders
    capacity_state <- result$capacity_state

    # Add any new events generated
    if (!is.null(result$new_events) && nrow(result$new_events) > 0) {
      event_queue <- rbind(event_queue, result$new_events)
      event_queue <- event_queue[order(event_queue$event_time), ]
    }
  }

  message(sprintf("All events processed (total iterations: %d)", iteration))
  return(orders)
}


#' Process Single Event
#'
#' Handles a single event and updates state accordingly.
#'
#' @param event Single row data frame with event details
#' @param orders Data frame of all orders
#' @param capacity_state Capacity tracking state
#' @param config Configuration
#'
#' @return List with updated orders, capacity_state, and new_events
process_event <- function(event, orders, capacity_state, config) {
  order_idx <- which(orders$order_id == event$order_id)
  order <- orders[order_idx, ]

  new_events <- data.frame()

  if (event$event_type == "schedule_pickup") {
    result <- handle_pickup_scheduling(event, order, capacity_state, config)
  } else if (event$event_type == "execute_pickup") {
    result <- handle_pickup_execution(event, order, capacity_state, config)
  } else if (event$event_type == "start_washing") {
    result <- handle_washing(event, order, capacity_state, config)
  } else if (event$event_type == "start_drying") {
    result <- handle_drying(event, order, capacity_state, config)
  } else if (event$event_type == "start_folding") {
    result <- handle_folding(event, order, capacity_state, config)
  } else if (event$event_type == "schedule_delivery") {
    result <- handle_delivery_scheduling(event, order, capacity_state, config)
  } else if (event$event_type == "execute_delivery") {
    result <- handle_delivery_execution(event, order, capacity_state, config)
  }

  # Update the order in the orders data frame
  orders[order_idx, ] <- result$order

  return(list(
    orders = orders,
    capacity_state = result$capacity_state,
    new_events = result$new_events
  ))
}


# Event Handlers ----

#' Handle Pickup Scheduling Event
#'
#' Schedules a pickup when van and driver are available.
#'
#' @param event Event details
#' @param order Order being processed
#' @param capacity_state Capacity tracking
#' @param config Configuration
#'
#' @return List with updated order, capacity_state, and new_events
handle_pickup_scheduling <- function(event, order, capacity_state, config) {
  # Check if van and driver available
  van_check <- check_resource_availability(capacity_state, "van", event$event_time)
  driver_check <- check_resource_availability(capacity_state, "driver", event$event_time)

  if (van_check$available && driver_check$available) {
    # Schedule pickup
    pickup_duration_min <- PICKUP_TIME_PER_STOP_MIN
    pickup_end_time <- event$event_time + minutes(as.integer(pickup_duration_min))

    # Reserve resources
    capacity_state <- reserve_resource(capacity_state, "van", van_check$resource_id, pickup_end_time)
    capacity_state <- reserve_resource(capacity_state, "driver", driver_check$resource_id, pickup_end_time)

    # Update order
    order$status <- "pickup_scheduled"
    order$pickup_time_actual <- event$event_time
    order$assigned_van <- van_check$resource_id
    order$assigned_driver <- driver_check$resource_id

    # Create next event: execute pickup
    new_events <- data.frame(
      event_time = pickup_end_time,
      event_type = "execute_pickup",
      order_id = order$order_id
    )
  } else {
    # Queue for later - schedule for when resources will actually be available
    # Find the later of the two next available times (need both van AND driver)
    next_van_time <- if (!van_check$available) van_check$next_available_time else event$event_time
    next_driver_time <- if (!driver_check$available) driver_check$next_available_time else event$event_time
    next_available <- max(next_van_time, next_driver_time)

    new_events <- data.frame(
      event_time = next_available,
      event_type = "schedule_pickup",
      order_id = order$order_id
    )

    # Log queuing
    capacity_state$queue_log[[length(capacity_state$queue_log) + 1]] <- list(
      time = event$event_time,
      order_id = order$order_id,
      reason = "van_or_driver_unavailable",
      rescheduled_for = next_available
    )
  }

  return(list(
    order = order,
    capacity_state = capacity_state,
    new_events = new_events
  ))
}


#' Handle Pickup Execution Event
#'
#' Completes pickup and moves order to washing queue.
#'
#' @param event Event details
#' @param order Order being processed
#' @param capacity_state Capacity tracking
#' @param config Configuration
#'
#' @return List with updated order, capacity_state, and new_events
handle_pickup_execution <- function(event, order, capacity_state, config) {
  # Update order status
  order$status <- "picked_up"
  order$pickup_completed_time <- event$event_time

  # Create next event: start washing
  # ASSUMPTION: Intake/scanning happens immediately upon arrival at laundromat
  intake_duration_min <- INTAKE_TIME_PER_ITEM_MIN * 5  # Assume 5 items average
  intake_end_time <- event$event_time + minutes(as.integer(intake_duration_min))

  new_events <- data.frame(
    event_time = intake_end_time,
    event_type = "start_washing",
    order_id = order$order_id
  )

  return(list(
    order = order,
    capacity_state = capacity_state,
    new_events = new_events
  ))
}


#' Handle Washing Event
#'
#' Processes washing if machine available.
#'
#' @param event Event details
#' @param order Order being processed
#' @param capacity_state Capacity tracking
#' @param config Configuration
#'
#' @return List with updated order, capacity_state, and new_events
handle_washing <- function(event, order, capacity_state, config) {
  # Check if order needs washing
  if (!grepl("wash", order$service_type)) {
    # Skip to drying
    new_events <- data.frame(
      event_time = event$event_time,
      event_type = "start_drying",
      order_id = order$order_id
    )
    return(list(order = order, capacity_state = capacity_state, new_events = new_events))
  }

  # Check wash machine availability
  wash_check <- check_resource_availability(capacity_state, "wash", event$event_time)

  if (wash_check$available) {
    # Calculate wash duration based on weight
    wash_duration_min <- WASH_TIME_BASE_MIN + (order$kg_estimate * WASH_TIME_PER_KG_MIN)
    wash_end_time <- event$event_time + minutes(as.integer(wash_duration_min))

    # Reserve machine
    capacity_state <- reserve_resource(capacity_state, "wash", wash_check$resource_id, wash_end_time)

    # Update order
    order$status <- "washing"
    order$wash_start_time <- event$event_time
    order$wash_end_time <- wash_end_time
    order$assigned_wash_machine <- wash_check$resource_id

    # Create next event: start drying (if needed) or folding
    if (grepl("dry", order$service_type)) {
      new_events <- data.frame(
        event_time = wash_end_time,
        event_type = "start_drying",
        order_id = order$order_id
      )
    } else {
      new_events <- data.frame(
        event_time = wash_end_time,
        event_type = "start_folding",
        order_id = order$order_id
      )
    }
  } else {
    # Queue for later - schedule for when machine will actually be available
    new_events <- data.frame(
      event_time = wash_check$next_available_time,
      event_type = "start_washing",
      order_id = order$order_id
    )

    capacity_state$queue_log[[length(capacity_state$queue_log) + 1]] <- list(
      time = event$event_time,
      order_id = order$order_id,
      reason = "wash_machine_unavailable",
      rescheduled_for = wash_check$next_available_time
    )
  }

  return(list(
    order = order,
    capacity_state = capacity_state,
    new_events = new_events
  ))
}


#' Handle Drying Event
#'
#' Processes drying if machine available.
#'
#' @param event Event details
#' @param order Order being processed
#' @param capacity_state Capacity tracking
#' @param config Configuration
#'
#' @return List with updated order, capacity_state, and new_events
handle_drying <- function(event, order, capacity_state, config) {
  # Check if order needs drying
  if (!grepl("dry", order$service_type)) {
    # Skip to folding
    new_events <- data.frame(
      event_time = event$event_time,
      event_type = "start_folding",
      order_id = order$order_id
    )
    return(list(order = order, capacity_state = capacity_state, new_events = new_events))
  }

  # Check dry machine availability
  dry_check <- check_resource_availability(capacity_state, "dry", event$event_time)

  if (dry_check$available) {
    # Calculate dry duration
    dry_duration_min <- DRY_TIME_BASE_MIN + (order$kg_estimate * DRY_TIME_PER_KG_MIN)
    dry_end_time <- event$event_time + minutes(as.integer(dry_duration_min))

    # Reserve machine
    capacity_state <- reserve_resource(capacity_state, "dry", dry_check$resource_id, dry_end_time)

    # Update order
    order$status <- "drying"
    order$dry_start_time <- event$event_time
    order$dry_end_time <- dry_end_time
    order$assigned_dry_machine <- dry_check$resource_id

    # Create next event: folding
    new_events <- data.frame(
      event_time = dry_end_time,
      event_type = "start_folding",
      order_id = order$order_id
    )
  } else {
    # Queue for later - schedule for when machine will actually be available
    new_events <- data.frame(
      event_time = dry_check$next_available_time,
      event_type = "start_drying",
      order_id = order$order_id
    )

    capacity_state$queue_log[[length(capacity_state$queue_log) + 1]] <- list(
      time = event$event_time,
      order_id = order$order_id,
      reason = "dry_machine_unavailable",
      rescheduled_for = dry_check$next_available_time
    )
  }

  return(list(
    order = order,
    capacity_state = capacity_state,
    new_events = new_events
  ))
}


#' Handle Folding Event
#'
#' Processes folding (no capacity constraint, done manually).
#'
#' @param event Event details
#' @param order Order being processed
#' @param capacity_state Capacity tracking
#' @param config Configuration
#'
#' @return List with updated order, capacity_state, and new_events
handle_folding <- function(event, order, capacity_state, config) {
  # ASSUMPTION: Folding has no capacity constraint (workers can fold anytime)
  folding_duration_min <- order$kg_estimate * FOLDING_TIME_PER_KG_MIN
  folding_end_time <- event$event_time + minutes(as.integer(folding_duration_min))

  # Update order
  order$status <- "folded"
  order$folding_end_time <- folding_end_time

  # Create next event: schedule delivery
  new_events <- data.frame(
    event_time = folding_end_time,
    event_type = "schedule_delivery",
    order_id = order$order_id
  )

  return(list(
    order = order,
    capacity_state = capacity_state,
    new_events = new_events
  ))
}


#' Handle Delivery Scheduling Event
#'
#' Schedules delivery when van and driver available.
#'
#' @param event Event details
#' @param order Order being processed
#' @param capacity_state Capacity tracking
#' @param config Configuration
#'
#' @return List with updated order, capacity_state, and new_events
handle_delivery_scheduling <- function(event, order, capacity_state, config) {
  # Use requested delivery time or earliest available
  target_time <- max(event$event_time, order$preferred_delivery_time)

  # Check van and driver availability
  van_check <- check_resource_availability(capacity_state, "van", target_time)
  driver_check <- check_resource_availability(capacity_state, "driver", target_time)

  if (van_check$available && driver_check$available) {
    # Schedule delivery
    delivery_duration_min <- DELIVERY_TIME_PER_STOP_MIN
    delivery_end_time <- target_time + minutes(as.integer(delivery_duration_min))

    # Reserve resources
    capacity_state <- reserve_resource(capacity_state, "van", van_check$resource_id, delivery_end_time)
    capacity_state <- reserve_resource(capacity_state, "driver", driver_check$resource_id, delivery_end_time)

    # Update order
    order$status <- "out_for_delivery"
    order$delivery_time_scheduled <- target_time

    # Create next event: execute delivery
    new_events <- data.frame(
      event_time = delivery_end_time,
      event_type = "execute_delivery",
      order_id = order$order_id
    )
  } else {
    # Queue for later - schedule for when resources will actually be available
    # Find the later of the two next available times (need both van AND driver)
    next_van_time <- if (!van_check$available) van_check$next_available_time else target_time
    next_driver_time <- if (!driver_check$available) driver_check$next_available_time else target_time
    next_available <- max(next_van_time, next_driver_time)

    new_events <- data.frame(
      event_time = next_available,
      event_type = "schedule_delivery",
      order_id = order$order_id
    )

    capacity_state$queue_log[[length(capacity_state$queue_log) + 1]] <- list(
      time = target_time,
      order_id = order$order_id,
      reason = "delivery_van_or_driver_unavailable",
      rescheduled_for = next_available
    )
  }

  return(list(
    order = order,
    capacity_state = capacity_state,
    new_events = new_events
  ))
}


#' Handle Delivery Execution Event
#'
#' Completes delivery and finishes order lifecycle.
#'
#' @param event Event details
#' @param order Order being processed
#' @param capacity_state Capacity tracking
#' @param config Configuration
#'
#' @return List with updated order, capacity_state, and new_events
handle_delivery_execution <- function(event, order, capacity_state, config) {
  # Update order status
  order$status <- "delivered"
  order$delivery_time_actual <- event$event_time

  # Calculate total time from placement to delivery
  order$total_time_hours <- as.numeric(
    difftime(order$delivery_time_actual, order$placement_time, units = "hours")
  )

  # No new events - order is complete
  new_events <- data.frame()

  return(list(
    order = order,
    capacity_state = capacity_state,
    new_events = new_events
  ))
}


# Bottleneck Identification ----

#' Identify Bottlenecks
#'
#' Analyzes capacity log to identify which resources were most constrained.
#'
#' @param capacity_state Capacity tracking with logs
#' @param config Configuration
#'
#' @return List of identified bottlenecks with descriptions
identify_bottlenecks <- function(capacity_state, config) {
  bottlenecks <- list()

  if (length(capacity_state$queue_log) == 0) {
    return(list(list(
      resource = "none",
      description = "No bottlenecks detected - all orders processed smoothly"
    )))
  }

  # Count queue events by reason
  queue_reasons <- sapply(capacity_state$queue_log, function(x) x$reason)
  queue_counts <- table(queue_reasons)

  # Identify top bottlenecks
  for (reason in names(queue_counts)) {
    if (queue_counts[reason] > 0) {
      bottlenecks[[length(bottlenecks) + 1]] <- list(
        resource = reason,
        queue_count = as.integer(queue_counts[reason]),
        description = sprintf(
          "%s caused %d queueing events",
          reason, queue_counts[reason]
        )
      )
    }
  }

  return(bottlenecks)
}


# Summary Statistics ----

#' Calculate Summary Statistics
#'
#' Generates high-level summary statistics from simulation results.
#'
#' @param orders Data frame of completed orders
#' @param capacity_state Capacity tracking
#'
#' @return List of summary statistics
calculate_summary_stats <- function(orders, capacity_state) {
  completed_orders <- orders[orders$status == "delivered", ]

  list(
    total_orders = nrow(orders),
    completed_orders = nrow(completed_orders),
    completion_rate = nrow(completed_orders) / nrow(orders),
    avg_total_time_hours = mean(completed_orders$total_time_hours, na.rm = TRUE),
    median_total_time_hours = median(completed_orders$total_time_hours, na.rm = TRUE),
    total_queue_events = length(capacity_state$queue_log)
  )
}


# Test Data Generation (Temporary - Phase 4 will replace) ----

#' Generate Test Orders
#'
#' Creates a small set of test orders for Phase 2 testing.
#' This will be replaced by proper order generation in Phase 4.
#'
#' @param config Configuration
#'
#' @return Data frame of test orders
generate_test_orders <- function(config) {
  start_date <- as.POSIXct(config$simulation$start_date)

  data.frame(
    order_id = 1:20,
    placement_time = start_date + hours(seq(0, 19, 1)),
    pickup_time_requested = start_date + hours(seq(2, 21, 1)),
    delivery_time_requested = start_date + hours(seq(26, 45, 1)),
    weight_kg = round(rnorm(20, mean = 15, sd = 5), 1),
    service_type = sample(c("wash", "dry", "wash_dry"), 20, replace = TRUE, prob = c(0.2, 0.1, 0.7)),
    has_special_care = FALSE,
    has_self_check = sample(c(TRUE, FALSE), 20, replace = TRUE),
    is_subscription = sample(c(TRUE, FALSE), 20, replace = TRUE),
    stringsAsFactors = FALSE
  )
}
