# Coding Standards for Fulo Simulate

This document defines the coding standards and best practices for the Fulo Simulate project.

## Overview

Fulo Simulate is an internal simulation tool that must be maintainable by team members with varying levels of R expertise. Therefore, code clarity and documentation are paramount.

## Core Principles

1. **Clarity over Cleverness**: Write code that is easy to understand, not code that is clever or terse
2. **Document Everything**: Every function, complex logic block, and assumption must be documented
3. **No Magic Numbers**: All constants must be named and explained
4. **Reproducible Results**: Use random seeds, version control, and deterministic logic
5. **Fail Fast**: Validate inputs early and provide clear error messages

## Style Guide

We follow the **tidyverse style guide** with a few modifications.

### File Organization

- One module per file (e.g., `simulation.R`, `financial.R`)
- Source files in `R/` directory
- File names use snake_case: `my_module.R`
- Main application in `app.R` at root level

### Naming Conventions

```r
# Variables and functions: snake_case
order_count <- 100
calculate_revenue <- function(orders) { ... }

# Constants: SCREAMING_SNAKE_CASE
MAX_VAN_CAPACITY_KG <- 100
DEFAULT_WASH_PRICE_EUR <- 7

# Private/internal functions: prefix with dot
.internal_helper <- function() { ... }
```

### Function Documentation

**Every function must have roxygen2 documentation:**

```r
#' Brief Description (One Sentence)
#'
#' Longer description explaining what the function does,
#' any important assumptions, and how it fits into the workflow.
#'
#' @param param1 Description of parameter 1, including units and constraints
#' @param param2 Description of parameter 2
#'
#' @return Description of return value, including structure and units
#' @export  # Only if function should be user-facing
#'
#' @examples
#' result <- my_function(param1 = 10, param2 = "value")
my_function <- function(param1, param2) {
  # Implementation
}
```

### Inline Comments

**When to comment:**

- Complex algorithms or logic
- Non-obvious business rules
- Assumptions and their justification
- Workarounds or temporary solutions
- References to external sources

**What NOT to comment:**

- Obvious operations (don't comment `x <- x + 1` as "increment x")
- Code that can be made self-explanatory with better naming

**Example:**

```r
# GOOD: Explains WHY
# Apply price elasticity to model demand response
# Formula from Economics 101: Q = Q0 * (P0/P)^elasticity
# Higher elasticity means more sensitivity to price changes
adjusted_demand <- base_demand * (base_price / actual_price)^elasticity

# BAD: Explains WHAT (which is obvious)
# Multiply base demand by price ratio raised to elasticity power
adjusted_demand <- base_demand * (base_price / actual_price)^elasticity
```

### Code Formatting

```r
# Spacing: Use spaces generously
x <- 1  # Good
x<-1    # Bad

# Function calls: Space after comma
func(a, b, c)  # Good
func(a,b,c)    # Bad

# Operators: Space around operators
x <- y + z  # Good
x<-y+z      # Bad

# Line length: Maximum 80 characters
# If longer, break into multiple lines:
long_function_call(
  parameter1 = value1,
  parameter2 = value2,
  parameter3 = value3
)
```

### Control Flow

```r
# Always use curly braces, even for one-liners
if (condition) {
  do_something()
}

# NOT this (even though R allows it)
if (condition) do_something()

# Use early returns for validation
my_function <- function(x) {
  # Validate early and return
  if (is.null(x)) {
    stop("x cannot be NULL")
  }
  if (x < 0) {
    stop("x must be non-negative")
  }

  # Main logic here
  result <- process(x)
  return(result)
}
```

## Constants and Configuration

### Defining Constants

```r
# At top of file or in separate constants.R
# Group related constants

# Time Constants (in minutes)
WASH_TIME_MIN <- 30
WASH_TIME_MAX <- 60
DRY_TIME_MIN <- 40
DRY_TIME_MAX <- 80
FOLDING_TIME_AVG <- 15

# Cost Constants (in EUR)
DRIVER_HOURLY_RATE <- 15
FUEL_COST_PER_KM <- 0.10

# Capacity Constants
MAX_VAN_CAPACITY_KG <- 100
PICKUP_TIME_PER_STOP_MIN <- 20
```

### Documenting Assumptions

```r
# ASSUMPTION: Washing time varies linearly with load size
# Source: Industry standards for commercial washers (60 min for 10kg)
# This may need adjustment based on actual machine performance
calculate_wash_time <- function(kg) {
  base_time_per_kg <- 6  # minutes
  kg * base_time_per_kg
}
```

## Error Handling

### Input Validation

```r
validate_order <- function(order) {
  errors <- character()

  if (is.null(order$weight_kg) || order$weight_kg <= 0) {
    errors <- c(errors, "Weight must be positive")
  }

  if (!order$service_type %in% c("wash", "dry", "wash_dry")) {
    errors <- c(errors, "Invalid service type")
  }

  if (length(errors) > 0) {
    stop("Invalid order: ", paste(errors, collapse = "; "))
  }

  return(TRUE)
}
```

### Clear Error Messages

```r
# GOOD: Actionable error message
if (config$num_vans < 1) {
  stop(
    "Number of vans must be at least 1. ",
    "Current value: ", config$num_vans, ". ",
    "Update config$capacity$num_vans to a positive integer."
  )
}

# BAD: Vague error message
if (config$num_vans < 1) {
  stop("Invalid config")
}
```

## Testing and Validation

### Manual Validation

Every major calculation should be validated against manual calculations:

```r
# Example: Validate revenue calculation
calculate_revenue <- function(orders, config) {
  # ... implementation ...

  # For debugging/validation:
  if (getOption("fulo.debug", FALSE)) {
    cat("Revenue calculation:\n")
    cat("  Orders:", nrow(orders), "\n")
    cat("  Avg price:", mean(revenue_per_order), "\n")
    cat("  Total:", total_revenue, "\n")
  }

  return(total_revenue)
}
```

### Reproducibility

```r
# Always use random seed for reproducibility
run_simulation <- function(config, random_seed = 42) {
  set.seed(random_seed)
  # ... simulation logic ...
}
```

## Performance Considerations

### Vectorization

```r
# GOOD: Vectorized operations
revenue <- orders$price * orders$quantity

# BAD: Loop (slower)
revenue <- numeric(nrow(orders))
for (i in 1:nrow(orders)) {
  revenue[i] <- orders$price[i] * orders$quantity[i]
}
```

### Pre-allocation

```r
# GOOD: Pre-allocate vectors
n <- 1000
results <- numeric(n)
for (i in 1:n) {
  results[i] <- expensive_calculation(i)
}

# BAD: Growing vectors (very slow)
results <- c()
for (i in 1:n) {
  results <- c(results, expensive_calculation(i))
}
```

## Data Structures

### Use Data Frames for Tabular Data

```r
# GOOD: Data frame for orders
orders <- data.frame(
  order_id = 1:100,
  weight_kg = rnorm(100, mean = 15, sd = 5),
  service_type = sample(c("wash", "dry", "wash_dry"), 100, replace = TRUE),
  price = numeric(100)
)

# Access columns clearly
total_weight <- sum(orders$weight_kg)
```

### Use Lists for Hierarchical Data

```r
# GOOD: Nested list for configuration
config <- list(
  regional = list(
    dwellings = 50000,
    population = 120000
  ),
  costs = list(
    wash_per_kg = 0.25,
    dry_per_kg = 0.40
  )
)

# Access with $
wash_cost <- config$costs$wash_per_kg
```

## Version Control

### Git Commit Messages

```
# Format: <type>: <description>

# Types:
feat: Add new feature
fix: Bug fix
docs: Documentation changes
refactor: Code refactoring
test: Add or update tests
chore: Maintenance tasks

# Examples:
feat: Add price elasticity model to order generation
fix: Correct van utilization calculation
docs: Update user guide with new metrics
refactor: Simplify route assignment algorithm
```

### Branching Strategy

- `main`: Stable, tested code only
- `dev`: Integration branch for development
- `feature/xxx`: Feature branches

### Pre-commit Checklist

Before committing code:

- [ ] All functions have roxygen2 documentation
- [ ] Complex logic has inline comments
- [ ] No magic numbers (all constants named)
- [ ] Code formatted with `styler::style_file()`
- [ ] No obvious errors or warnings
- [ ] Manual testing completed

## Dependencies

### Package Management

Use `renv` for package management:

```r
# Update renv.lock after adding new packages
renv::snapshot()

# Restore packages on new machine
renv::restore()
```

### Loading Packages

```r
# At top of file, explicit about what we use
library(dplyr)     # For data manipulation
library(ggplot2)   # For plotting
library(jsonlite)  # For JSON I/O

# OR use explicit namespace
result <- dplyr::filter(data, condition)
```

## Code Review Checklist

When reviewing code, check for:

- [ ] **Documentation**: All functions have roxygen2 headers
- [ ] **Comments**: Complex logic explained
- [ ] **Constants**: No magic numbers
- [ ] **Naming**: Clear, descriptive names following conventions
- [ ] **Error Handling**: Input validation with clear messages
- [ ] **Performance**: No obvious inefficiencies
- [ ] **Reproducibility**: Random seeds used where needed
- [ ] **Style**: Follows tidyverse style guide
- [ ] **Testing**: Manual validation completed

## Tools

### Formatting

```r
# Auto-format code to match style guide
styler::style_file("R/my_module.R")
styler::style_dir("R/")
```

### Linting

```r
# Check for common issues
lintr::lint("R/my_module.R")
lintr::lint_dir("R/")
```

### Documentation

```r
# Generate documentation from roxygen2 comments
roxygen2::roxygenise()
```

## Examples

### Complete Example Function

```r
#' Calculate Delivery Cost for Route
#'
#' Calculates the total cost of a delivery route including driver time,
#' fuel, and additional time for traffic and parking.
#'
#' ASSUMPTIONS:
#' - Traffic multiplier of 1.5x during peak hours (6-8 PM)
#' - Parking time proportional to difficulty (1-10 scale)
#' - Base time includes loading/unloading at each stop
#'
#' @param route Data frame with columns: stops, total_km, peak_hour (logical)
#' @param config List containing:
#'   - costs$driver_hourly_rate: EUR per hour
#'   - costs$fuel_per_km: EUR per kilometer
#'   - regional$parking_difficulty: 1-10 scale
#'
#' @return Numeric delivery cost in EUR
#' @export
#'
#' @examples
#' route <- data.frame(stops = 5, total_km = 20, peak_hour = TRUE)
#' config <- get_default_config()
#' cost <- calculate_delivery_cost(route, config)
calculate_delivery_cost <- function(route, config) {
  # Validate inputs
  if (route$stops < 1) {
    stop("Route must have at least 1 stop. Current value: ", route$stops)
  }

  # Constants
  BASE_TIME_PER_STOP_MIN <- 20  # minutes for pickup/delivery
  TRAFFIC_PEAK_MULTIPLIER <- 1.5
  PARKING_TIME_PER_DIFFICULTY_MIN <- 10  # minutes per point on 1-10 scale

  # Calculate base time
  base_time_min <- route$stops * BASE_TIME_PER_STOP_MIN

  # Add driving time (assume 30 km/h average in city)
  AVG_SPEED_KMH <- 30
  driving_time_min <- (route$total_km / AVG_SPEED_KMH) * 60

  # Apply traffic multiplier during peak hours
  if (route$peak_hour) {
    driving_time_min <- driving_time_min * TRAFFIC_PEAK_MULTIPLIER
  }

  # Add parking time based on difficulty
  parking_time_min <- route$stops *
    (config$regional$parking_difficulty / 10) *
    PARKING_TIME_PER_DIFFICULTY_MIN

  # Total time in hours
  total_time_hours <- (base_time_min + driving_time_min + parking_time_min) / 60

  # Calculate cost
  driver_cost <- total_time_hours * config$costs$driver_hourly_rate
  fuel_cost <- route$total_km * config$costs$fuel_per_km
  total_cost <- driver_cost + fuel_cost

  return(total_cost)
}
```

---

**Document Version**: 1.0
**Last Updated**: 2026-01-02
**Maintained By**: Fulo Simulate Team
