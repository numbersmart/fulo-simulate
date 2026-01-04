# app.R - Fulo Simulate Shiny Application
#
# Main Shiny application for running and visualizing laundry service simulations.
# This app provides an interactive interface for configuring scenarios, running
# simulations, and analyzing financial and operational results.
#
# Phase: 6 - Shiny UI Development

# Load required libraries
library(shiny)
library(ggplot2)
library(plotly)
library(jsonlite)
library(dplyr)
library(tidyr)

# Source all R modules
source("R/utils.R")
source("R/inputs.R")
source("R/randomization.R")
source("R/routing.R")
source("R/simulation.R")
source("R/financial.R")
source("R/operations.R")

# Define UI
ui <- fluidPage(

  # Application title
  titlePanel("Fulo Simulate - Laundry Service Business Simulator"),

  # Sidebar with inputs
  sidebarLayout(
    sidebarPanel(
      width = 3,

      h4("Configuration"),

      # Scenario selection
      selectInput("scenario_preset",
                  "Load Preset Scenario:",
                  choices = c("Custom", "Realistic", "Pessimistic", "Optimistic"),
                  selected = "Realistic"),

      hr(),

      # Regional parameters
      h5("Regional Parameters"),
      numericInput("dwellings", "Dwellings:", value = 50000, min = 1000, step = 1000),
      numericInput("population", "Population:", value = 120000, min = 1000, step = 1000),
      sliderInput("parking_difficulty", "Parking Difficulty (1-10):",
                  min = 1, max = 10, value = 7, step = 1),
      selectInput("geographic_density", "Geographic Density:",
                  choices = c("urban", "suburban", "rural"),
                  selected = "urban"),

      hr(),

      # Pricing parameters
      h5("Pricing"),
      numericInput("wash_price", "Wash Price (€):", value = 7, min = 1, step = 0.5),
      numericInput("dry_price", "Dry Price (€):", value = 8, min = 1, step = 0.5),
      numericInput("self_check_discount", "Self-Check Discount (€):",
                   value = 2, min = 0, step = 0.5),
      sliderInput("subscription_discount_pct", "Subscription Discount (%):",
                  min = 0, max = 30, value = 15, step = 5),

      hr(),

      # Cost parameters
      h5("Costs"),
      numericInput("driver_hourly_rate", "Driver Rate (€/hr):",
                   value = 15, min = 10, step = 1),
      numericInput("cost_per_kg_wash", "Wash Cost (€/kg):",
                   value = 0.25, min = 0.1, step = 0.05),
      numericInput("cost_per_kg_dry", "Dry Cost (€/kg):",
                   value = 0.40, min = 0.1, step = 0.05),
      numericInput("overhead_per_week", "Weekly Overhead (€):",
                   value = 500, min = 100, step = 50),
      numericInput("fuel_per_km", "Fuel Cost (€/km):",
                   value = 0.10, min = 0.05, step = 0.01),

      hr(),

      # Capacity parameters
      h5("Capacity"),
      numericInput("num_vans", "Number of Vans:", value = 3, min = 1, step = 1),
      numericInput("num_drivers", "Number of Drivers:", value = 4, min = 1, step = 1),
      numericInput("num_wash_machines", "Wash Machines:", value = 10, min = 1, step = 1),
      numericInput("num_dry_machines", "Dry Machines:", value = 8, min = 1, step = 1),
      numericInput("operating_hours_per_day", "Operating Hours/Day:",
                   value = 12, min = 8, max = 24, step = 1),

      hr(),

      # Simulation parameters
      h5("Simulation"),
      selectInput("demand_scenario", "Demand Scenario:",
                  choices = c("pessimistic", "realistic", "optimistic"),
                  selected = "realistic"),
      numericInput("duration_days", "Duration (days):",
                   value = 7, min = 1, max = 30, step = 1),
      sliderInput("price_elasticity", "Price Elasticity:",
                  min = 0.5, max = 3.0, value = 1.5, step = 0.1),
      sliderInput("subscription_ratio", "Subscription Rate (%):",
                  min = 0, max = 50, value = 20, step = 5),
      numericInput("random_seed", "Random Seed:",
                   value = 42, min = 1, step = 1),

      hr(),

      # Run button
      actionButton("run_simulation", "Run Simulation",
                   class = "btn-primary btn-lg btn-block"),

      br(),

      # Status display
      uiOutput("simulation_status")
    ),

    # Main panel with tabs
    mainPanel(
      width = 9,

      tabsetPanel(
        id = "main_tabs",

        # Summary tab
        tabPanel("Summary",
                 br(),
                 h3("Simulation Summary"),
                 uiOutput("summary_metrics"),
                 hr(),
                 fluidRow(
                   column(6, plotlyOutput("summary_profit_chart")),
                   column(6, plotlyOutput("summary_utilization_chart"))
                 )
        ),

        # Financial tab
        tabPanel("Financial",
                 br(),
                 h3("Financial Analysis"),
                 fluidRow(
                   column(4, uiOutput("revenue_box")),
                   column(4, uiOutput("costs_box")),
                   column(4, uiOutput("profit_box"))
                 ),
                 hr(),
                 fluidRow(
                   column(6, plotlyOutput("revenue_breakdown_chart")),
                   column(6, plotlyOutput("cost_breakdown_chart"))
                 ),
                 hr(),
                 h4("Break-even Analysis"),
                 uiOutput("breakeven_info"),
                 plotlyOutput("breakeven_chart")
        ),

        # Operations tab
        tabPanel("Operations",
                 br(),
                 h3("Operational Metrics"),
                 h4("Resource Utilization"),
                 plotlyOutput("utilization_chart"),
                 hr(),
                 h4("Bottleneck Analysis"),
                 uiOutput("bottleneck_info"),
                 hr(),
                 h4("Service Level Metrics"),
                 uiOutput("service_metrics")
        ),

        # Scenarios tab
        tabPanel("Scenarios",
                 br(),
                 h3("Scenario Comparison"),
                 p("Run multiple simulations with different configurations to compare results."),
                 actionButton("add_to_comparison", "Add Current Results to Comparison"),
                 actionButton("clear_comparison", "Clear All Scenarios"),
                 hr(),
                 uiOutput("comparison_table"),
                 plotlyOutput("comparison_chart")
        ),

        # About tab
        tabPanel("About",
                 br(),
                 h3("About Fulo Simulate"),
                 p("Fulo Simulate is a comprehensive business simulation tool for laundry delivery services."),
                 p("It models the complete order lifecycle including pickup, washing, drying, and delivery,
                   with realistic constraints on capacity, routing, and operational costs."),
                 h4("Key Features:"),
                 tags$ul(
                   tags$li("Realistic demand modeling with peak hours and price elasticity"),
                   tags$li("Multi-tier pricing with subscription and self-check discounts"),
                   tags$li("Comprehensive cost tracking (operations, delivery, overhead)"),
                   tags$li("Capacity utilization and bottleneck identification"),
                   tags$li("Break-even analysis and profitability projections"),
                   tags$li("Scenario comparison for sensitivity analysis")
                 ),
                 h4("Scenarios:"),
                 tags$ul(
                   tags$li(tags$b("Realistic:"), " Base case with current Madrid operations data"),
                   tags$li(tags$b("Pessimistic:"), " Conservative scenario (lower demand, higher costs)"),
                   tags$li(tags$b("Optimistic:"), " Aggressive growth scenario (higher demand, lower costs)")
                 ),
                 hr(),
                 p("Built with R Shiny | Version 1.0.0 | Phase 6 Complete")
        )
      )
    )
  )
)

# Define server logic
server <- function(input, output, session) {

  # Reactive values to store simulation results
  sim_results <- reactiveVal(NULL)
  financial_results <- reactiveVal(NULL)
  operational_results <- reactiveVal(NULL)
  comparison_scenarios <- reactiveVal(list())

  # Load preset scenario configurations
  observeEvent(input$scenario_preset, {
    if (input$scenario_preset == "Custom") return()

    config_file <- switch(
      input$scenario_preset,
      "Realistic" = "configs/realistic.json",
      "Pessimistic" = "configs/pessimistic.json",
      "Optimistic" = "configs/optimistic.json"
    )

    if (file.exists(config_file)) {
      config <- fromJSON(config_file, simplifyVector = FALSE)

      # Update all inputs from config
      updateNumericInput(session, "dwellings", value = config$regional$dwellings)
      updateNumericInput(session, "population", value = config$regional$population)
      updateSliderInput(session, "parking_difficulty", value = config$regional$parking_difficulty)
      updateSelectInput(session, "geographic_density", selected = config$regional$geographic_density)

      updateNumericInput(session, "wash_price", value = config$pricing$wash_price)
      updateNumericInput(session, "dry_price", value = config$pricing$dry_price)
      updateNumericInput(session, "self_check_discount", value = config$pricing$self_check_discount)
      updateSliderInput(session, "subscription_discount_pct",
                        value = config$pricing$subscription_discount_pct * 100)

      updateNumericInput(session, "driver_hourly_rate", value = config$costs$driver_hourly_rate)
      updateNumericInput(session, "cost_per_kg_wash", value = config$costs$cost_per_kg_wash)
      updateNumericInput(session, "cost_per_kg_dry", value = config$costs$cost_per_kg_dry)
      updateNumericInput(session, "overhead_per_week", value = config$costs$overhead_per_week)
      updateNumericInput(session, "fuel_per_km", value = config$costs$fuel_per_km)

      updateNumericInput(session, "num_vans", value = config$capacity$num_vans)
      updateNumericInput(session, "num_drivers", value = config$capacity$num_drivers)
      updateNumericInput(session, "num_wash_machines", value = config$capacity$num_wash_machines)
      updateNumericInput(session, "num_dry_machines", value = config$capacity$num_dry_machines)
      updateNumericInput(session, "operating_hours_per_day", value = config$capacity$operating_hours_per_day)

      updateSelectInput(session, "demand_scenario", selected = config$randomization$demand_scenario)
      updateNumericInput(session, "duration_days", value = config$simulation$duration_days)
      updateSliderInput(session, "price_elasticity", value = config$elasticity$price_elasticity)
      updateSliderInput(session, "subscription_ratio",
                        value = config$elasticity$subscription_ratio * 100)
    }
  })

  # Build configuration from inputs
  build_config <- reactive({
    list(
      regional = list(
        dwellings = input$dwellings,
        population = input$population,
        parking_difficulty = input$parking_difficulty,
        geographic_density = input$geographic_density
      ),
      costs = list(
        driver_hourly_rate = input$driver_hourly_rate,
        cost_per_kg_wash = input$cost_per_kg_wash,
        cost_per_kg_dry = input$cost_per_kg_dry,
        overhead_per_week = input$overhead_per_week,
        fuel_per_km = input$fuel_per_km
      ),
      pricing = list(
        wash_price = input$wash_price,
        dry_price = input$dry_price,
        self_check_discount = input$self_check_discount,
        subscription_discount_pct = input$subscription_discount_pct / 100
      ),
      capacity = list(
        num_vans = input$num_vans,
        van_capacity_kg = 100,
        num_wash_machines = input$num_wash_machines,
        num_dry_machines = input$num_dry_machines,
        num_drivers = input$num_drivers,
        operating_hours_per_day = input$operating_hours_per_day
      ),
      randomization = list(
        distribution_type = "normal",
        random_seed = input$random_seed,
        demand_scenario = input$demand_scenario,
        peak_hours_start = "18:00",
        peak_hours_end = "20:00",
        peak_hour_multiplier = 3.0,
        refund_rate = 0.02,
        failed_delivery_rate = 0.05
      ),
      elasticity = list(
        price_elasticity = input$price_elasticity,
        self_check_adoption_rate = 0.30,
        subscription_ratio = input$subscription_ratio / 100
      ),
      simulation = list(
        start_date = "2026-01-06",
        duration_days = input$duration_days,
        time_slot_hours = 2
      )
    )
  })

  # Run simulation
  observeEvent(input$run_simulation, {

    # Show progress
    showModal(modalDialog(
      title = "Running Simulation",
      "Please wait while the simulation runs...",
      footer = NULL,
      easyClose = FALSE
    ))

    tryCatch({
      # Build config
      config <- build_config()

      # Validate config
      validation <- validate_config(config)
      if (!validation$valid) {
        removeModal()
        showModal(modalDialog(
          title = "Configuration Error",
          paste("Configuration validation failed:", paste(validation$errors, collapse = ", ")),
          easyClose = TRUE
        ))
        return()
      }

      # Run simulation
      results <- run_simulation(config, random_seed = input$random_seed)
      sim_results(results)

      # Calculate financial metrics
      financial <- calculate_financial_summary(results, config)
      financial_results(financial)

      # Calculate operational metrics
      operational <- calculate_operational_summary(results, config)
      operational_results(operational)

      removeModal()

      # Switch to summary tab
      updateTabsetPanel(session, "main_tabs", selected = "Summary")

    }, error = function(e) {
      removeModal()
      showModal(modalDialog(
        title = "Simulation Error",
        paste("An error occurred:", e$message),
        easyClose = TRUE
      ))
    })
  })

  # Simulation status
  output$simulation_status <- renderUI({
    if (is.null(sim_results())) {
      tags$div(
        class = "alert alert-info",
        icon("info-circle"),
        " No simulation results yet. Configure parameters and click 'Run Simulation'."
      )
    } else {
      tags$div(
        class = "alert alert-success",
        icon("check-circle"),
        sprintf(" Simulation complete! %d orders processed.", nrow(sim_results()$orders))
      )
    }
  })

  # Summary metrics
  output$summary_metrics <- renderUI({
    req(sim_results(), financial_results(), operational_results())

    financial <- financial_results()
    operational <- operational_results()

    fluidRow(
      column(3,
             tags$div(class = "well",
                      h4(style = "color: #2c3e50;", "Revenue"),
                      h3(style = "color: #27ae60;", sprintf("€%.0f", financial$summary$total_revenue)),
                      p(sprintf("€%.2f per order", financial$revenue$avg_revenue_per_order))
             )
      ),
      column(3,
             tags$div(class = "well",
                      h4(style = "color: #2c3e50;", "Costs"),
                      h3(style = "color: #e74c3c;", sprintf("€%.0f", financial$summary$total_costs)),
                      p(sprintf("€%.2f per order",
                                financial$summary$total_costs / nrow(sim_results()$orders)))
             )
      ),
      column(3,
             tags$div(class = "well",
                      h4(style = "color: #2c3e50;", "Profit"),
                      h3(style = ifelse(financial$summary$gross_profit > 0, "color: #27ae60;", "color: #e74c3c;"),
                         sprintf("€%.0f", financial$summary$gross_profit)),
                      p(sprintf("%.1f%% margin", financial$summary$gross_margin_pct))
             )
      ),
      column(3,
             tags$div(class = "well",
                      h4(style = "color: #2c3e50;", "Bottleneck"),
                      h3(style = "color: #e67e22;", operational$summary$primary_bottleneck),
                      p(sprintf("%.1f%% utilized", operational$summary$bottleneck_utilization))
             )
      )
    )
  })

  # Summary profit chart
  output$summary_profit_chart <- renderPlotly({
    req(financial_results())

    financial <- financial_results()

    data <- data.frame(
      Category = c("Revenue", "Costs", "Profit"),
      Amount = c(
        financial$summary$total_revenue,
        financial$summary$total_costs,
        financial$summary$gross_profit
      ),
      Color = c("#27ae60", "#e74c3c", ifelse(financial$summary$gross_profit > 0, "#3498db", "#95a5a6"))
    )

    plot_ly(data, x = ~Category, y = ~Amount, type = "bar",
            marker = list(color = ~Color)) %>%
      layout(title = "Revenue, Costs & Profit",
             yaxis = list(title = "Amount (€)"),
             showlegend = FALSE)
  })

  # Summary utilization chart
  output$summary_utilization_chart <- renderPlotly({
    req(operational_results())

    utilization <- operational_results()$utilization$summary

    plot_ly(utilization, x = ~resource_type, y = ~utilization_pct,
            type = "bar", marker = list(color = "#3498db")) %>%
      layout(title = "Resource Utilization",
             xaxis = list(title = "Resource"),
             yaxis = list(title = "Utilization (%)", range = c(0, 100)),
             shapes = list(
               list(type = "line", x0 = -0.5, x1 = 3.5, y0 = 80, y1 = 80,
                    line = list(color = "red", dash = "dash"))
             ))
  })

  # Revenue box
  output$revenue_box <- renderUI({
    req(financial_results())
    financial <- financial_results()

    tags$div(class = "well text-center",
             h4("Total Revenue"),
             h2(style = "color: #27ae60;", sprintf("€%.0f", financial$summary$total_revenue)),
             hr(),
             p(sprintf("Base: €%.0f", financial$revenue$total_base_revenue)),
             p(sprintf("Discounts: -€%.0f", financial$revenue$total_discounts))
    )
  })

  # Costs box
  output$costs_box <- renderUI({
    req(financial_results())
    financial <- financial_results()

    tags$div(class = "well text-center",
             h4("Total Costs"),
             h2(style = "color: #e74c3c;", sprintf("€%.0f", financial$summary$total_costs)),
             hr(),
             p(sprintf("Operations: €%.0f", financial$operational_costs$total_operational_cost)),
             p(sprintf("Delivery: €%.0f", financial$delivery_costs$total_delivery_cost))
    )
  })

  # Profit box
  output$profit_box <- renderUI({
    req(financial_results())
    financial <- financial_results()

    profit_color <- ifelse(financial$summary$gross_profit > 0, "#27ae60", "#e74c3c")

    tags$div(class = "well text-center",
             h4("Gross Profit"),
             h2(style = paste0("color: ", profit_color, ";"),
                sprintf("€%.0f", financial$summary$gross_profit)),
             hr(),
             p(sprintf("Margin: %.1f%%", financial$summary$gross_margin_pct)),
             p(sprintf("Status: %s", ifelse(financial$summary$is_profitable, "Profitable", "Loss")))
    )
  })

  # Revenue breakdown chart
  output$revenue_breakdown_chart <- renderPlotly({
    req(financial_results())

    revenue_by_service <- financial_results()$revenue$revenue_by_service

    plot_ly(revenue_by_service, labels = ~service_type, values = ~revenue,
            type = "pie", textposition = "inside",
            textinfo = "label+percent") %>%
      layout(title = "Revenue by Service Type")
  })

  # Cost breakdown chart
  output$cost_breakdown_chart <- renderPlotly({
    req(financial_results())

    breakdown <- financial_results()$total_costs$breakdown

    data <- data.frame(
      Category = c("Wash", "Dry", "Overhead", "Driver", "Fuel"),
      Amount = c(breakdown$wash, breakdown$dry, breakdown$overhead,
                 breakdown$driver, breakdown$fuel)
    )

    plot_ly(data, labels = ~Category, values = ~Amount,
            type = "pie", textposition = "inside",
            textinfo = "label+percent") %>%
      layout(title = "Cost Breakdown")
  })

  # Break-even info
  output$breakeven_info <- renderUI({
    req(financial_results())

    breakeven <- financial_results()$breakeven

    status_color <- ifelse(breakeven$is_above_breakeven, "success", "danger")
    status_text <- ifelse(breakeven$is_above_breakeven, "Above Break-even", "Below Break-even")

    tags$div(
      class = paste0("alert alert-", status_color),
      h5(status_text),
      p(sprintf("Break-even point: %d orders (%.1f orders/day)",
                breakeven$breakeven_orders, breakeven$breakeven_orders_per_day)),
      p(sprintf("Actual orders: %d (%.1f orders/day)",
                breakeven$actual_orders, breakeven$actual_orders_per_day)),
      p(sprintf("Orders above break-even: %d", breakeven$orders_above_breakeven)),
      hr(),
      p(sprintf("Contribution margin: €%.2f per order (%.1f%%)",
                breakeven$contribution_margin_per_order,
                breakeven$contribution_margin_pct))
    )
  })

  # Break-even chart
  output$breakeven_chart <- renderPlotly({
    req(financial_results())

    breakeven <- financial_results()$breakeven

    # Create data for break-even chart
    orders_range <- seq(0, max(breakeven$actual_orders * 1.2, breakeven$breakeven_orders * 1.2),
                        length.out = 100)

    revenue_line <- orders_range * breakeven$revenue_per_order
    cost_line <- breakeven$fixed_costs + (orders_range * breakeven$variable_cost_per_order)

    data <- data.frame(
      Orders = rep(orders_range, 2),
      Amount = c(revenue_line, cost_line),
      Type = rep(c("Revenue", "Total Costs"), each = length(orders_range))
    )

    plot_ly(data, x = ~Orders, y = ~Amount, color = ~Type, type = "scatter", mode = "lines") %>%
      add_trace(x = breakeven$breakeven_orders, y = breakeven$breakeven_orders * breakeven$revenue_per_order,
                mode = "markers", marker = list(size = 10, color = "red"),
                name = "Break-even Point") %>%
      add_trace(x = breakeven$actual_orders, y = breakeven$actual_orders * breakeven$revenue_per_order,
                mode = "markers", marker = list(size = 10, color = "green"),
                name = "Current Position") %>%
      layout(title = "Break-even Analysis",
             xaxis = list(title = "Number of Orders"),
             yaxis = list(title = "Amount (€)"))
  })

  # Utilization chart
  output$utilization_chart <- renderPlotly({
    req(operational_results())

    utilization <- operational_results()$utilization$summary

    plot_ly(utilization, x = ~resource_type, y = ~utilization_pct,
            type = "bar", marker = list(color = "#3498db"),
            text = ~paste0(round(utilization_pct, 1), "%"),
            textposition = "outside") %>%
      layout(title = "Resource Utilization by Type",
             xaxis = list(title = "Resource Type"),
             yaxis = list(title = "Utilization (%)", range = c(0, 100)),
             shapes = list(
               list(type = "line", x0 = -0.5, x1 = 3.5, y0 = 80, y1 = 80,
                    line = list(color = "red", dash = "dash", width = 2))
             ),
             annotations = list(
               list(x = 3, y = 85, text = "Bottleneck Threshold (80%)",
                    showarrow = FALSE, xanchor = "left")
             ))
  })

  # Bottleneck info
  output$bottleneck_info <- renderUI({
    req(operational_results())

    bottlenecks <- operational_results()$bottlenecks

    if (bottlenecks$has_bottlenecks) {
      tags$div(
        class = "alert alert-warning",
        h5(icon("exclamation-triangle"), " Bottlenecks Detected"),
        p(sprintf("Primary bottleneck: %s at %.1f%% utilization",
                  bottlenecks$primary_bottleneck,
                  bottlenecks$primary_bottleneck_utilization)),
        if (nrow(bottlenecks$bottlenecks) > 1) {
          p(sprintf("Additional bottlenecks: %d resource(s) above 80%% utilization",
                    nrow(bottlenecks$bottlenecks) - 1))
        }
      )
    } else {
      tags$div(
        class = "alert alert-success",
        h5(icon("check-circle"), " No Bottlenecks"),
        p("All resources are operating below the 80% utilization threshold.")
      )
    }
  })

  # Service metrics
  output$service_metrics <- renderUI({
    req(operational_results())

    service <- operational_results()$service_metrics

    fluidRow(
      column(4,
             tags$div(class = "well text-center",
                      h5("Completion Rate"),
                      h3(sprintf("%.1f%%", service$completion_rate_pct)),
                      p(sprintf("%d / %d orders", service$completed_orders, service$total_orders))
             )
      ),
      column(4,
             tags$div(class = "well text-center",
                      h5("Refund Rate"),
                      h3(sprintf("%.1f%%", service$refund_rate_pct)),
                      p(sprintf("%d refunds", service$refunded_orders))
             )
      ),
      column(4,
             tags$div(class = "well text-center",
                      h5("Failure Rate"),
                      h3(sprintf("%.1f%%", service$failure_rate_pct)),
                      p(sprintf("%d failed deliveries", service$failed_orders))
             )
      )
    )
  })

  # Add to comparison
  observeEvent(input$add_to_comparison, {
    req(sim_results(), financial_results(), operational_results())

    current_scenarios <- comparison_scenarios()
    scenario_name <- paste0("Scenario ", length(current_scenarios) + 1)

    current_scenarios[[scenario_name]] <- list(
      results = sim_results(),
      config = build_config(),
      name = scenario_name
    )

    comparison_scenarios(current_scenarios)

    showNotification(paste("Added", scenario_name, "to comparison"), type = "message")
  })

  # Clear comparison
  observeEvent(input$clear_comparison, {
    comparison_scenarios(list())
    showNotification("Cleared all comparison scenarios", type = "message")
  })

  # Comparison table
  output$comparison_table <- renderUI({
    scenarios <- comparison_scenarios()

    if (length(scenarios) == 0) {
      return(tags$p("No scenarios added yet. Run a simulation and click 'Add to Comparison'."))
    }

    comparison <- compare_scenarios(scenarios)

    tags$div(
      h4(sprintf("Comparing %d Scenarios", nrow(comparison))),
      renderTable(comparison, digits = 2)
    )
  })

  # Comparison chart
  output$comparison_chart <- renderPlotly({
    scenarios <- comparison_scenarios()
    req(length(scenarios) > 0)

    comparison <- compare_scenarios(scenarios)

    plot_ly(comparison, x = ~scenario, y = ~profit, type = "bar",
            name = "Profit", marker = list(color = "#27ae60")) %>%
      add_trace(y = ~revenue, name = "Revenue", marker = list(color = "#3498db")) %>%
      add_trace(y = ~costs, name = "Costs", marker = list(color = "#e74c3c")) %>%
      layout(title = "Scenario Comparison",
             xaxis = list(title = "Scenario"),
             yaxis = list(title = "Amount (€)"),
             barmode = "group")
  })
}

# Run the application
shinyApp(ui = ui, server = server)
