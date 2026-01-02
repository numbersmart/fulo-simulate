#' Utility Functions for Fulo Simulate
#'
#' Common utility functions used across the simulation engine.
#'
#' @author Fulo Simulate Team
#' @date 2026-01-02

# Package Dependencies Check ----

#' Check Required Package Dependencies
#'
#' Verifies that all required packages are installed and loadable.
#'
#' @return Logical TRUE if all dependencies available, FALSE otherwise
#' @export
#'
#' @examples
#' check_dependencies()
check_dependencies <- function() {
  required_packages <- c(
    "shiny",
    "ggplot2",
    "plotly",
    "jsonlite",
    "dplyr",
    "tidyr",
    "lubridate"
  )

  missing <- c()
  for (pkg in required_packages) {
    if (!requireNamespace(pkg, quietly = TRUE)) {
      missing <- c(missing, pkg)
    }
  }

  if (length(missing) > 0) {
    message("Missing required packages: ", paste(missing, collapse = ", "))
    message("Install with: install.packages(c('", paste(missing, collapse = "', '"), "'))")
    return(FALSE)
  }

  message("All required packages are available!")
  return(TRUE)
}


# File I/O Utilities ----

#' Save Configuration to JSON File
#'
#' Saves a configuration list to a JSON file with metadata.
#'
#' @param config List containing configuration parameters
#' @param filepath Character string specifying output file path
#' @param metadata List containing metadata (date, user, description)
#'
#' @return Invisible TRUE on success
#' @export
#'
#' @examples
#' config <- get_default_config()
#' save_config(config, "my_scenario.json", list(description = "Test scenario"))
save_config <- function(config, filepath, metadata = list()) {
  # Add metadata
  config$metadata <- list(
    saved_date = Sys.time(),
    saved_by = Sys.info()["user"],
    description = metadata$description %||% "",
    version = "1.0.0"
  )

  # Write to JSON
  jsonlite::write_json(
    config,
    filepath,
    pretty = TRUE,
    auto_unbox = TRUE
  )

  message("Configuration saved to: ", filepath)
  invisible(TRUE)
}


#' Load Configuration from JSON File
#'
#' Loads and validates a configuration from a JSON file.
#'
#' @param filepath Character string specifying input file path
#'
#' @return List containing configuration parameters
#' @export
#'
#' @examples
#' config <- load_config("configs/realistic.json")
load_config <- function(filepath) {
  if (!file.exists(filepath)) {
    stop("Configuration file not found: ", filepath)
  }

  # Read JSON
  config <- jsonlite::read_json(filepath, simplifyVector = TRUE)

  # Validate configuration
  validation <- validate_config(config)
  if (!validation$valid) {
    stop("Invalid configuration: ", paste(validation$errors, collapse = ", "))
  }

  message("Configuration loaded from: ", filepath)
  return(config)
}


# Helper Operators ----

#' Null Coalescing Operator
#'
#' Returns the left-hand side if not NULL, otherwise returns right-hand side.
#'
#' @param x Value to check
#' @param y Default value if x is NULL
#'
#' @return x if not NULL, otherwise y
#'
#' @examples
#' NULL %||% "default"  # Returns "default"
#' "value" %||% "default"  # Returns "value"
`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}


# Time Utilities ----

#' Generate Time Sequence
#'
#' Generates a sequence of datetime objects for simulation time periods.
#'
#' @param start_date Date or POSIXct start time
#' @param end_date Date or POSIXct end time
#' @param by Character string specifying interval ("1 hour", "30 mins", etc.)
#'
#' @return Vector of POSIXct datetime objects
#' @export
#'
#' @examples
#' times <- generate_time_sequence(Sys.Date(), Sys.Date() + 7, "2 hours")
generate_time_sequence <- function(start_date, end_date, by = "1 hour") {
  seq(
    from = lubridate::as_datetime(start_date),
    to = lubridate::as_datetime(end_date),
    by = by
  )
}


# Placeholder for validate_config (will be implemented in inputs.R)
validate_config <- function(config) {
  # This will be properly implemented in inputs.R
  # For now, return valid
  list(valid = TRUE, errors = character(0))
}
