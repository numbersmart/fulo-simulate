# Fulo Simulate - User Guide

**Version 1.0.0** | Last Updated: January 2026

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Understanding Scenarios](#understanding-scenarios)
4. [Configuring Parameters](#configuring-parameters)
5. [Running Simulations](#running-simulations)
6. [Interpreting Results](#interpreting-results)
7. [Scenario Comparison](#scenario-comparison)
8. [Use Cases & Examples](#use-cases--examples)
9. [Troubleshooting](#troubleshooting)
10. [Best Practices](#best-practices)

---

## Introduction

Fulo Simulate is a comprehensive business simulation tool designed for laundry delivery services. It helps you:

- **Forecast financials** - Predict revenue, costs, and profitability
- **Plan capacity** - Determine optimal resource allocation (vans, drivers, machines)
- **Identify bottlenecks** - Find operational constraints before they impact service
- **Compare scenarios** - Evaluate different business strategies side-by-side
- **Make data-driven decisions** - Use realistic simulations instead of guesswork

### Who Should Use This Tool?

- **Business Owners** - Planning new laundry service operations
- **Operations Managers** - Optimizing existing service capacity
- **Financial Planners** - Forecasting revenue and profitability
- **Investors** - Evaluating business viability and growth scenarios

---

## Getting Started

### Prerequisites

- R (version 4.0 or higher)
- RStudio (recommended but not required)
- Required R packages (installed automatically via `renv`)

### Installation

1. Clone or download the repository
2. Open R or RStudio
3. Set working directory to the project folder
4. Run: `renv::restore()` to install dependencies
5. Launch the app: `shiny::runApp()`

### First Simulation

1. **Select "Realistic" from the preset dropdown** - This loads sensible defaults
2. **Click "Run Simulation"** - Wait 5-30 seconds for results
3. **Explore the Summary tab** - See key metrics at a glance
4. **Navigate to other tabs** - Dive deeper into financials and operations

**Congratulations!** You've run your first simulation.

---

## Understanding Scenarios

Fulo Simulate includes three preset scenarios based on real-world Madrid operations:

### Realistic Scenario (Base Case)

**When to use:** Initial planning, baseline comparisons, realistic forecasting

**Characteristics:**
- Moderate demand: 0.5% weekly market penetration
- Standard pricing: €7 wash, €8 dry
- Typical costs: €15/hr driver rate, €0.25/kg wash, €0.40/kg dry
- Balanced capacity: 3 vans, 4 drivers, 10 wash machines, 8 dry machines
- 20% subscription rate, 30% self-check adoption
- 2% refund rate, 5% failed delivery rate

**Expected Results:**
- Moderate profit margins (15-25%)
- Some resource constraints
- Break-even typically around 150-200 orders

### Pessimistic Scenario (Conservative)

**When to use:** Risk assessment, worst-case planning, conservative forecasting

**Characteristics:**
- Low demand: 40% below baseline
- Lower pricing: €6 wash, €7 dry (competitive pressure)
- Higher costs: €18/hr drivers, +10% operations costs
- Limited capacity: 3 vans, 4 drivers (same as realistic)
- 10% subscription rate, 15% self-check adoption
- 5% refund rate, 8% failed delivery rate

**Expected Results:**
- Thin or negative margins (5-10% or loss)
- Underutilized resources
- Higher break-even point (200-300 orders)

### Optimistic Scenario (Growth)

**When to use:** Expansion planning, best-case scenarios, growth projections

**Characteristics:**
- High demand: 50% above baseline
- Premium pricing: €8 wash, €9 dry
- Lower costs: €14/hr drivers, -10% operations costs
- Expanded capacity: 4 vans, 5 drivers, 12 machines
- 30% subscription rate, 45% self-check adoption
- 1% refund rate, 3% failed delivery rate

**Expected Results:**
- Strong margins (25-35%)
- Some bottlenecks (wash machines, vans)
- Quick break-even (100-150 orders)

---

## Configuring Parameters

### Regional Parameters

**Dwellings** (Default: 50,000)
- Total residential units in service area
- Directly impacts potential market size
- Higher = more potential customers
- Typical range: 10,000 - 100,000

**Population** (Default: 120,000)
- Total people in service area
- Used for market sizing calculations
- Should be ~2.4x dwellings (average household size)

**Parking Difficulty** (1-10 scale, Default: 7)
- 1 = Easy parking, quick stops (2-4 min)
- 10 = Very difficult, long searches (12-15 min)
- Directly impacts delivery costs and times
- Madrid urban areas typically 7-9

**Geographic Density**
- Urban: Concentrated addresses, shorter distances
- Suburban: Medium spread, moderate distances
- Rural: Dispersed addresses, longer routes

### Pricing Parameters

**Wash Price** (Default: €7)
- Price per wash service
- Higher prices reduce demand (price elasticity)
- Lower prices increase volume but reduce margin
- Typical range: €5-10

**Dry Price** (Default: €8)
- Price per dry service
- Usually €1-2 higher than wash
- Most customers want wash+dry (€15 combined)
- Typical range: €6-12

**Self-Check Discount** (Default: €2)
- Flat discount for customers who self-check laundry
- Reduces operations costs (less staff time)
- Encourages customer participation
- Typical range: €1-3

**Subscription Discount** (Default: 15%)
- Percentage discount for monthly subscribers
- Applied AFTER self-check discount
- Builds customer loyalty and recurring revenue
- Typical range: 10-25%

### Cost Parameters

**Driver Hourly Rate** (Default: €15)
- Wages including benefits and overhead
- Based on Madrid minimum wage ~€15/hr in 2026
- Includes employment taxes and insurance
- Typical range: €12-20

**Wash Cost per kg** (Default: €0.25)
- Water, detergent, electricity, machine depreciation
- Industry standard for commercial laundry
- Typical range: €0.20-0.35

**Dry Cost per kg** (Default: €0.40)
- Higher than wash due to energy costs
- Electricity for heating dominates
- Typical range: €0.30-0.50

**Weekly Overhead** (Default: €500)
- Rent, utilities, insurance, admin costs
- Fixed costs that don't scale with volume
- Critical for break-even calculations
- Typical range: €300-800

**Fuel per km** (Default: €0.10)
- Diesel or electric equivalent
- Includes vehicle depreciation
- Based on Madrid fuel prices
- Typical range: €0.08-0.15

### Capacity Parameters

**Number of Vans** (Default: 3)
- Pickup and delivery vehicles
- Each can handle ~5 stops per 2-hour route
- Often a primary bottleneck
- Scale based on order volume

**Number of Drivers** (Default: 4)
- Should be ≥ number of vans
- Allows coverage during breaks, sick days
- Lower utilization if over-staffed

**Wash Machines** (Default: 10)
- Commercial washing machines
- ~1 hour per load (including loading/unloading)
- Typical bottleneck at high volumes
- Scale based on wash orders per day

**Dry Machines** (Default: 8)
- Commercial dryers
- ~1.2 hours per load (longer than washing)
- Can become bottleneck if ratio is wrong
- Typically 80% of wash machine count

**Operating Hours per Day** (Default: 12)
- Hours facility is open and staffed
- More hours = more capacity but higher overhead
- Typical range: 8-16 hours

### Simulation Parameters

**Demand Scenario**
- Pessimistic: Low demand (-40%)
- Realistic: Base demand
- Optimistic: High demand (+50%)
- Combines with price elasticity

**Duration (days)** (Default: 7)
- Simulation length
- 7 days = 1 week (typical)
- Longer = more stable metrics but slower run time
- Range: 1-30 days

**Price Elasticity** (Default: 1.5)
- How demand changes with price
- 1.5 = 10% price increase → 15% demand decrease
- Higher = more price-sensitive customers
- Range: 0.5-3.0

**Subscription Rate** (Default: 20%)
- Percentage of customers on subscriptions
- Higher = more recurring revenue but lower prices
- Impacts revenue stability
- Range: 0-50%

**Random Seed** (Default: 42)
- For reproducibility
- Same seed = identical results
- Change to test variability

---

## Running Simulations

### Step-by-Step Process

1. **Select Preset or Configure Custom**
   - Use preset for quick start
   - Use custom for specific scenarios

2. **Review Configuration**
   - Scroll through sidebar
   - Verify all parameters make sense
   - Check for validation warnings

3. **Click "Run Simulation"**
   - Progress modal appears
   - Typically completes in 5-30 seconds
   - Longer for 30-day simulations

4. **Review Results**
   - Automatically switches to Summary tab
   - Green checkmark appears in sidebar
   - Order count displayed

### What Happens During Simulation?

1. **Order Generation** - Creates realistic customer orders based on demand
2. **Scheduling** - Assigns pickups to time slots and routes
3. **Processing** - Simulates washing, drying, folding
4. **Delivery** - Routes deliveries accounting for traffic and parking
5. **Metrics** - Calculates financials and operations metrics

### Typical Run Times

- 7-day simulation: 5-10 seconds
- 14-day simulation: 10-20 seconds
- 30-day simulation: 20-30 seconds

*Run time depends on order volume and computer speed*

---

## Interpreting Results

### Summary Tab

**Four Key Metrics:**

1. **Revenue** (Green)
   - Total money earned from all orders
   - Higher is better
   - Compare to costs to assess profitability

2. **Costs** (Red)
   - Total expenses (operations + delivery + overhead)
   - Lower is better (but not at expense of service)
   - Watch the cost per order

3. **Profit** (Green if positive, Red if negative)
   - Revenue minus costs
   - This is gross profit (before taxes, etc.)
   - Positive = profitable, Negative = loss

4. **Bottleneck** (Orange)
   - Resource with highest utilization
   - >80% = constraint limiting growth
   - Focus optimization efforts here

**Charts:**
- **Profit Chart**: Visual comparison of revenue, costs, profit
- **Utilization Chart**: Shows which resources are constrained

### Financial Tab

**Revenue Section:**
- **Total Revenue**: Final amount after all discounts
- **Base Revenue**: Before discounts
- **Discounts**: Amount given up for self-check and subscriptions

**Revenue Breakdown Pie Chart:**
- Shows split between wash_only, dry_only, wash_dry
- Typically 70% wash_dry, 20% wash, 10% dry

**Cost Section:**
- **Total Costs**: All expenses combined
- **Operations**: Wash + dry + overhead (fixed costs)
- **Delivery**: Driver + fuel (variable costs)

**Cost Breakdown Pie Chart:**
- 5 slices: wash, dry, overhead, driver, fuel
- Typically driver is largest single category

**Break-even Analysis:**

- **Break-even Point**: Orders needed to cover fixed costs
- **Current Position**: Your actual order count
- **Status**: Above or below break-even
  - Green = Profitable
  - Red = Not yet profitable
- **Contribution Margin**: Profit per order after variable costs
  - Higher margin = faster break-even

**Break-even Chart:**
- Blue line = Revenue (slopes up)
- Red line = Costs (starts high, slopes up)
- Red dot = Break-even point (where lines cross)
- Green dot = Your current position
- Goal: Green dot to the right of red dot

### Operations Tab

**Resource Utilization Chart:**
- Bars show % capacity used for each resource
- Red dashed line at 80% = bottleneck threshold
- Above 80% = constraint, need more capacity
- Below 50% = underutilized, may be over-invested

**Bottleneck Analysis:**

**Warning (Orange Box):**
- One or more resources >80% utilized
- Primary bottleneck identified
- This limits your ability to handle more orders
- **Action**: Add capacity or optimize this resource

**Success (Green Box):**
- All resources <80% utilized
- Room to grow without adding capacity
- Good position for now

**Service Level Metrics:**

- **Completion Rate**: % of orders successfully delivered
  - Goal: >95%
  - Low rate indicates operational issues

- **Refund Rate**: % of orders refunded
  - Realistic: 2%, Pessimistic: 5%, Optimistic: 1%
  - High rate indicates quality or service issues

- **Failure Rate**: % of deliveries that failed
  - Reasons: customer not home, address issues
  - Realistic: 5%, Pessimistic: 8%, Optimistic: 3%
  - Drives up costs (re-delivery attempts)

### Scenarios Tab

**Comparison Table:**
- Shows all added scenarios side-by-side
- Key columns:
  - Revenue, Costs, Profit, Margin %
  - Orders, Orders/day
  - Break-even Orders
  - Primary Bottleneck
  - Delta % (change vs first scenario)

**Comparison Chart:**
- Grouped bars for each scenario
- Green = Profit, Blue = Revenue, Red = Costs
- Easy visual comparison

**How to Use:**
1. Run baseline simulation
2. Click "Add Current Results to Comparison"
3. Adjust one parameter (e.g., pricing)
4. Run again
5. Add to comparison
6. See impact of that change

---

## Scenario Comparison

### Common Comparisons

**Pricing Sensitivity:**
1. Run realistic scenario (€7 wash, €8 dry)
2. Add to comparison
3. Increase prices to €8 wash, €9 dry
4. Run and add
5. Decrease prices to €6 wash, €7 dry
6. Run and add
7. Compare profit at different price points

**Capacity Planning:**
1. Run realistic (3 vans, 4 drivers)
2. Add to comparison
3. Increase to 4 vans, 5 drivers
4. Run and add
5. Compare: Does profit increase justify cost?

**Market Scenarios:**
1. Run pessimistic (low demand)
2. Add to comparison
3. Run realistic (moderate demand)
4. Add to comparison
5. Run optimistic (high demand)
6. Add to comparison
7. See profit range across scenarios

### Interpreting Deltas

**Revenue Delta %:**
- Shows % change in revenue vs baseline
- Positive = higher revenue
- Driven by volume and pricing changes

**Profit Delta %:**
- Shows % change in profit vs baseline
- More volatile than revenue delta
- Small revenue changes can cause large profit swings

**Orders Delta %:**
- Shows % change in order volume
- Driven by demand scenario and price elasticity

---

## Use Cases & Examples

### Use Case 1: New Market Entry

**Situation:** Evaluating whether to launch service in a new Madrid neighborhood

**Steps:**
1. Configure realistic scenario
2. Set dwellings to neighborhood size (e.g., 25,000)
3. Set population proportionally (e.g., 60,000)
4. Run simulation
5. Check Summary tab: Is profit positive?
6. Check Financial tab: How long to break-even?
7. Check Operations tab: What capacity needed?

**Decision Criteria:**
- Positive profit after 7 days = viable
- Break-even <500 orders = achievable
- No major bottlenecks = smooth operations

### Use Case 2: Pricing Optimization

**Situation:** Determining optimal pricing for maximum profit

**Steps:**
1. Run with current prices (€7/€8)
2. Add to comparison
3. Increase by 10% (€7.70/€8.80)
4. Add to comparison
5. Increase by 20% (€8.40/€9.60)
6. Add to comparison
7. Compare profits in Scenarios tab

**Analysis:**
- Find price point with maximum profit
- Balance between margin and volume
- Consider elasticity impact

### Use Case 3: Capacity Expansion

**Situation:** Determining if and when to add a 4th van

**Steps:**
1. Run realistic scenario (current capacity)
2. Note bottleneck (likely vans at 85%+)
3. Add to comparison
4. Increase vans to 4, drivers to 5
5. Run simulation
6. Add to comparison

**Decision:**
- Does profit increase cover van cost?
- Van cost ~€30,000/year (depreciation + maintenance)
- Need €2,500/month profit increase to justify
- Check profit delta in comparison

### Use Case 4: Subscription Strategy

**Situation:** Evaluating impact of subscription program

**Steps:**
1. Run with 0% subscription rate
2. Add to comparison
3. Run with 20% subscription rate (realistic)
4. Add to comparison
5. Run with 40% subscription rate (aggressive)
6. Add to comparison

**Analysis:**
- Subscriptions reduce per-order revenue
- But increase customer loyalty and volume
- Find optimal subscription rate
- Consider retention benefits (not in simulation)

---

## Troubleshooting

### Simulation Won't Run

**Error: "Configuration validation failed"**
- Check that all parameters are valid ranges
- Ensure positive numbers where required
- Verify percentages are 0-100 (not 0-1 for discounts)

**Error: "Missing required packages"**
- Run `renv::restore()` to install dependencies
- Check internet connection for package downloads

**App won't launch**
- Verify R version ≥4.0
- Ensure working directory is correct
- Try `shiny::runApp("path/to/fulo-simulate")`

### Results Don't Make Sense

**Negative profit despite high prices**
- Check overhead (fixed costs may be too high)
- Check demand scenario (pessimistic has low volume)
- Calculate break-even in Financial tab

**100% utilization on all resources**
- Likely configuration issue
- Reduce demand or increase capacity
- Check that operating hours are reasonable

**No bottlenecks but losing money**
- Volume is low (underutilized capacity)
- Fixed costs exceed revenue
- Need to increase demand or reduce overhead

### Performance Issues

**Simulation takes >1 minute**
- Reduce duration (30 days → 7 days)
- Check demand scenario (optimistic generates most orders)
- Close other R processes
- Restart R session

**Charts not displaying**
- Check that plotly package is installed
- Try refreshing the browser
- Check browser console for JavaScript errors

---

## Best Practices

### Configuration

1. **Start with presets** - Use realistic/pessimistic/optimistic first
2. **Change one variable at a time** - For clear cause-and-effect analysis
3. **Use realistic ranges** - Don't set wages to €1 or prices to €100
4. **Keep seed consistent** - For reproducible comparisons (use 42)
5. **Match region to reality** - Madrid data won't fit rural areas exactly

### Analysis

1. **Run multiple scenarios** - Never rely on single simulation
2. **Look for trends** - How does profit change with price?
3. **Identify constraints** - Focus on bottlenecks first
4. **Calculate break-even** - Know your minimum viable volume
5. **Consider externalities** - Simulation doesn't include marketing, seasonality, competition

### Decision Making

1. **Use ranges, not point estimates** - "€5,000-8,000 profit" not "€6,234 profit"
2. **Stress test assumptions** - Run pessimistic to see downside
3. **Compare to break-even** - How far above must you be to feel safe?
4. **Factor in growth time** - Real demand grows slower than instant simulation
5. **Remember limitations** - Model is simplified; reality is messier

### Reporting

1. **Include multiple scenarios** - Show best/base/worst cases
2. **Highlight bottlenecks** - Call out operational constraints
3. **Show sensitivity** - How does ±10% pricing change results?
4. **Document assumptions** - What parameters did you use?
5. **Explain deltas** - Why did profit change between scenarios?

---

## Support & Resources

### Documentation
- **This User Guide** - For business users
- **Developer Guide** (`docs/DEVELOPER_GUIDE.md`) - For technical users
- **README** - Quick start and installation
- **Code Comments** - Inline documentation in R files

### Getting Help
- GitHub Issues: Report bugs or request features
- Email: support@fulo.com (if applicable)

### Updates
- Check GitHub for latest version
- Review CHANGELOG.md for changes
- Update with `git pull` and `renv::restore()`

---

**End of User Guide** | Version 1.0.0 | © 2026 Fulo Simulate
