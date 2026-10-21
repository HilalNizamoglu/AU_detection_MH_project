#!/bin/bash

# Script: build_book.sh
# Purpose: Build the Jupyter Book from the notebooks in analyzes/ and the
#          READMEs listed in myst.yml, and write the API reference next
#          to it.
# Description: Jupyter Book 2 runs on MyST, which is a Node application
#              that the "jupyter-book" wheel drives, so a Node of at
#              least 18 has to be on PATH.  It does not generate API
#              documentation from Python docstrings, so pdoc renders the
#              package separately into _build/html/api, where the api.md
#              page links to it.
#
#              Notebook execution is off in myst.yml: the outputs stored
#              in each .ipynb are inserted as they are.  Pass "execute"
#              to re-run the notebooks instead, which needs the dataset
#              to be present.

# Exit immediately if any command fails, if an unset variable is used, or
# if any stage of a pipeline fails
set -euo pipefail

# Name of the package the API reference is generated from
PROJECT=au_detection_mh

# Where the book is written.  MyST excludes this directory from the
# project itself, so a build does not pick up its own output.
BUILD_DIR=_build/html

# Lowest Node that Jupyter Book 2 accepts
NODE_MINIMUM=18

# Abort with an actionable message when uv is unavailable
require_uv() {
  if ! command -v uv >/dev/null 2>&1; then
    echo "Error: 'uv' was not found on PATH." >&2
    echo "" >&2
    echo "Install it with:  curl -LsSf https://astral.sh/uv/install.sh | sh" >&2
    exit 1
  fi
}

# Abort when Node is missing or older than Jupyter Book 2 accepts
#
# This is the one prerequisite that uv cannot supply.  On a shared
# machine the system Node is often too old to upgrade in place, in which
# case a user-local Node, or letting the book workflow build it in CI,
# are the ways forward.
require_node() {
  if ! command -v node >/dev/null 2>&1; then
    echo "Error: 'node' was not found on PATH." >&2
    echo "" >&2
    echo "Jupyter Book 2 runs on MyST, which needs Node >= $NODE_MINIMUM." >&2
    echo "See https://nodejs.org/en/download/" >&2
    exit 1
  fi

  local version
  version="$(node --version | sed 's/^v//' | cut -d. -f1)"
  if [[ "$version" -lt "$NODE_MINIMUM" ]]; then
    echo "Error: node $(node --version) is too old for Jupyter Book 2." >&2
    echo "" >&2
    echo "MyST needs Node >= $NODE_MINIMUM.  Options:" >&2
    echo "  - provision one into the project environment, which the docs" >&2
    echo "    extra already carries the tool for and which leaves the" >&2
    echo "    system Node alone:" >&2
    echo "      uv run --extra docs nodeenv --node=22.11.0 .venv/nodeenv" >&2
    echo "      export PATH=\"\$PWD/.venv/nodeenv/bin:\$PATH\"" >&2
    echo "  - let .github/workflows/book_build_publish.yml build the book" >&2
    echo "    in CI, where the runner supplies a current Node" >&2
    exit 1
  fi
}

# Build the book itself
build_book() {
  local execute_flag=("$@")

  echo "  -> Building the book into $BUILD_DIR..."
  uv run --extra docs jupyter book build --html "${execute_flag[@]}"
  echo "  -> Book build completed"
}

# Render the package docstrings into the built site
#
# pdoc writes one page per module plus an index.  api.md links to
# $PROJECT.html, so the output lands under $BUILD_DIR/api.
build_api_reference() {
  echo "  -> Rendering the API reference into $BUILD_DIR/api..."
  uv run --extra docs pdoc "$PROJECT" --output-directory "$BUILD_DIR/api"
  echo "  -> API reference completed"
}

show_usage() {
  echo "Usage: $0 [execute]"
  echo ""
  echo "DESCRIPTION:"
  echo "  Builds the Jupyter Book for $PROJECT from the table of"
  echo "  contents in myst.yml, then renders the package docstrings"
  echo "  into $BUILD_DIR/api with pdoc.  The book workflow runs this"
  echo "  same script, so what CI publishes is what this produces."
  echo ""
  echo "ARGUMENTS:"
  echo "  execute      Re-run the notebooks while building, instead of"
  echo "               inserting the outputs they already carry.  Needs"
  echo "               the dataset to be present."
  echo ""
  echo "REQUIREMENTS:"
  echo "  - uv, for the docs extra that carries jupyter-book and pdoc"
  echo "  - Node >= $NODE_MINIMUM, which MyST runs on and uv cannot supply"
  echo ""
  echo "OUTPUT:"
  echo "  - $BUILD_DIR/           the book"
  echo "  - $BUILD_DIR/api/       the API reference"
}

echo "=== $PROJECT book build script ==="
echo ""

EXECUTE_NOTEBOOKS=false

for arg in "$@"; do
  case $arg in
    execute)
      echo "  -> Will re-run the notebooks while building"
      EXECUTE_NOTEBOOKS=true
      ;;
    help|--help|-h)
      echo ""
      show_usage
      exit 0
      ;;
    *)
      echo "  Error: unknown argument '$arg'"
      echo ""
      show_usage
      exit 1
      ;;
  esac
done

require_uv
require_node

echo ""
echo "=== BUILD PHASE ==="
echo ""

if [ "$EXECUTE_NOTEBOOKS" = true ]; then
  build_book --execute
else
  build_book
fi
echo ""
build_api_reference

echo ""
echo "=== SUMMARY ==="
echo ""
echo "Book:          $(pwd)/$BUILD_DIR/index.html"
echo "API reference: $(pwd)/$BUILD_DIR/api/$PROJECT.html"
echo ""
echo "Script execution completed at $(date)"
