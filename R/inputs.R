#' Input Configuration and Validation
#'
#' Functions for managing simulation input parameters including defaults,
#' validation, and configuration management.
#'
#' Configuration is organized into logical sections:
#' - Regional: Geographic and demographic parameters
#' - Costs: Operational cost drivers
#' - Pricing: Revenue parameters and discounts
#' - Capacity: Available resources
#' - Randomization: Stochastic model parameters
#' - Elasticity: Demand response parameters
#' - Simulation: Runtime parameters
#'
#' @author Fulo Simulate Team
#' @date 2026-01-02

library(jsonlite)

# Default Configuration ----

#' Get Default Configuration
#'
#' Returns a complete configuration with sensible default values based on
#' current Madrid neighborhood operations.
#'
#' DEFAULTS RATIONALE:
#' - Regional params based on typical Madrid urban neighborhood (Chamberi-like)
#' - Costs based on 2026 Madrid market rates
#' - Pricing competitive with coin-operated laundromats (€6-9 range)
#' - Capacity sized for ~100-200 orders per week
#'
#' @return List containing all configuration parameters with defaults
#' @export
#'
#' @examples
#' config <- get_default_config()
#' print(config$pricing$wash_price)
get_default_config <- function() {
  list(
    metadata = list(
      name = "Default Configuration",
      description = "Baseline configuration with sensible defaults for Madrid neighborhood",
      version = "1.0.0",
      created_date = as.character(Sys.Date())
    ),

    # Regional Parameters ----
    regional = list(
      # Number of households in service area
      dwellings = 50000,

      # Total population in service area
      population = 120000,

      # Parking difficulty on 1-10 scale (10 = extremely difficult)
      # ASSUMPTION: Madrid urban areas typically 7-8
      parking_difficulty = 7,

      # Geographic density: "urban", "suburban", or "rural"
      geographic_density = "urban"
    ),

    # Cost Parameters (in EUR) ----
    costs = list(
      # Driver hourly rate including benefits
      # ASSUMPTION: Madrid minimum wage ~€15/hour in 2026
      driver_hourly_rate = 15,

      # Cost per kg for washing (detergent, water, electricity, machine wear)
      # ASSUMPTION: Commercial washers ~€0.25/kg based on utility costs
      cost_per_kg_wash = 0.25,

      # Cost per kg for drying (electricity, machine wear)
      # ASSUMPTION: Dryers more expensive due to energy ~€0.40/kg
      cost_per_kg_dry = 0.40,

      # Fixed overhead costs per week (rent, insurance, admin)
      overhead_per_week = 500,

      # Fuel cost per kilometer driven
      # ASSUMPTION: Based on €1.50/liter and 15km/liter = €0.10/km
      fuel_per_km = 0.10
    ),

    # Pricing Parameters (in EUR) ----
    pricing = list(
      # Price per wash service (not per kg)
      # ASSUMPTION: Competitive with laundromats (€6-8 range)
      wash_price = 7,

      # Price per dry service (not per kg)
      # ASSUMPTION: Competitive with laundromats (€6-9 range)
      dry_price = 8,

      # Discount for self-check feature (customer photographs tags)
      # ASSUMPTION: Saves us ~€2 in labor costs
      self_check_discount = 2,

      # Subscription discount as percentage (0.15 = 15% off)
      # ASSUMPTION: Reward loyalty, encourage recurring revenue
      subscription_discount_pct = 0.15
    ),

    # Capacity Parameters ----
    capacity = list(
      # Number of delivery vans available
      num_vans = 3,

      # Maximum load capacity per van in kg
      # ASSUMPTION: Typical commercial van holds ~100kg of laundry
      van_capacity_kg = 100,

      # Number of washing machines available
      num_wash_machines = 10,

      # Number of drying machines available
      num_dry_machines = 8,

      # Number of drivers employed
      num_drivers = 4,

      # Operating hours per day (e.g., 8am-8pm = 12 hours)
      operating_hours_per_day = 12
    ),

    # Randomization Parameters ----
    randomization = list(
      # Distribution type for order generation
      # Options: "normal", "uniform", "poisson"
      distribution_type = "normal",

      # Random seed for reproducibility
      random_seed = 42,

      # Demand scenario: "pessimistic", "realistic", "optimistic"
      # Affects overall order volume
      demand_scenario = "realistic",

      # Peak hours start time (24-hour format)
      peak_hours_start = "18:00",

      # Peak hours end time (24-hour format)
      peak_hours_end = "20:00",

      # Multiplier for order volume during peak hours
      # ASSUMPTION: Evening rush (6-8pm) has 3x normal demand
      peak_hour_multiplier = 3.0,

      # Percentage of orders that result in refund (0.02 = 2%)
      # ASSUMPTION: Industry standard quality issues ~2%
      refund_rate = 0.02,

      # Percentage of deliveries that fail (customer not home, etc.)
      # ASSUMPTION: Industry standard ~5% failed deliveries
      failed_delivery_rate = 0.05
    ),

    # Elasticity Parameters ----
    elasticity = list(
      # Price elasticity of demand
      # How much demand changes with price (1.5 = moderately elastic)
      # ASSUMPTION: Laundry services are discretionary, somewhat price sensitive
      price_elasticity = 1.5,

      # Adoption rate of self-check feature (0.30 = 30% of customers)
      # ASSUMPTION: Tech-savvy customers willing to save money
      self_check_adoption_rate = 0.30,

      # Percentage of customers on subscription (0.20 = 20%)
      # ASSUMPTION: Families with regular laundry needs
      subscription_ratio = 0.20
    ),

    # Simulation Parameters ----
    simulation = list(
      # Start date for simulation (ISO format)
      start_date = "2026-01-06",

      # Duration in days
      duration_days = 7,

      # Time slot duration in hours for scheduling
      # ASSUMPTION: 2-hour windows standard for delivery services
      time_slot_hours = 2
    )
  )
}


# Configuration Validation ----

#' Validate Configuration
#'
#' Validates a configuration object to ensure all required parameters are
#' present and values are within acceptable ranges.
#'
#' Performs comprehensive validation including:
#' - Required fields present
#' - Data types correct
#' - Values within valid ranges
#' - No negative costs or capacities
#' - Percentages between 0 and 1
#' - Dates parseable
#'
#' @param config List containing configuration parameters
#'
#' @return List with elements:
#'   - valid: Logical indicating if config is valid
#'   - errors: Character vector of error messages (empty if valid)
#'   - warnings: Character vector of warning messages
#' @export
#'
#' @examples
#' config <- get_default_config()
#' validation <- validate_config(config)
#' if (!validation$valid) {
#'   stop("Invalid config: ", paste(validation$errors, collapse = ", "))
#' }
validate_config <- function(config) {
  errors <- character()
  warnings <- character()

  # Check required top-level sections
  required_sections <- c("regional", "costs", "pricing", "capacity",
                         "randomization", "elasticity", "simulation")

  for (section in required_sections) {
    if (!section %in% names(config)) {
      errors <- c(errors, sprintf("Missing required section: %s", section))
    }
  }

  # If major sections missing, return early
  if (length(errors) > 0) {
    return(list(valid = FALSE, errors = errors, warnings = warnings))
  }

  # Validate Regional Parameters ----
  regional_errors <- validate_regional_params(config$regional)
  errors <- c(errors, regional_errors)

  # Validate Cost Parameters ----
  cost_errors <- validate_cost_params(config$costs)
  errors <- c(errors, cost_errors)

  # Validate Pricing Parameters ----
  pricing_errors <- validate_pricing_params(config$pricing)
  errors <- c(errors, pricing_errors)

  # Validate Capacity Parameters ----
  capacity_errors <- validate_capacity_params(config$capacity)
  errors <- c(errors, capacity_errors)

  # Validate Randomization Parameters ----
  random_errors <- validate_randomization_params(config$randomization)
  errors <- c(errors, random_errors)

  # Validate Elasticity Parameters ----
  elasticity_errors <- validate_elasticity_params(config$elasticity)
  errors <- c(errors, elasticity_errors)

  # Validate Simulation Parameters ----
  sim_errors <- validate_simulation_params(config$simulation)
  errors <- c(errors, sim_errors)

  # Cross-validation checks ----

  # Check that subscription discount doesn't exceed price
  if (config$pricing$subscription_discount_pct >= 1.0) {
    errors <- c(errors, "Subscription discount cannot be >= 100%")
  }

  # Check that self-check discount doesn't exceed price
  min_price <- min(config$pricing$wash_price, config$pricing$dry_price)
  if (config$pricing$self_check_discount >= min_price) {
    warnings <- c(warnings,
      sprintf("Self-check discount (%.2f) is >= minimum price (%.2f)",
              config$pricing$self_check_discount, min_price))
  }

  # Check that we have enough resources for operations
  if (config$capacity$num_drivers < config$capacity$num_vans) {
    warnings <- c(warnings, "Fewer drivers than vans - some vans may be idle")
  }

  # Final validation
  valid <- length(errors) == 0

  return(list(
    valid = valid,
    errors = errors,
    warnings = warnings
  ))
}


# Section-specific Validation Functions ----

#' Validate Regional Parameters
#' @param regional List of regional parameters
#' @return Character vector of errors
validate_regional_params <- function(regional) {
  errors <- character()

  # Dwellings
  if (is.null(regional$dwellings) || !is.numeric(regional$dwellings)) {
    errors <- c(errors, "regional$dwellings must be numeric")
  } else if (regional$dwellings <= 0) {
    errors <- c(errors, "regional$dwellings must be positive")
  }

  # Population
  if (is.null(regional$population) || !is.numeric(regional$population)) {
    errors <- c(errors, "regional$population must be numeric")
  } else if (regional$population <= 0) {
    errors <- c(errors, "regional$population must be positive")
  }

  # Parking difficulty
  if (is.null(regional$parking_difficulty) || !is.numeric(regional$parking_difficulty)) {
    errors <- c(errors, "regional$parking_difficulty must be numeric")
  } else if (regional$parking_difficulty < 1 || regional$parking_difficulty > 10) {
    errors <- c(errors, "regional$parking_difficulty must be between 1 and 10")
  }

  # Geographic density
  valid_densities <- c("urban", "suburban", "rural")
  if (is.null(regional$geographic_density) ||
      !regional$geographic_density %in% valid_densities) {
    errors <- c(errors, sprintf(
      "regional$geographic_density must be one of: %s",
      paste(valid_densities, collapse = ", ")
    ))
  }

  return(errors)
}


#' Validate Cost Parameters
#' @param costs List of cost parameters
#' @return Character vector of errors
validate_cost_params <- function(costs) {
  errors <- character()

  # All costs must be numeric and non-negative
  cost_fields <- c("driver_hourly_rate", "cost_per_kg_wash", "cost_per_kg_dry",
                   "overhead_per_week", "fuel_per_km")

  for (field in cost_fields) {
    if (is.null(costs[[field]]) || !is.numeric(costs[[field]])) {
      errors <- c(errors, sprintf("costs$%s must be numeric", field))
    } else if (costs[[field]] < 0) {
      errors <- c(errors, sprintf("costs$%s cannot be negative", field))
    }
  }

  return(errors)
}


#' Validate Pricing Parameters
#' @param pricing List of pricing parameters
#' @return Character vector of errors
validate_pricing_params <- function(pricing) {
  errors <- character()

  # Wash price
  if (is.null(pricing$wash_price) || !is.numeric(pricing$wash_price)) {
    errors <- c(errors, "pricing$wash_price must be numeric")
  } else if (pricing$wash_price <= 0) {
    errors <- c(errors, "pricing$wash_price must be positive")
  }

  # Dry price
  if (is.null(pricing$dry_price) || !is.numeric(pricing$dry_price)) {
    errors <- c(errors, "pricing$dry_price must be numeric")
  } else if (pricing$dry_price <= 0) {
    errors <- c(errors, "pricing$dry_price must be positive")
  }

  # Self-check discount
  if (is.null(pricing$self_check_discount) || !is.numeric(pricing$self_check_discount)) {
    errors <- c(errors, "pricing$self_check_discount must be numeric")
  } else if (pricing$self_check_discount < 0) {
    errors <- c(errors, "pricing$self_check_discount cannot be negative")
  }

  # Subscription discount percentage
  if (is.null(pricing$subscription_discount_pct) || !is.numeric(pricing$subscription_discount_pct)) {
    errors <- c(errors, "pricing$subscription_discount_pct must be numeric")
  } else if (pricing$subscription_discount_pct < 0 || pricing$subscription_discount_pct > 1) {
    errors <- c(errors, "pricing$subscription_discount_pct must be between 0 and 1")
  }

  return(errors)
}


#' Validate Capacity Parameters
#' @param capacity List of capacity parameters
#' @return Character vector of errors
validate_capacity_params <- function(capacity) {
  errors <- character()

  # All capacity fields must be positive integers
  capacity_fields <- c("num_vans", "van_capacity_kg", "num_wash_machines",
                       "num_dry_machines", "num_drivers", "operating_hours_per_day")

  for (field in capacity_fields) {
    if (is.null(capacity[[field]]) || !is.numeric(capacity[[field]])) {
      errors <- c(errors, sprintf("capacity$%s must be numeric", field))
    } else if (capacity[[field]] <= 0) {
      errors <- c(errors, sprintf("capacity$%s must be positive", field))
    } else if (field != "van_capacity_kg" && capacity[[field]] != round(capacity[[field]])) {
      errors <- c(errors, sprintf("capacity$%s must be an integer", field))
    }
  }

  # Operating hours sanity check
  if (!is.null(capacity$operating_hours_per_day) &&
      capacity$operating_hours_per_day > 24) {
    errors <- c(errors, "capacity$operating_hours_per_day cannot exceed 24")
  }

  return(errors)
}


#' Validate Randomization Parameters
#' @param randomization List of randomization parameters
#' @return Character vector of errors
validate_randomization_params <- function(randomization) {
  errors <- character()

  # Distribution type
  valid_distributions <- c("normal", "uniform", "poisson")
  if (is.null(randomization$distribution_type) ||
      !randomization$distribution_type %in% valid_distributions) {
    errors <- c(errors, sprintf(
      "randomization$distribution_type must be one of: %s",
      paste(valid_distributions, collapse = ", ")
    ))
  }

  # Random seed
  if (is.null(randomization$random_seed) || !is.numeric(randomization$random_seed)) {
    errors <- c(errors, "randomization$random_seed must be numeric")
  }

  # Demand scenario
  valid_scenarios <- c("pessimistic", "realistic", "optimistic")
  if (is.null(randomization$demand_scenario) ||
      !randomization$demand_scenario %in% valid_scenarios) {
    errors <- c(errors, sprintf(
      "randomization$demand_scenario must be one of: %s",
      paste(valid_scenarios, collapse = ", ")
    ))
  }

  # Peak hour multiplier
  if (is.null(randomization$peak_hour_multiplier) ||
      !is.numeric(randomization$peak_hour_multiplier)) {
    errors <- c(errors, "randomization$peak_hour_multiplier must be numeric")
  } else if (randomization$peak_hour_multiplier < 1) {
    errors <- c(errors, "randomization$peak_hour_multiplier must be >= 1")
  }

  # Refund rate
  if (is.null(randomization$refund_rate) || !is.numeric(randomization$refund_rate)) {
    errors <- c(errors, "randomization$refund_rate must be numeric")
  } else if (randomization$refund_rate < 0 || randomization$refund_rate > 1) {
    errors <- c(errors, "randomization$refund_rate must be between 0 and 1")
  }

  # Failed delivery rate
  if (is.null(randomization$failed_delivery_rate) ||
      !is.numeric(randomization$failed_delivery_rate)) {
    errors <- c(errors, "randomization$failed_delivery_rate must be numeric")
  } else if (randomization$failed_delivery_rate < 0 ||
             randomization$failed_delivery_rate > 1) {
    errors <- c(errors, "randomization$failed_delivery_rate must be between 0 and 1")
  }

  return(errors)
}


#' Validate Elasticity Parameters
#' @param elasticity List of elasticity parameters
#' @return Character vector of errors
validate_elasticity_params <- function(elasticity) {
  errors <- character()

  # Price elasticity
  if (is.null(elasticity$price_elasticity) || !is.numeric(elasticity$price_elasticity)) {
    errors <- c(errors, "elasticity$price_elasticity must be numeric")
  } else if (elasticity$price_elasticity < 0) {
    errors <- c(errors, "elasticity$price_elasticity cannot be negative")
  }

  # Self-check adoption rate
  if (is.null(elasticity$self_check_adoption_rate) ||
      !is.numeric(elasticity$self_check_adoption_rate)) {
    errors <- c(errors, "elasticity$self_check_adoption_rate must be numeric")
  } else if (elasticity$self_check_adoption_rate < 0 ||
             elasticity$self_check_adoption_rate > 1) {
    errors <- c(errors, "elasticity$self_check_adoption_rate must be between 0 and 1")
  }

  # Subscription ratio
  if (is.null(elasticity$subscription_ratio) ||
      !is.numeric(elasticity$subscription_ratio)) {
    errors <- c(errors, "elasticity$subscription_ratio must be numeric")
  } else if (elasticity$subscription_ratio < 0 || elasticity$subscription_ratio > 1) {
    errors <- c(errors, "elasticity$subscription_ratio must be between 0 and 1")
  }

  return(errors)
}


#' Validate Simulation Parameters
#' @param simulation List of simulation parameters
#' @return Character vector of errors
validate_simulation_params <- function(simulation) {
  errors <- character()

  # Start date
  if (is.null(simulation$start_date)) {
    errors <- c(errors, "simulation$start_date is required")
  } else {
    tryCatch({
      as.Date(simulation$start_date)
    }, error = function(e) {
      errors <<- c(errors, "simulation$start_date must be valid date (YYYY-MM-DD format)")
    })
  }

  # Duration days
  if (is.null(simulation$duration_days) || !is.numeric(simulation$duration_days)) {
    errors <- c(errors, "simulation$duration_days must be numeric")
  } else if (simulation$duration_days <= 0) {
    errors <- c(errors, "simulation$duration_days must be positive")
  } else if (simulation$duration_days > 365) {
    errors <- c(errors, "simulation$duration_days cannot exceed 365 (alpha limitation)")
  }

  # Time slot hours
  if (is.null(simulation$time_slot_hours) || !is.numeric(simulation$time_slot_hours)) {
    errors <- c(errors, "simulation$time_slot_hours must be numeric")
  } else if (simulation$time_slot_hours <= 0 || simulation$time_slot_hours > 24) {
    errors <- c(errors, "simulation$time_slot_hours must be between 0 and 24")
  }

  return(errors)
}


# Configuration Management ----
# Note: save_config and load_config are already implemented in utils.R
# This file provides the validation that utils.R uses

#' Print Configuration Summary
#'
#' Displays a human-readable summary of configuration parameters.
#'
#' @param config Configuration list
#'
#' @return Invisible NULL (prints to console)
#' @export
#'
#' @examples
#' config <- get_default_config()
#' print_config_summary(config)
print_config_summary <- function(config) {
  cat("\n=== FULO SIMULATE CONFIGURATION ===\n\n")

  if (!is.null(config$metadata$name)) {
    cat("Name:", config$metadata$name, "\n")
  }
  if (!is.null(config$metadata$description)) {
    cat("Description:", config$metadata$description, "\n")
  }

  cat("\n--- Regional Parameters ---\n")
  cat(sprintf("  Dwellings: %s\n", format(config$regional$dwellings, big.mark = ",")))
  cat(sprintf("  Population: %s\n", format(config$regional$population, big.mark = ",")))
  cat(sprintf("  Parking Difficulty: %d/10\n", config$regional$parking_difficulty))
  cat(sprintf("  Density: %s\n", config$regional$geographic_density))

  cat("\n--- Costs (EUR) ---\n")
  cat(sprintf("  Driver: €%.2f/hour\n", config$costs$driver_hourly_rate))
  cat(sprintf("  Washing: €%.2f/kg\n", config$costs$cost_per_kg_wash))
  cat(sprintf("  Drying: €%.2f/kg\n", config$costs$cost_per_kg_dry))
  cat(sprintf("  Overhead: €%.2f/week\n", config$costs$overhead_per_week))

  cat("\n--- Pricing (EUR) ---\n")
  cat(sprintf("  Wash: €%.2f\n", config$pricing$wash_price))
  cat(sprintf("  Dry: €%.2f\n", config$pricing$dry_price))
  cat(sprintf("  Self-check Discount: €%.2f\n", config$pricing$self_check_discount))
  cat(sprintf("  Subscription Discount: %.0f%%\n",
              config$pricing$subscription_discount_pct * 100))

  cat("\n--- Capacity ---\n")
  cat(sprintf("  Vans: %d\n", config$capacity$num_vans))
  cat(sprintf("  Drivers: %d\n", config$capacity$num_drivers))
  cat(sprintf("  Wash Machines: %d\n", config$capacity$num_wash_machines))
  cat(sprintf("  Dry Machines: %d\n", config$capacity$num_dry_machines))
  cat(sprintf("  Operating Hours: %d/day\n", config$capacity$operating_hours_per_day))

  cat("\n--- Simulation ---\n")
  cat(sprintf("  Start Date: %s\n", config$simulation$start_date))
  cat(sprintf("  Duration: %d days\n", config$simulation$duration_days))
  cat(sprintf("  Demand Scenario: %s\n", config$randomization$demand_scenario))
  cat(sprintf("  Random Seed: %d\n", config$randomization$random_seed))

  cat("\n===================================\n\n")

  invisible(NULL)
}
