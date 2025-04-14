# Justfile for SmartSMEAR R package
# Run tasks with 'just <task>'

# Default task runs tests
default:
  just --choose

# Document the package using roxygen2
document:
  Rscript -e "devtools::document()"

# Run tests using testthat
test:
  Rscript -e "devtools::test()"

# Check the package
check:
  Rscript -e "devtools::check()"

# Build the package
build:
  Rscript -e "devtools::build()"

# Install the package locally
install:
  Rscript -e "devtools::install()"


# Start an R session with the package loaded
repl:
  radian
