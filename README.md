# Fulo Simulate - Business Simulation Engine

An R/Shiny-based simulation engine for modeling Fulo's laundry operations to support data-driven business decisions for regional expansion.

## Overview

Fulo Simulate models the complete operational workflow of Fulo's on-demand laundry service, from order placement through pickup, processing, and delivery. It provides:

- **Financial Analysis**: Revenue, costs, margins, and break-even calculations
- **Operational Insights**: Capacity utilization, bottleneck identification, efficiency metrics
- **Scenario Planning**: Test pessimistic, realistic, and optimistic business scenarios
- **Interactive Interface**: Web-based Shiny app for non-technical users

## Features

- ✅ Complete order lifecycle simulation (placement → pickup → washing → drying → delivery)
- ✅ Configurable inputs for regional parameters, costs, pricing, and capacity
- ✅ Realistic order generation with price elasticity modeling
- ✅ Delivery route optimization with traffic and parking constraints
- ✅ Comprehensive financial and operational metrics
- ✅ Interactive visualizations and dashboards
- ✅ Save/load scenario configurations
- ✅ Well-documented, maintainable R code

## Prerequisites

- **R**: Version 4.0 or higher ([Download R](https://cran.r-project.org/))
- **RStudio**: Recommended IDE ([Download RStudio](https://posit.co/download/rstudio-desktop/))
- **Git**: For version control ([Download Git](https://git-scm.com/downloads))

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/numbersmart/fulo-simulate.git
cd fulo-simulate
```

### 2. Install R Package Dependencies

This project uses `renv` for reproducible package management.

```r
# Install renv if you don't have it
install.packages("renv")

# Restore project dependencies
renv::restore()
```

This will install all required packages as specified in `renv.lock`.

### 3. Verify Installation

```r
# Source utility functions
source("R/utils.R")

# Check that all required packages are available
check_dependencies()
```

## Quick Start

### Running the Simulation

1. **Launch the Shiny Application:**

```r
# From R console or RStudio
shiny::runApp()
```

The application will open in your default web browser.

2. **Configure Inputs:**
   - Adjust regional parameters (population, dwellings, parking difficulty)
   - Set costs (delivery, washing, drying)
   - Configure pricing (wash price, dry price, discounts)
   - Define capacity (vans, machines, drivers)
   - Choose randomization settings (distribution type, peak hours, demand scenario)

3. **Run Simulation:**
   - Click **"Run Simulation"** button
   - Wait for progress indicator (typically 2-5 minutes for 1-week scenario)
   - View results in dashboard

4. **Interpret Results:**
   - **Summary Tab**: Key financial and operational metrics at a glance
   - **Financial Tab**: Revenue, costs, profit/loss, break-even analysis
   - **Operations Tab**: Utilization metrics, bottleneck identification
   - **Charts Tab**: Interactive visualizations of results

### Testing Phase 4 Implementation

To test the order generation and routing functionality:

```r
# Run Phase 4 test suite
source("test_phase4.R")
```

This will test:
- Order generation with all three scenario configs (realistic, pessimistic, optimistic)
- Configuration validation
- Service type distribution
- Price elasticity effects
- Routing calculations (distance, travel time with traffic and parking)

## Project Structure

```
fulo-simulate/
├── app.R                    # Main Shiny application entry point
├── R/                       # R source code (modularized)
│   ├── simulation.R         # Core simulation engine
│   ├── inputs.R             # Input configuration and validation
│   ├── randomization.R      # Order generation and randomization
│   ├── financial.R          # Financial calculations (revenue, costs, P&L)
│   ├── operations.R         # Operational metrics (utilization, bottlenecks)
│   ├── routing.R            # Delivery routing and logistics
│   └── utils.R              # Utility functions
├── data/                    # Data files
│   └── defaults.json        # Default configuration values
├── configs/                 # Example scenario configurations
│   ├── pessimistic.json     # Conservative scenario
│   ├── realistic.json       # Base case scenario
│   └── optimistic.json      # Aggressive growth scenario
├── docs/                    # Documentation
│   ├── user_guide.md        # Detailed user guide
│   ├── metrics_guide.md     # Metrics interpretation guide
│   └── coding_standards.md  # Development standards
├── renv/                    # renv package cache (managed by renv)
├── renv.lock                # Package dependency lock file
├── .gitignore               # Git ignore patterns
├── .Rprofile                # R environment configuration
├── plan.md                  # Implementation plan
└── README.md                # This file
```

## Documentation

- **[User Guide](docs/user_guide.md)**: Step-by-step instructions for using the tool
- **[Metrics Guide](docs/metrics_guide.md)**: How to interpret simulation results
- **[Implementation Plan](plan.md)**: Technical implementation roadmap
- **[Coding Standards](docs/coding_standards.md)**: Development guidelines

## Support

- **Issues**: Report bugs or request features at [GitHub Issues](https://github.com/numbersmart/fulo-simulate/issues)
- **Questions**: Contact Eduardo (product owner)
- **Documentation**: See `docs/` directory

## License

Internal tool for Numbersmart. Not for public distribution.

## Authors

- **Product Owner**: Eduardo Flores
- **Development**: AI-assisted implementation
- **Version**: 1.0.0-alpha

---

**Status**: Alpha - In Development
**Last Updated**: 2026-01-02
