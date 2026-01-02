# fulo-simulate R Profile
# This file is automatically sourced when R starts in this project

# Activate renv for this project
source("renv/activate.R")

# Set options for the session
options(
  # Use CRAN mirror
  repos = c(CRAN = "https://cloud.r-project.org/"),

  # Increase output width for better console display
  width = 120,

  # Disable scientific notation for clarity
  scipen = 999,

  # Set default number of digits to display
  digits = 4,

  # Show warnings immediately
  warn = 1
)

# Welcome message
if (interactive()) {
  cat("\n")
  cat("====================================\n")
  cat("  Fulo Simulate - v1.0.0-alpha\n")
  cat("====================================\n")
  cat("\n")
  cat("Quick Start:\n")
  cat("  - Run simulation: shiny::runApp()\n")
  cat("  - Load config:    load_config('configs/realistic.json')\n")
  cat("  - View docs:      ?run_simulation\n")
  cat("\n")
  cat("Tip: Run check_dependencies() to verify all packages are installed.\n")
  cat("\n")
}
