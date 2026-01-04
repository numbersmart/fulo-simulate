# Test script for Phase 4 - Order Generation & Randomization
#
# This script tests the new order generation and routing functionality
# with all three scenario configurations.

# Load required libraries
library(jsonlite)

# Source all modules
source("R/utils.R")
source("R/inputs.R")
source("R/randomization.R")
source("R/routing.R")
source("R/simulation.R")

# Test function
test_scenario <- function(config_path, scenario_name) {
  cat("\n========================================\n")
  cat("Testing:", scenario_name, "\n")
  cat("========================================\n")

  # Load config
  config <- fromJSON(config_path, simplifyVector = FALSE)

  # Validate config
  validation <- validate_config(config)
  if (!validation$valid) {
    cat("Config validation FAILED:\n")
    print(validation$errors)
    return(FALSE)
  }
  cat("✓ Config validation passed\n")

  # Generate orders
  tryCatch({
    orders <- generate_orders(config, random_seed = 42)
    cat(sprintf("✓ Generated %d orders\n", nrow(orders)))
    cat(sprintf("  - wash_dry: %d (%.1f%%)\n",
                sum(orders$service_type == "wash_dry"),
                100 * sum(orders$service_type == "wash_dry") / nrow(orders)))
    cat(sprintf("  - wash_only: %d (%.1f%%)\n",
                sum(orders$service_type == "wash_only"),
                100 * sum(orders$service_type == "wash_only") / nrow(orders)))
    cat(sprintf("  - dry_only: %d (%.1f%%)\n",
                sum(orders$service_type == "dry_only"),
                100 * sum(orders$service_type == "dry_only") / nrow(orders)))
    cat(sprintf("  - Avg kg/order: %.1f\n", mean(orders$kg_estimate)))
    cat(sprintf("  - Subscribers: %d (%.1f%%)\n",
                sum(orders$is_subscription),
                100 * sum(orders$is_subscription) / nrow(orders)))
    cat(sprintf("  - Self-check enabled: %d (%.1f%%)\n",
                sum(orders$self_check_enabled),
                100 * sum(orders$self_check_enabled) / nrow(orders)))
  }, error = function(e) {
    cat("✗ Order generation FAILED:", e$message, "\n")
    return(FALSE)
  })

  # Test routing calculations
  tryCatch({
    # Calculate distance between two sample points
    dist <- calculate_route_distance(40.4168, -3.7038, 40.4200, -3.7000)
    cat(sprintf("✓ Route distance calculation works (%.2f km)\n", dist))

    # Calculate travel time
    time <- calculate_travel_time(dist, hour_of_day = 18, parking_difficulty = 7)
    cat(sprintf("✓ Travel time calculation works (%.1f min)\n", time))
  }, error = function(e) {
    cat("✗ Routing calculation FAILED:", e$message, "\n")
    return(FALSE)
  })

  cat("\n✓ All Phase 4 tests passed for", scenario_name, "\n")
  return(TRUE)
}

# Run tests for all three scenarios
cat("\n")
cat("==========================================\n")
cat("PHASE 4 TEST SUITE\n")
cat("Testing Order Generation & Randomization\n")
cat("==========================================\n")

all_passed <- TRUE

all_passed <- test_scenario("configs/realistic.json", "Realistic Scenario") && all_passed
all_passed <- test_scenario("configs/pessimistic.json", "Pessimistic Scenario") && all_passed
all_passed <- test_scenario("configs/optimistic.json", "Optimistic Scenario") && all_passed

# Summary
cat("\n========================================\n")
if (all_passed) {
  cat("SUCCESS: All Phase 4 tests passed!\n")
  cat("========================================\n")
} else {
  cat("FAILURE: Some tests failed\n")
  cat("========================================\n")
  stop("Phase 4 tests failed")
}
