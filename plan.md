# Fulo Simulate - Engineering Implementation Plan (Alpha Version)

**Project:** Internal simulation engine for Fulo laundry operations
**Technology Stack:** R, Shiny
**Target:** Alpha release for testing with owned laundromats
**Repository:** https://github.com/numbersmart/fulo-simulate

---

## Executive Summary

This plan outlines the implementation of `fulo-simulate`, an R/Shiny-based simulation engine that models Fulo's laundry operations to support business decision-making for regional expansion. The plan is structured for execution across multiple sessions with different specialized agents.

**Key Requirements:**
- Simulate complete operational workflow (order → pickup → processing → delivery)
- Calculate financial outcomes (revenue, costs, margins, break-even)
- Identify operational bottlenecks and capacity constraints
- Provide interactive web interface for non-technical users
- Exceptionally well-documented R code for maintainability

**Alpha Scope:** Core simulation functionality with basic UI and essential documentation.

---

## Implementation Phases

The implementation is divided into 7 phases, each designed to be executed independently or delegated to specialized agents. Each phase includes clear inputs, outputs, and acceptance criteria.

---

## Phase 1: Foundation & Project Setup

**Objective:** Establish project structure, R environment, and development standards.

**Owner:** Senior R Developer or DevOps Agent

**GitHub Issues:** None directly, but foundational for all others

**Tasks:**

1. **Project Structure Setup**
   ```
   fulo-simulate/
   ├── app.R                 # Main Shiny application
   ├── R/
   │   ├── simulation.R      # Core simulation engine
   │   ├── inputs.R          # Input configuration
   │   ├── randomization.R   # Order generation logic
   │   ├── financial.R       # Financial calculations
   │   ├── operations.R      # Operational metrics
   │   ├── routing.R         # Delivery routing logic
   │   └── utils.R           # Utility functions
   ├── data/
   │   └── defaults.json     # Default configuration values
   ├── configs/
   │   ├── pessimistic.json  # Example scenarios
   │   ├── realistic.json
   │   └── optimistic.json
   ├── docs/
   │   └── user_guide.md
   ├── README.md
   ├── renv.lock             # Package dependencies
   └── .gitignore
   ```

2. **R Environment Configuration**
   - Install R (version 4.0+)
   - Set up `renv` for package management
   - Install required packages:
     ```r
     # Core packages
     - shiny (>= 1.7.0)
     - shinydashboard or bslib for UI
     - ggplot2 (>= 3.4.0) for visualizations
     - plotly (>= 4.10.0) for interactive charts
     - jsonlite for configuration files
     - dplyr, tidyr for data manipulation
     - lubridate for date/time handling

     # Documentation
     - roxygen2 for function documentation
     - rmarkdown for guides
     ```

3. **Development Standards**
   - Adopt tidyverse style guide
   - Set up roxygen2 documentation template
   - Create constant definitions file (no magic numbers)
   - Establish commenting standards

4. **Git Configuration**
   - Create `.gitignore` for R projects
   - Set up branch strategy (main for stable, dev for development)
   - Configure pre-commit hooks for style checking (optional)

**Deliverables:**
- [ ] Project directory structure created
- [ ] `renv.lock` file with all dependencies
- [ ] `README.md` with basic project description and setup instructions
- [ ] Development standards documented in `docs/coding_standards.md`

**Acceptance Criteria:**
- R environment can be reproduced on any machine using `renv::restore()`
- All required packages install without errors
- Project structure follows best practices for R/Shiny applications

**Estimated Effort:** 2-4 hours

---

## Phase 2: Core Simulation Engine

**Objective:** Build the fundamental simulation logic that models the complete order lifecycle.

**Owner:** Senior R Developer with simulation/modeling experience

**GitHub Issues:** #7 (Complete order lifecycle), #1 (Simulation Engine Core Epic)

**Dependencies:** Phase 1 complete

**Key Concepts:**

The simulation models discrete events in the Fulo workflow:
1. Order Placement
2. Pickup Scheduling
3. Pickup Execution
4. Laundromat Intake/Scanning
5. Washing
6. Drying
7. Folding
8. Delivery Scheduling
9. Delivery Execution

**Implementation Tasks:**

1. **Define Data Structures** (`R/simulation.R`)
   ```r
   # Order object structure
   - order_id
   - placement_time
   - pickup_time_requested, pickup_time_actual
   - delivery_time_requested, delivery_time_actual
   - weight_kg
   - service_type (wash, dry, wash_dry)
   - has_special_care
   - has_self_check
   - is_subscription
   - status (placed, scheduled, picked_up, washing, drying, folded, out_for_delivery, delivered)
   - assigned_route
   - costs, revenue
   ```

2. **Implement Order Lifecycle State Machine**
   - Function: `simulate_order_lifecycle(order, capacity_state, config)`
   - Track time spent in each stage
   - Check capacity constraints at each step
   - Queue orders when capacity saturated
   - Return updated order and capacity state

3. **Capacity Management**
   - Track available: vans, drivers, machines, operating hours
   - Implement queuing logic when resources exhausted
   - Identify bottlenecks (which resource is limiting)

4. **Time Management**
   - Implement discrete event simulation
   - Process events chronologically
   - Respect 24-48 hour promise window
   - Calculate realistic stage durations:
     - Pickup: 15-30 min per stop
     - Washing: 30-60 min depending on load
     - Drying: 40-80 min depending on load
     - Folding: 10-20 min

5. **Main Simulation Loop**
   ```r
   run_simulation <- function(config, random_seed) {
     # Initialize capacity state
     # Generate all orders (from randomization module)
     # Sort events chronologically
     # Process each event:
     #   - Update order status
     #   - Check capacity
     #   - Queue if needed
     #   - Track metrics
     # Return: list of completed orders, metrics, bottlenecks
   }
   ```

**Deliverables:**
- [ ] `R/simulation.R` with core engine functions
- [ ] Order state machine implementation
- [ ] Capacity management system
- [ ] Bottleneck detection logic
- [ ] Unit tests for key functions (optional but recommended)

**Acceptance Criteria:**
- Simulation processes 1000 orders for 1-week scenario in <5 minutes
- All orders respect 24-48 hour windows
- Bottlenecks correctly identified when capacity hit
- Results are deterministic with same random seed
- Code has comprehensive roxygen2 documentation
- All assumptions documented in comments

**Estimated Effort:** 12-16 hours

---

## Phase 3: Input Configuration System

**Objective:** Create comprehensive input configuration for all simulation parameters.

**Owner:** Backend Developer or R Developer

**GitHub Issues:** #9 (Configure regional and operational inputs), #10 (Configure randomness), #2 (Input Configuration System Epic)

**Dependencies:** Phase 1 complete

**Input Categories:**

1. **Regional Parameters**
   - Number of dwellings: 50000 (default for Madrid neighborhood)
   - Population: 120000
   - Parking difficulty: 7 (1-10 scale, 10 = hardest)
   - Geographic density: "urban" (urban, suburban, rural)

2. **Cost Parameters**
   - Delivery cost per hour: €15
   - Cost per kg washing: €0.25
   - Cost per kg drying: €0.40
   - Overhead cost per week: €500

3. **Pricing Parameters**
   - Wash price per service: €7 (range €6-8)
   - Dry price per service: €8 (range €6-9)
   - Self-check discount: €2
   - Subscription discount: 15%

4. **Capacity Parameters**
   - Number of vans: 3
   - Van capacity: 100 kg
   - Number of washing machines: 10
   - Number of drying machines: 8
   - Number of drivers: 4
   - Operating hours per day: 12

5. **Randomization Parameters**
   - Distribution type: "normal", "uniform", "custom"
   - Random seed: 42 (for reproducibility)
   - Demand scenario: "pessimistic", "realistic", "optimistic"
   - Peak hours: "18:00-20:00"
   - Peak hour multiplier: 3.0
   - Refund rate: 0.02 (2%)
   - Failed delivery rate: 0.05 (5%)

6. **Elasticity Parameters**
   - Price elasticity: 1.5 (how much demand changes with price)
   - Self-check adoption rate: 0.30 (30%)
   - Subscription ratio: 0.20 (20% of customers)

**Implementation Tasks:**

1. **Create Input Data Structure** (`R/inputs.R`)
   ```r
   get_default_config <- function() {
     # Returns list with all default values
     # Organized by category
   }

   validate_config <- function(config) {
     # Validate all inputs
     # Check for negative values, out-of-range, etc.
     # Return list(valid = TRUE/FALSE, errors = c(...))
   }
   ```

2. **JSON Configuration Files** (`data/defaults.json`, `configs/*.json`)
   - Structure JSON with logical sections
   - Include comments explaining each parameter
   - Create example configurations for scenarios

3. **Save/Load Configuration** (`R/utils.R`)
   ```r
   save_config <- function(config, filepath, metadata = list()) {
     # Save config as JSON with metadata
     # Metadata: date, user, description
   }

   load_config <- function(filepath) {
     # Load and validate configuration
     # Return config or error
   }
   ```

4. **Input Validation**
   - Ensure no negative costs
   - Ensure prices within realistic ranges
   - Ensure capacity values are integers > 0
   - Validate time ranges
   - Check that discount doesn't exceed price

**Deliverables:**
- [ ] `R/inputs.R` with configuration functions
- [ ] `data/defaults.json` with sensible defaults
- [ ] `configs/pessimistic.json`, `realistic.json`, `optimistic.json`
- [ ] Input validation with clear error messages
- [ ] Documentation for each parameter

**Acceptance Criteria:**
- All parameters documented with units and ranges
- Validation catches common errors
- Configurations can be saved and loaded successfully
- Default configuration works out-of-box
- Example scenarios represent realistic business cases

**Estimated Effort:** 8-10 hours

---

## Phase 4: Order Generation & Randomization

**Objective:** Implement realistic order generation with configurable randomization.

**Owner:** Data Scientist or R Developer with statistics background

**GitHub Issues:** #11 (Order patterns), #12 (Order characteristics), #13 (Delivery routes), #3 (Randomization Epic)

**Dependencies:** Phase 3 complete (inputs needed)

**Implementation Tasks:**

1. **Time Slot Generation** (`R/randomization.R`)
   ```r
   generate_time_slots <- function(start_date, end_date, slot_duration_hours = 2) {
     # Generate all time slots in simulation period
     # Return data frame: slot_id, start_time, end_time
   }
   ```

2. **Order Volume Generation**
   ```r
   generate_order_volume <- function(config) {
     # Calculate total orders for simulation period
     # Based on: population, dwellings, demand scenario
     # Apply peak hour multipliers
     # Return: orders per time slot
   }
   ```

3. **Order Timing Generation**
   ```r
   generate_order_times <- function(time_slots, volume_per_slot, config) {
     # For each order:
     #   - Placement time (when customer orders)
     #   - Requested pickup time (24-48h in future)
     #   - Requested delivery time (24-48h after pickup)
     # Respect peak hours configuration
     # Return data frame of orders with times
   }
   ```

4. **Order Characteristics Generation**
   ```r
   generate_order_characteristics <- function(orders, config) {
     # For each order:
     #   - Weight (kg): influenced by price elasticity
     #     - Higher price → smaller orders
     #     - Use log-normal distribution
     #   - Service type: wash (30%), dry (20%), wash_dry (50%)
     #   - Special care: 5% of orders
     #   - Self-check: config$self_check_adoption_rate
     #   - Subscription: config$subscription_ratio
     # Return orders with characteristics added
   }
   ```

5. **Price Elasticity Model**
   ```r
   calculate_order_size <- function(base_price, elasticity, mean_kg = 15, sd_kg = 5) {
     # Model: demand decreases as price increases
     # Use elasticity parameter
     # Generate from log-normal distribution
     # Return weight in kg
   }
   ```

6. **Route Assignment (Simple)** (`R/routing.R`)
   ```r
   assign_routes <- function(orders, config) {
     # Group orders by pickup time window and location
     # Apply simple batching:
     #   - Same 2-hour window
     #   - Van capacity constraint (max kg)
     #   - Assign route_id
     # Calculate route costs:
     #   - Base time: 30 min + (15 min × stops)
     #   - Traffic multiplier: 1.5 during peak
     #   - Parking time: (parking_difficulty / 10) × 10 min per stop
     #   - Cost = total_hours × hourly_rate
     # Apply failed delivery rate randomly
     # Return orders with route assignments and costs
   }
   ```

**Deliverables:**
- [ ] `R/randomization.R` with order generation functions
- [ ] `R/routing.R` with simple route assignment
- [ ] Price elasticity model implementation
- [ ] Comprehensive comments explaining distributions
- [ ] Example output showing realistic order patterns

**Acceptance Criteria:**
- Orders distributed across time with peak hours showing higher volume
- Order sizes correlate with pricing (higher price = smaller orders)
- Service types distributed realistically
- Routes respect van capacity constraints
- Randomization is reproducible with same seed
- Code documents all statistical assumptions

**Estimated Effort:** 10-14 hours

---

## Phase 5: Financial & Operational Metrics

**Objective:** Calculate comprehensive financial outcomes and operational metrics.

**Owner:** Backend Developer or Financial Analyst with R skills

**GitHub Issues:** #8 (Financial outcomes), #14 (Operational metrics), #4 (Output Analytics Epic)

**Dependencies:** Phase 2 complete (simulation results needed)

**Implementation Tasks:**

1. **Revenue Calculation** (`R/financial.R`)
   ```r
   calculate_revenue <- function(orders, config) {
     # For each order:
     #   base_revenue = 0
     #   if (wash) base_revenue += config$wash_price
     #   if (dry) base_revenue += config$dry_price
     #   if (self_check) base_revenue -= config$self_check_discount
     #   if (subscription) base_revenue *= (1 - config$subscription_discount)
     # Return: total_revenue, revenue_per_order, revenue_by_service_type
   }
   ```

2. **Cost Calculation**
   ```r
   calculate_costs <- function(orders, routes, config) {
     # Delivery costs: sum of route costs (from Phase 4)
     # Washing costs: sum(orders$weight_kg × config$cost_per_kg_wash)
     # Drying costs: sum(orders$weight_kg × config$cost_per_kg_dry)
     # Refund costs: revenue × config$refund_rate
     # Overhead: config$overhead_per_week × num_weeks
     # Return: breakdown by category and total
   }
   ```

3. **Profit/Loss Calculation**
   ```r
   calculate_profit_loss <- function(revenue, costs) {
     profit = revenue$total - costs$total
     margin = profit / revenue$total
     # Return: profit, margin, cost_per_delivery
   }
   ```

4. **Break-Even Analysis**
   ```r
   calculate_breakeven <- function(fixed_costs, revenue_per_order, variable_cost_per_order) {
     # breakeven_orders = fixed_costs / (revenue_per_order - variable_cost_per_order)
     # Return: orders needed to break even, current status
   }
   ```

5. **Operational Metrics** (`R/operations.R`)
   ```r
   calculate_van_utilization <- function(routes, config) {
     # For each route: actual_kg / van_capacity_kg
     # Return: avg, peak, utilization_distribution
   }

   calculate_time_to_promise <- function(orders) {
     # For each order: delivery_time_actual - pickup_time_actual
     # Return: avg, median, distribution
   }

   identify_bottlenecks <- function(orders, capacity_state) {
     # Analyze where queues formed
     # Which resource was most constrained
     # What time periods saw saturation
     # Return: list of bottlenecks with descriptions
   }

   calculate_resource_utilization <- function(capacity_state, config) {
     # Machine utilization: hours_used / hours_available
     # Driver utilization: hours_worked / hours_available
     # Return: utilization percentages
   }
   ```

6. **Summary Metrics**
   ```r
   generate_summary <- function(orders, routes, config) {
     # Consolidate all metrics
     # Return structured list for display:
     #   - Financial: revenue, costs, profit, margin, breakeven
     #   - Operational: utilization, bottlenecks, efficiency
     #   - Volume: total orders, orders per day, by service type
   }
   ```

**Deliverables:**
- [ ] `R/financial.R` with revenue, cost, profit calculations
- [ ] `R/operations.R` with operational metrics
- [ ] Break-even analysis implementation
- [ ] Bottleneck identification algorithm
- [ ] All formulas documented with references
- [ ] Validation against manual spreadsheet

**Acceptance Criteria:**
- Financial calculations match manual verification
- All key metrics from PR-FAQ FAQ #4 included
- Metrics clearly labeled with units
- Bottlenecks correctly identified based on capacity constraints
- Break-even analysis provides actionable insights

**Estimated Effort:** 8-10 hours

---

## Phase 6: Shiny UI Development

**Objective:** Build functional web interface for configuring inputs and viewing results.

**Owner:** Full-stack Developer or Shiny Specialist

**GitHub Issues:** #9 (Input configuration), #10 (Randomization config), #16 (Run simulation), #17 (Save/load), #15 (Visualizations), #5 (Shiny UI Epic)

**Dependencies:** Phases 2, 3, 4, 5 complete

**UI Structure:**

```
┌─────────────────────────────────────────────┐
│ Fulo Simulate - Business Planning Tool     │
├─────────────────────────────────────────────┤
│                                             │
│  ┌─────────────┐  ┌────────────────────┐  │
│  │  Sidebar    │  │  Main Panel        │  │
│  │             │  │                    │  │
│  │ - Regional  │  │  Results Dashboard │  │
│  │ - Costs     │  │  - Summary Metrics │  │
│  │ - Pricing   │  │  - Charts          │  │
│  │ - Capacity  │  │  - Tables          │  │
│  │ - Random    │  │                    │  │
│  │             │  │                    │  │
│  │ [Run]       │  │                    │  │
│  │ [Save]      │  │                    │  │
│  │ [Load]      │  │                    │  │
│  └─────────────┘  └────────────────────┘  │
│                                             │
└─────────────────────────────────────────────┘
```

**Implementation Tasks:**

1. **App Structure** (`app.R`)
   ```r
   library(shiny)
   library(shinydashboard) # or bslib

   source("R/simulation.R")
   source("R/inputs.R")
   source("R/randomization.R")
   source("R/financial.R")
   source("R/operations.R")
   source("R/routing.R")

   ui <- dashboardPage(...)
   server <- function(input, output, session) {...}
   shinyApp(ui, server)
   ```

2. **Input Sidebar** (UI Component)
   - Tabbed sections for each input category
   - Use appropriate widgets:
     - `numericInput()` for numbers
     - `sliderInput()` for ranges
     - `selectInput()` for choices (distribution types, scenarios)
     - `textInput()` for strings
   - Add help text with `helpText()` or tooltips
   - Validate inputs reactively

3. **Configuration Management** (Server Logic)
   ```r
   # Save configuration
   observeEvent(input$save_btn, {
     config <- get_current_config()
     save_config(config, input$save_filename)
     showNotification("Configuration saved!")
   })

   # Load configuration
   observeEvent(input$load_btn, {
     config <- load_config(input$load_file$datapath)
     update_inputs(config) # Update UI inputs
     showNotification("Configuration loaded!")
   })
   ```

4. **Run Simulation** (Server Logic)
   ```r
   observeEvent(input$run_btn, {
     # Disable button
     updateActionButton(session, "run_btn", label = "Running...",
                        icon = icon("spinner"))

     # Show progress
     withProgress(message = "Running simulation...", {
       # Get config from inputs
       config <- get_current_config()

       # Run simulation
       incProgress(0.2, detail = "Generating orders...")
       orders <- generate_orders(config)

       incProgress(0.4, detail = "Simulating lifecycle...")
       results <- run_simulation(orders, config)

       incProgress(0.6, detail = "Calculating metrics...")
       metrics <- generate_summary(results, config)

       incProgress(0.8, detail = "Creating visualizations...")
       # Store results for display
       results_reactive(metrics)
     })

     # Re-enable button
     updateActionButton(session, "run_btn", label = "Run Simulation")
   })
   ```

5. **Results Display** (UI + Server)
   - **Summary Tab:**
     - Value boxes for key metrics (revenue, costs, profit, margin)
     - Table of operational metrics
     - Bottleneck warnings (if any)

   - **Financial Tab:**
     - Revenue breakdown (by service type)
     - Cost breakdown (pie chart)
     - Revenue vs Cost comparison chart
     - Break-even analysis display

   - **Operations Tab:**
     - Van utilization chart (line chart over time)
     - Resource utilization gauges
     - Bottleneck identification with explanations

   - **Orders Tab:**
     - Order volume over time (bar chart)
     - Service type distribution (pie chart)
     - Order table with filters

6. **Visualization Implementation** (`R/visualizations.R` or in `app.R`)
   ```r
   output$revenue_cost_chart <- renderPlotly({
     plot_ly() %>%
       add_trace(type = 'bar', name = 'Revenue', ...) %>%
       add_trace(type = 'bar', name = 'Cost', ...) %>%
       layout(title = "Revenue vs Cost", barmode = 'group')
   })

   output$cost_breakdown <- renderPlotly({
     plot_ly() %>%
       add_trace(type = 'pie', labels = ~category, values = ~amount) %>%
       layout(title = "Cost Breakdown")
   })

   output$van_utilization <- renderPlotly({
     plot_ly() %>%
       add_trace(type = 'scatter', mode = 'lines', ...) %>%
       layout(title = "Van Utilization Over Time",
              xaxis = list(title = "Time"),
              yaxis = list(title = "Utilization %"))
   })
   ```

**Deliverables:**
- [ ] `app.R` with complete Shiny application
- [ ] Input sidebar with all configuration options
- [ ] Run simulation button with progress indicator
- [ ] Save/load configuration functionality
- [ ] Results dashboard with key metrics
- [ ] Interactive charts and visualizations
- [ ] Error handling and user feedback

**Acceptance Criteria:**
- Non-technical users can configure and run simulations
- UI is functional and intuitive
- Progress indicator shows during simulation
- Results display clearly with charts and tables
- Save/load works correctly with validation
- App loads in <5 seconds
- No crashes from normal user interactions

**Estimated Effort:** 14-18 hours

---

## Phase 7: Documentation & Polish

**Objective:** Create comprehensive documentation and finalize code quality.

**Owner:** Technical Writer or Senior Developer

**GitHub Issues:** #18 (Code documentation), #19 (README and user guide), #6 (Documentation Epic)

**Dependencies:** Phases 2-6 complete

**Implementation Tasks:**

1. **Code Documentation** (All `R/*.R` files)
   - Add roxygen2 headers to every function:
     ```r
     #' Calculate Revenue from Orders
     #'
     #' Calculates total revenue based on orders and pricing configuration.
     #' Applies self-check discounts and subscription discounts as applicable.
     #'
     #' @param orders Data frame of orders with service types and discounts
     #' @param config List containing pricing parameters (wash_price, dry_price, etc.)
     #' @return List with total_revenue, revenue_per_order, revenue_by_service_type
     #' @examples
     #' config <- get_default_config()
     #' orders <- generate_orders(config)
     #' revenue <- calculate_revenue(orders, config)
     #' @export
     calculate_revenue <- function(orders, config) {
       # Implementation...
     }
     ```

   - Add inline comments for complex logic:
     ```r
     # Apply price elasticity to determine order size
     # Formula: size = base_size * (base_price / actual_price)^elasticity
     # Higher elasticity means more sensitivity to price changes
     ```

   - Document all assumptions:
     ```r
     # ASSUMPTION: Washing takes 30-60 minutes depending on load size
     # Source: Industry standards for commercial washers
     WASH_TIME_MIN <- 30  # minutes
     WASH_TIME_MAX <- 60  # minutes
     ```

   - Remove all magic numbers:
     ```r
     # BAD
     cost <- hours * 15

     # GOOD
     DRIVER_HOURLY_RATE <- 15  # EUR per hour
     cost <- hours * DRIVER_HOURLY_RATE
     ```

2. **README.md**
   - Project overview and purpose
   - Installation instructions:
     ```markdown
     ## Installation

     ### Prerequisites
     - R version 4.0 or higher
     - RStudio (recommended)

     ### Setup
     1. Clone the repository:
        ```bash
        git clone https://github.com/numbersmart/fulo-simulate.git
        cd fulo-simulate
        ```

     2. Install dependencies:
        ```r
        install.packages("renv")
        renv::restore()
        ```

     3. Run the application:
        ```r
        shiny::runApp()
        ```
     ```

   - Quick start guide
   - Links to detailed documentation

3. **User Guide** (`docs/user_guide.md`)
   - Introduction to the simulation tool
   - How to configure inputs:
     - Regional parameters (what they mean, how to estimate)
     - Cost parameters (where to get data)
     - Pricing parameters (how to test scenarios)
     - Randomization parameters (understanding distributions)

   - How to run simulations:
     - Step-by-step with screenshots
     - How to interpret progress
     - What to do if errors occur

   - How to interpret results:
     - Explanation of each metric
     - What "good" looks like
     - How to identify problems
     - Example interpretations

   - How to save and share configurations

   - Troubleshooting common issues

4. **Example Configurations** (`configs/*.json`)
   - **Pessimistic Scenario:**
     - Low demand (75% of realistic)
     - High costs (delivery +20%, operations +10%)
     - Low prices (to attract customers)
     - High refund rate (5%)

   - **Realistic Scenario:**
     - Base case from current data
     - Standard costs and pricing
     - Typical refund/failure rates

   - **Optimistic Scenario:**
     - High demand (125% of realistic)
     - Lower costs (efficiency gains)
     - Premium pricing
     - Low refund rate (1%)

   - Document the rationale for each scenario

5. **Metrics Interpretation Guide** (`docs/metrics_guide.md`)
   - **Financial Metrics:**
     - Total Revenue: What it means, how it's calculated
     - Total Costs: Breakdown and drivers
     - Profit/Loss: Interpretation, targets
     - Cost per Delivery: Benchmarks, how to improve
     - Break-even: How to use this for planning

   - **Operational Metrics:**
     - Van Utilization: What's optimal, issues with too high/low
     - Machine Utilization: Capacity planning implications
     - Time to Promise: Customer experience impact
     - Bottlenecks: How to address each type

   - Example scenarios with interpretations

6. **Code Style and Quality**
   - Run styler to format code:
     ```r
     styler::style_dir("R/")
     ```

   - Check for common issues:
     ```r
     lintr::lint_dir("R/")
     ```

   - Verify documentation:
     ```r
     roxygen2::roxygenise()
     ```

**Deliverables:**
- [ ] All functions have roxygen2 documentation
- [ ] Complex logic has inline comments
- [ ] All assumptions documented
- [ ] No magic numbers in code
- [ ] Code formatted with tidyverse style
- [ ] README.md with installation and quick start
- [ ] User guide (docs/user_guide.md)
- [ ] Metrics interpretation guide (docs/metrics_guide.md)
- [ ] Three example configurations with rationales
- [ ] Troubleshooting guide

**Acceptance Criteria:**
- Non-R developers can understand code flow by reading comments
- New users can set up and run simulation using README alone
- User guide answers common questions
- Example configurations represent realistic business scenarios
- All documentation in English

**Estimated Effort:** 10-14 hours

---

## Testing & Validation Plan

Throughout development, validate the simulation against these criteria:

1. **Correctness:**
   - [ ] Financial calculations match manual spreadsheet
   - [ ] Bottlenecks identified match manual analysis
   - [ ] Orders respect time constraints (24-48h windows)
   - [ ] Capacity constraints honored (no overbooking)

2. **Performance:**
   - [ ] 1-week simulation with 1000 orders completes in <5 minutes
   - [ ] UI remains responsive during simulation
   - [ ] Charts render in <2 seconds

3. **Reproducibility:**
   - [ ] Same inputs + same seed = identical results
   - [ ] Saved configurations reload correctly
   - [ ] Results are explainable and auditable

4. **Usability:**
   - [ ] Non-technical user can run simulation without help
   - [ ] Error messages are clear and actionable
   - [ ] Results are interpretable without technical knowledge

5. **Code Quality:**
   - [ ] All functions documented
   - [ ] No magic numbers
   - [ ] Style guide followed
   - [ ] No obvious performance bottlenecks

---

## Execution Strategy for Multiple Sessions

### Session 1: Foundation (2-4 hours)
- **Agent:** DevOps or Senior R Developer
- **Phases:** Phase 1
- **Goal:** Project structure and environment ready

### Session 2: Core Engine (12-16 hours)
- **Agent:** Senior R Developer with simulation experience
- **Phases:** Phase 2
- **Goal:** Simulation engine working with test data

### Session 3: Inputs & Randomization (18-24 hours)
- **Agent:** Data Scientist or R Developer
- **Phases:** Phase 3 + Phase 4
- **Goal:** Realistic order generation with configurable inputs
- **Can be parallelized:** Phase 3 and Phase 4 can be done by different agents simultaneously if Phase 1 is complete

### Session 4: Metrics & Analytics (8-10 hours)
- **Agent:** Backend Developer or Financial Analyst with R
- **Phases:** Phase 5
- **Goal:** Complete financial and operational metrics

### Session 5: UI Development (14-18 hours)
- **Agent:** Full-stack Developer or Shiny Specialist
- **Phases:** Phase 6
- **Goal:** Functional Shiny app with all features

### Session 6: Documentation (10-14 hours)
- **Agent:** Technical Writer or Senior Developer
- **Phases:** Phase 7
- **Goal:** Production-ready documentation

### Session 7: Testing & Refinement (8-12 hours)
- **Agent:** QA or Product Manager
- **Activities:** End-to-end testing, bug fixes, user acceptance
- **Goal:** Alpha release ready

**Total Estimated Effort:** 72-98 hours (9-12 full working days)

---

## Acceptance Criteria for Alpha Release

The alpha version is ready when:

- [ ] **Functional Completeness:**
  - [ ] Users can configure all input parameters
  - [ ] Simulation runs successfully for 1-week scenarios
  - [ ] All key financial metrics calculated and displayed
  - [ ] All key operational metrics calculated and displayed
  - [ ] Bottlenecks identified and explained
  - [ ] Results visualized with charts

- [ ] **Usability:**
  - [ ] Non-technical user can run simulation following README
  - [ ] Configurations can be saved and loaded
  - [ ] Example configurations work out-of-box

- [ ] **Performance:**
  - [ ] 1-week simulation completes in <5 minutes
  - [ ] UI loads in <5 seconds

- [ ] **Quality:**
  - [ ] All functions have roxygen2 documentation
  - [ ] Complex logic has explanatory comments
  - [ ] No magic numbers in code
  - [ ] Code follows tidyverse style guide
  - [ ] README and user guide complete

- [ ] **Validation:**
  - [ ] Financial calculations validated against manual spreadsheet
  - [ ] Results are reproducible with same inputs
  - [ ] Eduardo (Product Owner) approves functionality

---

## Risk Mitigation

| Risk | Impact | Mitigation |
|------|--------|------------|
| Simulation doesn't match reality | High | Start simple, validate with owned laundromats, iterate |
| Performance issues with large scenarios | Medium | Profile code, optimize bottlenecks, limit alpha to 1-week scenarios |
| R package dependency conflicts | Medium | Use renv for dependency management, lock versions |
| Non-technical users can't operate tool | High | Extensive user testing with Eduardo, improve UI based on feedback |
| Code becomes unmaintainable | High | Enforce documentation standards, code reviews |
| Assumptions are invalid | Medium | Document all assumptions clearly, make them configurable |

---

## Future Enhancements (Post-Alpha)

These are explicitly out of scope for alpha but noted for future development:

- Multi-week/multi-month simulations
- Multi-region simultaneous simulation
- Historical data integration for more accurate randomization
- Seasonal patterns (summer vs winter demand)
- Advanced route optimization algorithms
- Machine learning-based demand prediction
- Real-time integration with production systems
- Automated testing suite
- Multi-user support with authentication
- Mobile-responsive UI
- Export to PowerPoint/PDF for presentations

---

## Questions for Product Owner (Eduardo)

Before starting implementation, clarify:

1. **Data Availability:**
   - Do we have real data from owned laundromats to validate against?
   - What are the actual costs per kg for washing and drying?
   - What is the actual driver hourly rate?

2. **Business Logic:**
   - Can multiple customer orders be consolidated into same washing machine?
   - How do we handle special care items (if at all in alpha)?
   - What is the actual pricing strategy (fixed vs variable)?

3. **Success Criteria:**
   - What decisions will this simulation inform for alpha?
   - What accuracy level is needed for alpha vs production?
   - Who are the primary users besides you?

4. **Constraints:**
   - Any hard deadlines for alpha release?
   - Any technical constraints (must run on specific infrastructure)?
   - Any security/data privacy requirements?

---

## Getting Started

To begin implementation:

1. **Review this plan** with Eduardo and technical team
2. **Answer clarifying questions** above
3. **Set up Phase 1** (Foundation) - can be done independently
4. **Assign agents** to subsequent phases based on availability
5. **Schedule checkpoints** after Phases 2, 4, and 6 for progress review

For each session, the assigned agent should:
1. Read the relevant phase section carefully
2. Review dependencies (prior phases must be complete)
3. Create a git branch for their work
4. Follow the tasks sequentially
5. Test their deliverables against acceptance criteria
6. Create a pull request for code review
7. Update project status in GitHub issues

---

**Document Version:** 1.0
**Last Updated:** 2026-01-02
**Author:** Claude (AI Assistant)
**Approved By:** [Pending - Eduardo]
