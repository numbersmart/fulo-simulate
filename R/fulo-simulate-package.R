#' Fulo Simulate - Business Simulation Engine for Laundry Services
#'
#' @description
#' A comprehensive business simulation platform for modeling laundry delivery
#' service operations. Provides financial analysis, operational insights, and
#' scenario planning capabilities through an interactive Shiny web application.
#'
#' @details
#' ## Overview
#'
#' Fulo Simulate is an event-driven discrete event simulation engine that models
#' the complete operational workflow of a laundry delivery service, from order
#' placement through pickup, processing (washing/drying), and final delivery.
#'
#' ## Key Features
#'
#' - **Complete Order Lifecycle Simulation**: 9-stage state machine from placement
#'   to delivery
#' - **Financial Analysis**: Revenue calculations with multi-tier discounting,
#'   cost tracking, P&L statements, and break-even analysis
#' - **Operational Intelligence**: Resource utilization tracking, bottleneck
#'   identification, and efficiency metrics
#' - **Scenario Planning**: Preset configurations (realistic, pessimistic,
#'   optimistic) with full customization
#' - **Interactive Web Interface**: Shiny-based dashboard with 9 interactive
#'   Plotly charts
#' - **Delivery Route Modeling**: Geographic clustering, traffic simulation,
#'   parking difficulty, and multi-stop route optimization
#'
#' ## Main Modules
#'
#' - **simulation.R**: Core event-driven simulation engine (750 lines)
#' - **inputs.R**: Configuration management and validation (590 lines)
#' - **randomization.R**: Realistic order generation with demand modeling (440 lines)
#' - **routing.R**: Delivery logistics and route optimization (276 lines)
#' - **financial.R**: Revenue, cost, and profitability analysis (372 lines)
#' - **operations.R**: Resource utilization and operational metrics (386 lines)
#' - **utils.R**: Utility functions and helpers
#'
#' ## Quick Start
#'
#' Launch the interactive Shiny application:
#' ```r
#' shiny::runApp()
#' ```
#'
#' Or run a simulation programmatically:
#' ```r
#' # Load configuration
#' config <- jsonlite::fromJSON("configs/realistic.json", simplifyVector = FALSE)
#'
#' # Run simulation
#' results <- run_simulation(config, random_seed = 42)
#'
#' # Calculate metrics
#' financial <- calculate_financial_summary(results, config)
#' operational <- calculate_operational_summary(results, config)
#' ```
#'
#' ## Configuration
#'
#' Simulations are configured via JSON files or the Shiny UI with the following
#' parameter categories:
#'
#' - **Regional**: Population, dwellings, geographic density, parking difficulty
#' - **Pricing**: Wash/dry prices, self-check discount, subscription discount
#' - **Costs**: Driver wages, fuel, washing/drying costs, overhead
#' - **Capacity**: Vans, drivers, machines, operating hours
#' - **Simulation**: Demand scenario, duration, price elasticity, subscription rate
#'
#' ## Performance
#'
#' Typical simulation times on modern hardware:
#' - 7-day simulation: 5-10 seconds
#' - 14-day simulation: 10-20 seconds
#' - 30-day simulation: 20-30 seconds
#'
#' ## Documentation
#'
#' - User Guide: `docs/USER_GUIDE.md` - Comprehensive guide for business users
#' - Developer Guide: `docs/DEVELOPER_GUIDE.md` - Technical documentation
#' - Changelog: `CHANGELOG.md` - Version history and release notes
#'
#' @author Eduardo Flores (Product Owner)
#' @version 1.0.0
#' @keywords simulation business-intelligence laundry-service operations-research
#'
#' @references
#' - Project Repository: \url{https://github.com/numbersmart/fulo-simulate}
#' - User Guide: \url{docs/USER_GUIDE.md}
#' - Developer Guide: \url{docs/DEVELOPER_GUIDE.md}
#'
#' @seealso
#' - \code{\link{run_simulation}} - Main simulation entry point
#' - \code{\link{calculate_financial_summary}} - Financial metrics
#' - \code{\link{calculate_operational_summary}} - Operational metrics
#' - \code{\link{validate_config}} - Configuration validation
#'
#' @examples
#' \dontrun{
#' # Launch the Shiny application
#' shiny::runApp()
#'
#' # Load and run a preset scenario
#' config <- jsonlite::fromJSON("configs/realistic.json", simplifyVector = FALSE)
#' results <- run_simulation(config, random_seed = 42)
#'
#' # Analyze results
#' financial <- calculate_financial_summary(results, config)
#' print(financial$summary)
#'
#' operational <- calculate_operational_summary(results, config)
#' print(operational$summary)
#'
#' # Compare multiple scenarios
#' pessimistic_config <- jsonlite::fromJSON("configs/pessimistic.json",
#'                                           simplifyVector = FALSE)
#' pessimistic_results <- run_simulation(pessimistic_config, random_seed = 42)
#'
#' comparison <- compare_scenarios(list(
#'   list(name = "Realistic", results = results, config = config),
#'   list(name = "Pessimistic", results = pessimistic_results,
#'        config = pessimistic_config)
#' ))
#' print(comparison)
#' }
#'
"_PACKAGE"
