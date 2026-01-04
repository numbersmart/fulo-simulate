# Fulo Simulate - Developer Guide

**Version 1.0.0** | Last Updated: January 2026

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Project Structure](#project-structure)
3. [Module Documentation](#module-documentation)
4. [Development Workflow](#development-workflow)
5. [Testing](#testing)
6. [Contributing](#contributing)
7. [Code Standards](#code-standards)
8. [Deployment](#deployment)

---

## Architecture Overview

### Design Principles

Fulo Simulate follows a modular architecture with clear separation of concerns:

- **Inputs** - Configuration and validation
- **Simulation** - Core event-driven engine
- **Randomization** - Order generation with realistic patterns
- **Routing** - Geographic and logistics calculations
- **Financial** - Revenue, cost, and P&L calculations
- **Operations** - Utilization, bottleneck, and efficiency metrics
- **UI** - Shiny web interface

### Key Design Decisions

**Event-Driven Simulation:**
- Orders progress through lifecycle stages (placed → pickup → wash → dry → delivery)
- Event queue processes chronologically
- Resource capacity checked and reserved at each stage
- Bottlenecks naturally emerge from capacity constraints

**Reactive Shiny Architecture:**
- UI inputs build configuration object
- Simulation runs on button click (not automatically)
- Results stored in reactive values
- Charts and tables reactively update

**Configuration-Driven:**
- JSON configuration files for scenarios
- All parameters externalized (no hard-coding)
- Validation ensures parameters are within valid ranges

**Functional Programming Style:**
- Pure functions where possible
- Side effects isolated (random number generation)
- Functions return data structures, don't modify global state

---

## Project Structure

```
fulo-simulate/
├── app.R                    # Shiny app entry point
├── R/                       # R source modules
│   ├── utils.R              # Utility functions
│   ├── inputs.R             # Configuration and validation
│   ├── simulation.R         # Core simulation engine
│   ├── randomization.R      # Order generation
│   ├── routing.R            # Delivery routing
│   ├── financial.R          # Financial calculations
│   └── operations.R         # Operational metrics
├── configs/                 # Preset scenario configurations
│   ├── realistic.json
│   ├── pessimistic.json
│   └── optimistic.json
├── data/                    # Default data files
│   └── defaults.json
├── docs/                    # Documentation
│   ├── USER_GUIDE.md
│   ├── DEVELOPER_GUIDE.md
│   └── coding_standards.md
├── tests/                   # Test scripts
│   ├── test_phase4.R
│   └── test_phase5.R
├── renv/                    # Package management (renv)
├── renv.lock                # Locked dependencies
├── .Rprofile                # R session configuration
├── .gitignore               # Git ignore rules
├── README.md                # Project readme
├── CHANGELOG.md             # Version history
└── LICENSE                  # License file
```

---

## Module Documentation

### R/utils.R

**Purpose:** Shared utility functions used across modules

**Key Functions:**

- `check_dependencies()` - Validates required packages are installed
- `save_config(config, file_path)` - Saves configuration to JSON
- `load_config(file_path)` - Loads configuration from JSON
- `%||%` - Null coalescing operator
- `generate_time_sequence()` - Creates time slot sequences

**Usage Example:**
```r
# Check if all required packages are available
if (!check_dependencies()) {
  stop("Missing required packages")
}

# Load configuration
config <- load_config("configs/realistic.json")
```

### R/inputs.R (590 lines)

**Purpose:** Configuration management and validation

**Key Functions:**

- `get_default_config()` - Returns default Madrid-based configuration
- `validate_config(config)` - Validates entire configuration
- `validate_regional_params()` - Validates regional section
- `validate_cost_params()` - Validates cost section
- `validate_pricing_params()` - Validates pricing section
- `validate_capacity_params()` - Validates capacity section
- `validate_randomization_params()` - Validates randomization section
- `validate_elasticity_params()` - Validates elasticity section
- `validate_simulation_params()` - Validates simulation section
- `print_config_summary(config)` - Human-readable configuration display

**Configuration Structure:**
```r
config <- list(
  regional = list(dwellings, population, parking_difficulty, geographic_density),
  costs = list(driver_hourly_rate, cost_per_kg_wash, cost_per_kg_dry, overhead_per_week, fuel_per_km),
  pricing = list(wash_price, dry_price, self_check_discount, subscription_discount_pct),
  capacity = list(num_vans, num_drivers, num_wash_machines, num_dry_machines, operating_hours_per_day),
  randomization = list(demand_scenario, peak_hours_start, peak_hours_end, peak_hour_multiplier, refund_rate, failed_delivery_rate),
  elasticity = list(price_elasticity, self_check_adoption_rate, subscription_ratio),
  simulation = list(start_date, duration_days, time_slot_hours)
)
```

**Validation Returns:**
```r
list(
  valid = TRUE/FALSE,
  errors = character(),   # Blocking errors
  warnings = character()  # Non-blocking warnings
)
```

### R/simulation.R (750 lines)

**Purpose:** Core discrete event simulation engine

**Key Functions:**

- `run_simulation(config, random_seed)` - Main entry point
- `initialize_capacity_state(config)` - Sets up resource tracking
- `create_initial_event_queue(orders)` - Creates event queue from orders
- `process_event_queue(queue, orders, capacity_state, config)` - Main simulation loop
- `handle_pickup_scheduling()` - Schedules pickups
- `handle_pickup_execution()` - Executes pickups
- `handle_washing()` - Simulates washing
- `handle_drying()` - Simulates drying
- `handle_folding()` - Simulates folding
- `handle_delivery_scheduling()` - Schedules deliveries
- `handle_delivery_execution()` - Executes deliveries
- `check_resource_availability()` - Checks if resource is free
- `reserve_resource()` - Reserves resource until time
- `identify_bottlenecks()` - Analyzes capacity logs for bottlenecks
- `calculate_summary_stats()` - High-level statistics

**Order Lifecycle:**
```
placed → pickup_scheduled → pickup_executed → intake →
washing → drying → folding → delivery_scheduled → delivered
```

**Event Processing:**
```r
# Event structure
event <- list(
  event_time = POSIXct,
  event_type = "schedule_pickup" | "execute_pickup" | "washing" | ...,
  order_id = integer
)

# Events processed in chronological order
# Each event may create new events (e.g., washing complete → start drying)
```

### R/randomization.R (440 lines)

**Purpose:** Order generation with realistic patterns

**Key Functions:**

- `generate_orders(config, random_seed)` - Main order generation function
- `calculate_base_demand(config)` - Demand based on scenario and elasticity
- `generate_placement_times()` - Order times with peak hour patterns
- `generate_service_types()` - Service type distribution
- `generate_order_sizes()` - Order sizes in kg
- `generate_geographic_distribution()` - Address clustering
- `generate_time_preferences()` - Pickup/delivery windows
- `apply_randomization_effects()` - Refunds and failures

**Demand Modeling:**
```r
# Base: 0.5% weekly market penetration
# Scenario multiplier: pessimistic 0.6x, realistic 1.0x, optimistic 1.5x
# Price elasticity: demand adjusts based on pricing
# Result: Realistic order volume for simulation period
```

**Order Data Frame:**
```r
orders <- data.frame(
  order_id, placement_time, preferred_pickup_time, preferred_delivery_time,
  service_type, kg_estimate, is_subscription, self_check_enabled,
  complexity_factor, route_cluster, address_lat, address_lon, parking_difficulty
)
```

### R/routing.R (276 lines)

**Purpose:** Delivery routing and logistics

**Key Functions:**

- `calculate_route_distance(lat1, lon1, lat2, lon2)` - Manhattan distance
- `calculate_travel_time(distance_km, hour_of_day, parking_difficulty)` - Time with traffic
- `calculate_route_metrics()` - Total time/distance for multi-stop route
- `assign_routes(orders, time_slot, available_vans)` - Route assignment
- `calculate_route_cost()` - Driver + fuel costs
- `simulate_traffic_variability()` - Random traffic delays

**Traffic Modeling:**
```r
# Base speed: 30 km/h
# Rush hours (8-10 AM, 6-8 PM): 1.5x slower
# Midday (11-5 PM): 1.2x slower
# Off-peak: Normal speed
```

**Parking Difficulty:**
```r
# Scale 1-10
# Time: 2 min (easy) to 15 min (very difficult)
# Linear: parking_time = ((difficulty - 1) / 9) * 13 + 2
```

### R/financial.R (372 lines)

**Purpose:** Financial calculations and analysis

**Key Functions:**

- `calculate_revenue(orders, config)` - Revenue with multi-tier discounts
- `calculate_operational_costs(orders, config)` - Wash/dry/overhead costs
- `calculate_delivery_costs(capacity_log, orders, config)` - Driver/fuel costs
- `calculate_total_costs()` - Aggregate all cost categories
- `calculate_profit_loss()` - P&L statement
- `calculate_breakeven()` - Break-even analysis
- `calculate_financial_summary()` - Master function

**Revenue Calculation:**
```r
# 1. Base revenue by service type
# 2. Apply self-check discount (flat amount)
# 3. Apply subscription discount (percentage on remaining)
# 4. Handle refunds (set revenue to 0)
```

**Break-even Formula:**
```r
# Fixed costs: overhead
# Variable costs: wash + dry + delivery (per order)
# Contribution margin: revenue - variable costs (per order)
# Break-even orders: fixed costs / contribution margin
```

### R/operations.R (386 lines)

**Purpose:** Operational metrics and analysis

**Key Functions:**

- `calculate_resource_utilization()` - Utilization for all resources
- `identify_bottlenecks()` - Constraint identification (>80% utilization)
- `calculate_service_metrics()` - Completion, refund, failure rates
- `calculate_efficiency_metrics()` - Throughput, cycle time, productivity
- `calculate_operational_summary()` - Master function
- `compare_scenarios()` - Multi-scenario comparison

**Utilization Calculation:**
```r
# Capacity hours = num_resources * operating_hours_per_day * duration_days
# Used hours = estimated from order counts and processing times
# Utilization % = (used_hours / capacity_hours) * 100
```

**Bottleneck Definition:**
```r
# Bottleneck: Resource with ≥80% utilization
# Primary bottleneck: Resource with highest utilization
# Headroom: 100% - utilization%
```

### app.R (850 lines)

**Purpose:** Shiny web application

**UI Structure:**
- Sidebar: All configuration inputs + run button
- Main panel: 5 tabs (Summary, Financial, Operations, Scenarios, About)

**Server Logic:**
- `build_config()` - Reactive config from inputs
- `run_simulation` observer - Executes simulation on button click
- Chart outputs - Plotly interactive charts
- Comparison management - Add/clear scenarios

**Reactive Flow:**
```
User changes input → build_config() updates →
User clicks "Run" → Validation → Simulation →
Results stored in reactiveVal →
Charts/tables automatically update
```

---

## Development Workflow

### Setting Up Development Environment

```r
# 1. Clone repository
git clone https://github.com/numbersmart/fulo-simulate.git
cd fulo-simulate

# 2. Open R/RStudio
# Set working directory to project root

# 3. Install renv (if not already installed)
install.packages("renv")

# 4. Restore dependencies
renv::restore()

# 5. Test installation
source("R/utils.R")
check_dependencies()

# 6. Run app
shiny::runApp()
```

### Making Changes

1. **Create feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make changes**
   - Edit R files in `R/` directory
   - Follow coding standards (see `docs/coding_standards.md`)
   - Add roxygen2 documentation to functions

3. **Test changes**
   - Run relevant test scripts (`test_phase4.R`, `test_phase5.R`)
   - Launch Shiny app and verify functionality
   - Test with all three preset scenarios

4. **Document changes**
   - Update function documentation (roxygen2)
   - Update user guide if user-facing changes
   - Update this developer guide if architecture changes
   - Add entry to CHANGELOG.md

5. **Commit and push**
   ```bash
   git add .
   git commit -m "feat: description of changes"
   git push origin feature/your-feature-name
   ```

6. **Create pull request**
   - Describe changes
   - Reference any related issues
   - Request review

### Adding a New Feature

**Example: Adding a new cost category**

1. **Update inputs.R:**
   ```r
   # Add to validate_cost_params()
   if (config$costs$new_cost_category < 0) {
     errors <- c(errors, "new_cost_category must be non-negative")
   }
   ```

2. **Update financial.R:**
   ```r
   # Add to calculate_operational_costs()
   new_cost <- config$costs$new_cost_category * some_multiplier
   total_operational_cost <- wash_cost + dry_cost + overhead_cost + new_cost

   # Add to breakdown
   breakdown = list(
     wash = ...,
     dry = ...,
     overhead = ...,
     new_category = new_cost
   )
   ```

3. **Update app.R:**
   ```r
   # Add input in sidebar
   numericInput("new_cost_category", "New Cost (€):", value = 100, min = 0)

   # Add to build_config()
   costs = list(
     ...,
     new_cost_category = input$new_cost_category
   )

   # Update cost breakdown pie chart
   data <- data.frame(
     Category = c("Wash", "Dry", "Overhead", "Driver", "Fuel", "New"),
     Amount = c(..., breakdown$new_category)
   )
   ```

4. **Update configs:**
   ```json
   {
     "costs": {
       ...,
       "new_cost_category": 100
     }
   }
   ```

5. **Test:**
   - Run simulation with new cost
   - Verify appears in financial tab
   - Check breakdown chart includes new category

---

## Testing

### Manual Testing

**Test Scenarios:**
1. Load each preset (realistic, pessimistic, optimistic)
2. Run simulation
3. Verify results are reasonable
4. Check all tabs display correctly
5. Add to scenario comparison
6. Repeat with custom configuration

**Test Cases:**
```r
# Realistic scenario
- Revenue: €3,000-5,000 for 7 days
- Costs: €2,500-4,000
- Profit: €500-1,500 (10-25% margin)
- Break-even: 150-250 orders
- Primary bottleneck: Usually vans or wash machines

# Pessimistic scenario
- Revenue: €1,500-2,500
- Costs: €2,000-3,500
- Profit: Negative to €500 (0-10% margin or loss)
- Break-even: 250-400 orders
- Primary bottleneck: Often none (underutilized)

# Optimistic scenario
- Revenue: €5,000-8,000
- Costs: €3,000-5,000
- Profit: €2,000-3,500 (25-40% margin)
- Break-even: 100-150 orders
- Primary bottleneck: Vans or wash machines (>85%)
```

### Automated Testing

**Phase 4 Tests** (`test_phase4.R`):
- Order generation with all scenarios
- Routing calculations
- Config validation

**Phase 5 Tests** (`test_phase5.R`):
- Full simulation runs
- Financial calculations
- Operational metrics
- Scenario comparison

**Running Tests:**
```r
# Test Phase 4
source("test_phase4.R")

# Test Phase 5
source("test_phase5.R")
```

### Unit Testing (Future Enhancement)

Consider adding `testthat` framework:

```r
# Example test structure
test_that("revenue calculation applies discounts correctly", {
  orders <- data.frame(
    service_type = "wash_dry",
    is_subscription = TRUE,
    self_check_enabled = TRUE
  )
  config <- list(
    pricing = list(
      wash_price = 7,
      dry_price = 8,
      self_check_discount = 2,
      subscription_discount_pct = 0.15
    )
  )

  result <- calculate_revenue(orders, config)

  # Base: 7 + 8 = 15
  # After self-check: 15 - 2 = 13
  # After subscription: 13 * 0.85 = 11.05
  expect_equal(result$orders_with_revenue$final_revenue[1], 11.05, tolerance = 0.01)
})
```

---

## Contributing

### Code Review Process

1. **Pull requests must:**
   - Pass all existing tests
   - Include tests for new functionality
   - Follow coding standards
   - Include documentation updates
   - Have descriptive commit messages

2. **Review criteria:**
   - Code quality and readability
   - Performance impact
   - User experience changes
   - Documentation completeness

### Commit Message Format

Follow conventional commits:

```
<type>: <description>

[optional body]

[optional footer]
```

**Types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation only
- `style`: Code style (formatting, no logic change)
- `refactor`: Code refactoring
- `test`: Adding tests
- `chore`: Maintenance tasks

**Examples:**
```
feat: Add traffic variability to routing calculations

Implements random variation (±20%) to simulate real-world
traffic unpredictability in delivery time estimates.

Closes #42
```

```
fix: Correct break-even calculation for zero fixed costs

Division by zero occurred when overhead set to 0.
Now returns Inf for break-even orders in this case.
```

---

## Code Standards

See `docs/coding_standards.md` for complete standards.

**Key Points:**

- **Style:** Follow tidyverse style guide
- **Documentation:** roxygen2 for all exported functions
- **Naming:** snake_case for functions and variables
- **Constants:** UPPER_CASE for constants
- **Comments:** Explain "why" not "what"
- **Assumptions:** Mark with "ASSUMPTION:" prefix

**Example Function:**
```r
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
  # ASSUMPTION: Self-check discount applied first, then subscription discount

  # Extract pricing parameters
  wash_price <- config$pricing$wash_price
  dry_price <- config$pricing$dry_price

  # ... implementation

  return(list(
    total_revenue = total_revenue,
    avg_revenue_per_order = total_revenue / nrow(orders)
  ))
}
```

---

## Deployment

### Shiny Server Deployment

**Option 1: ShinyApps.io (Cloud)**

```r
# Install rsconnect
install.packages("rsconnect")

# Configure account
rsconnect::setAccountInfo(
  name="your-account",
  token="your-token",
  secret="your-secret"
)

# Deploy
rsconnect::deployApp(appDir = ".", appName = "fulo-simulate")
```

**Option 2: Shiny Server (Self-hosted)**

1. Install Shiny Server on Linux server
2. Copy app to `/srv/shiny-server/fulo-simulate/`
3. Configure server at `http://your-server:3838/fulo-simulate/`

**Option 3: Docker**

```dockerfile
FROM rocker/shiny:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    libcurl4-gnutls-dev \
    libssl-dev

# Copy app
COPY . /srv/shiny-server/fulo-simulate

# Install R packages
RUN R -e "renv::restore()"

# Expose port
EXPOSE 3838

# Run app
CMD ["/usr/bin/shiny-server"]
```

### Environment Variables

For production deployment, consider externalizing:

- Database connections (if added)
- API keys (if integrated with external services)
- Feature flags

**Example `.Renviron`:**
```
FULO_ENV=production
FULO_LOG_LEVEL=info
```

### Performance Optimization

**For large simulations (30+ days, optimistic demand):**

1. **Caching:** Cache simulation results
2. **Parallelization:** Use `future` package for parallel processing
3. **Database:** Store results in database instead of reactive values
4. **Sampling:** Reduce order volume for preview, full run on demand

---

## API Documentation (Future Enhancement)

Consider adding Plumber API for programmatic access:

```r
#* Run simulation
#* @param config:list Configuration object
#* @post /simulate
function(config) {
  results <- run_simulation(config)
  financial <- calculate_financial_summary(results, config)
  operational <- calculate_operational_summary(results, config)

  list(
    simulation = results,
    financial = financial,
    operational = operational
  )
}
```

---

## Troubleshooting Development Issues

**renv issues:**
```r
# Reset renv if corrupted
renv::deactivate()
renv::activate()
renv::restore()
```

**Shiny reactivity issues:**
```r
# Use browser() to debug reactive expressions
observe({
  browser()
  # Inspect reactive values here
})
```

**Memory issues:**
```r
# Clear workspace
rm(list = ls())
gc()

# Check object sizes
pryr::object_size(simulation_results)
```

---

**End of Developer Guide** | Version 1.0.0 | © 2026 Fulo Simulate
