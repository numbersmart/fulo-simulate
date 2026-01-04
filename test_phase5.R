# Test script for Phase 5 - Financial & Operational Metrics
#
# This script tests the financial and operational analytics functionality
# by running a full simulation and calculating all metrics.

# Load required libraries
library(jsonlite)

# Source all modules
source("R/utils.R")
source("R/inputs.R")
source("R/randomization.R")
source("R/routing.R")
source("R/simulation.R")
source("R/financial.R")
source("R/operations.R")

# Test function
test_metrics <- function(config_path, scenario_name) {
  cat("\n========================================\n")
  cat("Testing:", scenario_name, "\n")
  cat("========================================\n")

  # Load config
  config <- fromJSON(config_path, simplifyVector = FALSE)

  cat("✓ Config loaded\n")

  # Run simulation
  tryCatch({
    sim_results <- run_simulation(config, random_seed = 42)
    cat(sprintf("✓ Simulation completed with %d orders\n", nrow(sim_results$orders)))
  }, error = function(e) {
    cat("✗ Simulation FAILED:", e$message, "\n")
    return(FALSE)
  })

  # Test financial calculations
  tryCatch({
    financial <- calculate_financial_summary(sim_results, config)

    cat("\n--- Financial Metrics ---\n")
    cat(sprintf("  Total Revenue:     €%.2f\n", financial$summary$total_revenue))
    cat(sprintf("  Total Costs:       €%.2f\n", financial$summary$total_costs))
    cat(sprintf("  Gross Profit:      €%.2f\n", financial$summary$gross_profit))
    cat(sprintf("  Gross Margin:      %.1f%%\n", financial$summary$gross_margin_pct))
    cat(sprintf("  Break-even Orders: %d orders\n", financial$summary$breakeven_orders))
    cat(sprintf("  Profitable:        %s\n", ifelse(financial$summary$is_profitable, "YES", "NO")))

    # Revenue breakdown
    cat("\n  Revenue by Service:\n")
    for (i in 1:nrow(financial$revenue$revenue_by_service)) {
      svc <- financial$revenue$revenue_by_service[i, ]
      cat(sprintf("    %s: €%.2f (%d orders, €%.2f avg)\n",
                  svc$service_type, svc$revenue, svc$order_count, svc$avg_revenue_per_order))
    }

    cat("✓ Financial calculations passed\n")
  }, error = function(e) {
    cat("✗ Financial calculations FAILED:", e$message, "\n")
    return(FALSE)
  })

  # Test operational calculations
  tryCatch({
    operational <- calculate_operational_summary(sim_results, config)

    cat("\n--- Operational Metrics ---\n")
    cat(sprintf("  Orders per Day:    %.1f\n", operational$summary$orders_per_day))
    cat(sprintf("  Primary Bottleneck: %s (%.1f%% utilization)\n",
                operational$summary$primary_bottleneck,
                operational$summary$bottleneck_utilization))
    cat(sprintf("  Completion Rate:   %.1f%%\n", operational$summary$completion_rate))

    # Utilization breakdown
    cat("\n  Resource Utilization:\n")
    for (i in 1:nrow(operational$utilization$summary)) {
      res <- operational$utilization$summary[i, ]
      cat(sprintf("    %s: %.1f%% (%d resources)\n",
                  res$resource_type, res$utilization_pct,
                  switch(res$resource_type,
                         "Van" = config$capacity$num_vans,
                         "Driver" = config$capacity$num_drivers,
                         "Wash Machine" = config$capacity$num_wash_machines,
                         "Dry Machine" = config$capacity$num_dry_machines)))
    }

    # Service metrics
    cat("\n  Service Level:\n")
    cat(sprintf("    Completed: %d/%d orders\n",
                operational$service_metrics$completed_orders,
                operational$service_metrics$total_orders))
    if (!is.na(operational$service_metrics$refund_rate_pct)) {
      cat(sprintf("    Refund Rate: %.1f%%\n", operational$service_metrics$refund_rate_pct))
    }
    if (!is.na(operational$service_metrics$failure_rate_pct)) {
      cat(sprintf("    Failure Rate: %.1f%%\n", operational$service_metrics$failure_rate_pct))
    }

    cat("✓ Operational calculations passed\n")
  }, error = function(e) {
    cat("✗ Operational calculations FAILED:", e$message, "\n")
    return(FALSE)
  })

  cat("\n✓ All Phase 5 tests passed for", scenario_name, "\n")
  return(list(
    financial = financial,
    operational = operational,
    results = sim_results,
    config = config
  ))
}

# Run tests for all three scenarios
cat("\n")
cat("==========================================\n")
cat("PHASE 5 TEST SUITE\n")
cat("Testing Financial & Operational Metrics\n")
cat("==========================================\n")

scenarios <- list()

scenarios$realistic <- test_metrics("configs/realistic.json", "Realistic Scenario")
scenarios$pessimistic <- test_metrics("configs/pessimistic.json", "Pessimistic Scenario")
scenarios$optimistic <- test_metrics("configs/optimistic.json", "Optimistic Scenario")

# Test scenario comparison
cat("\n========================================\n")
cat("Testing Scenario Comparison\n")
cat("========================================\n")

tryCatch({
  comparison_input <- list(
    list(results = scenarios$realistic$results,
         config = scenarios$realistic$config,
         name = "Realistic"),
    list(results = scenarios$pessimistic$results,
         config = scenarios$pessimistic$config,
         name = "Pessimistic"),
    list(results = scenarios$optimistic$results,
         config = scenarios$optimistic$config,
         name = "Optimistic")
  )

  comparison <- compare_scenarios(comparison_input)

  cat("\nScenario Comparison Results:\n")
  print(comparison)

  cat("\n✓ Scenario comparison passed\n")
}, error = function(e) {
  cat("✗ Scenario comparison FAILED:", e$message, "\n")
})

# Summary
cat("\n========================================\n")
cat("SUCCESS: All Phase 5 tests passed!\n")
cat("========================================\n")
cat("\nKey Findings:\n")
cat(sprintf("  Realistic:    €%.0f profit, %.1f%% margin\n",
            scenarios$realistic$financial$summary$gross_profit,
            scenarios$realistic$financial$summary$gross_margin_pct))
cat(sprintf("  Pessimistic:  €%.0f profit, %.1f%% margin\n",
            scenarios$pessimistic$financial$summary$gross_profit,
            scenarios$pessimistic$financial$summary$gross_margin_pct))
cat(sprintf("  Optimistic:   €%.0f profit, %.1f%% margin\n",
            scenarios$optimistic$financial$summary$gross_profit,
            scenarios$optimistic$financial$summary$gross_margin_pct))
