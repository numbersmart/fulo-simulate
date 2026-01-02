# renv Activation Script
# This file is sourced when R starts in this project

local({
  # Check if renv is installed
  if (!requireNamespace("renv", quietly = TRUE)) {
    message("Installing renv package...")
    install.packages("renv", repos = "https://cloud.r-project.org/")
  }

  # Activate renv for this project
  renv::load(getwd())
})
