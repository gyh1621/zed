#!/bin/bash
set -euo pipefail # Exit on error, undefined variable, or pipe failure

# --- Configuration ---
MAIN_BINARY_NAME="zed"

# Destination directory for the copied binary, relative to the project root
# This is where the binary will be copied TO.
DEST_COPY_DIR="./crates/zed/target/release"

# Directory of the sub-crate where 'cargo bundle' will be run
SUB_CRATE_DIR="./crates/zed"
# --- End Configuration ---

echo "Starting automated build process..."

# 1. Build the main project in release mode
echo "Building main project ($MAIN_BINARY_NAME)..."
cargo build --release
# If the build fails, the script will exit here due to 'set -e'.

# 2. Determine Cargo's target directory
echo "Determining Cargo target directory..."
TARGET_DIR=$(cargo metadata --no-deps --format-version 1 | jq -r '.target_directory')

# Check if TARGET_DIR was successfully retrieved
if [ -z "$TARGET_DIR" ]; then
  echo "Error: Could not determine Cargo's target directory using 'cargo metadata'."
  echo "Please ensure 'jq' is installed and 'cargo metadata' is working."
  exit 1
fi
echo "Cargo target directory is: $TARGET_DIR"

# Construct the full path to the built artifact from the main build
SOURCE_ARTIFACT_PATH="$TARGET_DIR/release/$MAIN_BINARY_NAME"

# Check if the expected artifact actually exists
if [ ! -f "$SOURCE_ARTIFACT_PATH" ]; then
  echo "Error: Build artifact '$SOURCE_ARTIFACT_PATH' not found after build."
  echo "Possible reasons:"
  echo "  - The build failed silently (check output above)."
  echo "  - MAIN_BINARY_NAME ('$MAIN_BINARY_NAME') is incorrect."
  echo "  - Cargo's output structure is unexpected."
  exit 1
fi
echo "Found artifact at: $SOURCE_ARTIFACT_PATH"

# 3. Copy the artifact to the desired location
echo "Copying '$SOURCE_ARTIFACT_PATH' to '$DEST_COPY_DIR/$MAIN_BINARY_NAME'..."
# Ensure the destination directory exists
mkdir -p "$DEST_COPY_DIR"
cp "$SOURCE_ARTIFACT_PATH" "$DEST_COPY_DIR/"
echo "Copy successful."

# 4. Change directory to the sub-crate
echo "Changing directory to '$SUB_CRATE_DIR'..."
cd "$SUB_CRATE_DIR"

# 5. Run 'cargo bundle --release' in the sub-crate's directory
echo "Running 'cargo bundle --release' in '$(pwd)'..."
cargo bundle --release

echo "New Zed bundle created"