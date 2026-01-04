# Changelog

All notable changes to Fulo Simulate will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-04

### Initial Release

Complete business simulation platform for laundry delivery services with comprehensive financial and operational analytics.

### Added

#### Phase 1: Foundation (2026-01-02)
- Project structure with modular R code organization
- Package dependency management with renv
- Development standards documentation
- Git configuration (.gitignore, .Rprofile)
- Placeholder modules for all phases
- Default configuration files
- Example scenario configurations (realistic, pessimistic, optimistic)

#### Phase 2: Core Simulation Engine (2026-01-02)
- Event-driven discrete event simulation (750 lines)
- Complete order lifecycle state machine (9 stages)
- Capacity management system for all resources
- Resource reservation and availability checking
- Event queue processing (FIFO chronological)
- Bottleneck identification from capacity logs
- Summary statistics calculation
- Test order generation (replaced in Phase 4)

#### Phase 3: Input Configuration System (2026-01-02)
- Default configuration with Madrid-based parameters (590 lines)
- Comprehensive validation system with section-specific validators
- Input range checking and cross-validation
- Clear error messages for validation failures
- Warning system for non-critical issues
- Configuration summary display function
- Full parameter documentation with assumptions

#### Phase 4: Order Generation & Randomization (2026-01-03)
- Realistic order generation based on demand scenarios (440 lines)
- Demand modeling with market penetration and price elasticity
- Peak hour patterns (18:00-20:00 concentration)
- Service type distribution (wash/dry/wash+dry)
- Order size generation with normal distribution
- Geographic clustering for route optimization (5 zones)
- Customer time preferences (24-48h pickup, 24-72h delivery windows)
- Refund and failure simulation
- Delivery routing and logistics (276 lines)
- Manhattan distance calculation for urban areas
- Traffic simulation with time-of-day multipliers
- Parking difficulty modeling (2-15 min range)
- Multi-stop route metrics calculation
- Route cost calculation (driver time + fuel)
- Traffic variability simulation (±20%)

#### Phase 5: Financial & Operational Metrics (2026-01-03)
- Revenue calculations with multi-tier discounts (372 lines)
  - Base pricing by service type
  - Self-check discount (flat amount)
  - Subscription discount (percentage)
  - Refund handling
- Cost calculations (operations, delivery, overhead)
  - Wash and dry costs (per kg)
  - Driver wages (hourly)
  - Fuel costs (per km)
  - Weekly overhead allocation
- Profit & loss statements
- Break-even analysis with contribution margins
- Operational metrics (386 lines)
  - Resource utilization tracking (vans, drivers, machines)
  - Bottleneck identification (>80% threshold)
  - Service level metrics (completion, refunds, failures)
  - Efficiency metrics (throughput, cycle time, productivity)
- Multi-scenario comparison functionality

#### Phase 6: Shiny UI Development (2026-01-04)
- Complete interactive web application (850+ lines)
- Sidebar configuration panel
  - Preset scenario selector
  - 30+ configurable parameters across 6 categories
  - Run simulation button with progress feedback
- Main tabbed interface:
  - Summary tab: Executive dashboard with 4 KPI cards
  - Financial tab: Revenue/cost breakdown, P&L, break-even analysis
  - Operations tab: Utilization charts, bottleneck alerts, service metrics
  - Scenarios tab: Multi-scenario comparison table and charts
  - About tab: Application documentation
- 9 interactive Plotly charts
- Real-time reactive updates
- Error handling and validation
- Professional Bootstrap styling

#### Phase 7: Documentation & Polish (2026-01-04)
- Comprehensive USER_GUIDE.md (9,000+ words)
  - Getting started tutorial
  - Scenario explanations
  - Parameter documentation
  - Results interpretation guide
  - Use cases and examples
  - Troubleshooting guide
  - Best practices
- DEVELOPER_GUIDE.md (5,000+ words)
  - Architecture overview
  - Module documentation
  - Development workflow
  - Testing guidelines
  - Contributing guidelines
  - Deployment instructions
- CHANGELOG.md (this file)
- LICENSE file (MIT License)
- Enhanced README.md with complete documentation

### Technical Details

**Languages & Frameworks:**
- R 4.0+
- Shiny web framework
- Plotly for interactive visualizations
- tidyverse packages (dplyr, tidyr, lubridate)

**Code Statistics:**
- Total R code: ~4,600 lines across 7 modules
- Shiny app: 850+ lines
- Documentation: 15,000+ words
- Test scripts: 2 comprehensive test suites

**Key Features:**
- Realistic demand modeling with price elasticity
- Multi-tier pricing with discount stacking
- Capacity-constrained simulation
- Geographic routing with traffic and parking
- Complete financial analysis (revenue, costs, P&L, break-even)
- Operational intelligence (utilization, bottlenecks, efficiency)
- Interactive web dashboard
- Scenario comparison capability
- Preset configurations for quick start
- Full parameter customization

**Performance:**
- 7-day simulation: 5-10 seconds
- 14-day simulation: 10-20 seconds
- 30-day simulation: 20-30 seconds

### Assumptions & Limitations

**Documented Assumptions:**
- Market penetration: 0.5% of dwellings per week (realistic scenario)
- Average household laundry: 6-8 kg per order
- Service type distribution: 70% wash+dry, 20% wash-only, 10% dry-only
- Traffic patterns: Rush hours 1.5x slower, midday 1.2x slower
- Parking difficulty: Linear scale from 2-15 minutes
- Route characteristics: 5 stops per route, 2 hours per route, 20km average
- Base speed: 30 km/h in urban Madrid areas
- Service area: ~5km x 5km grid
- Customer preferences: 24-48h pickup, 24-72h delivery windows

**Known Limitations:**
- Simplified routing (no vehicle routing optimization algorithm)
- No seasonality modeling
- No competition or market dynamics
- No customer acquisition costs or marketing
- No staff scheduling complexities
- Delivery times estimated, not precisely tracked
- No multi-day order processing (wash Monday, deliver Friday)

### Dependencies

**R Packages:**
- shiny (≥1.7.0) - Web application framework
- ggplot2 (≥3.4.0) - Static plotting
- plotly (≥4.10.0) - Interactive charts
- jsonlite (≥1.8.0) - JSON parsing
- dplyr (≥1.1.0) - Data manipulation
- tidyr (≥1.3.0) - Data tidying
- lubridate (≥1.9.0) - Date/time handling
- roxygen2 (≥7.2.0) - Documentation
- styler (≥1.10.0) - Code formatting
- lintr (≥3.0.0) - Code linting

All dependencies managed via `renv` for reproducibility.

---

## [Unreleased]

### Planned Enhancements

**v1.1.0 (Future):**
- Export results to PDF/Excel
- Save/load simulation sessions
- Historical comparison (time series)
- Advanced vehicle routing optimization
- Seasonality modeling
- Staff scheduling module

**v1.2.0 (Future):**
- Multi-location support
- Customer acquisition modeling
- Marketing spend integration
- Competitive dynamics
- API for programmatic access
- Database backend for large simulations

### Known Issues

None reported as of v1.0.0 release.

---

## Version History

- **1.0.0** (2026-01-04) - Initial release with all 7 phases complete
- **0.7.0** (2026-01-04) - Phase 7: Documentation & Polish
- **0.6.0** (2026-01-04) - Phase 6: Shiny UI Development
- **0.5.0** (2026-01-03) - Phase 5: Financial & Operational Metrics
- **0.4.0** (2026-01-03) - Phase 4: Order Generation & Randomization
- **0.3.0** (2026-01-02) - Phase 3: Input Configuration System
- **0.2.0** (2026-01-02) - Phase 2: Core Simulation Engine
- **0.1.0** (2026-01-02) - Phase 1: Project Foundation

---

**Changelog maintained by:** Fulo Simulate Team
**Last updated:** 2026-01-04
