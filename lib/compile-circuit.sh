#!/bin/bash
# Generalized circuit compilation script
# Usage: ./lib/compile-circuit.sh <circuit_name> [config_file]

set -e

CIRCUIT_NAME="$1"
CONFIG_FILE="${2:-circuits.config.json}"

if [ -z "$CIRCUIT_NAME" ]; then
    echo "Error: Circuit name required"
    echo "Usage: $0 <circuit_name> [config_file]"
    exit 1
fi

if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: Config file not found: $CONFIG_FILE"
    exit 1
fi

# Parse config using jq
if ! command -v jq &> /dev/null; then
    echo "Error: jq is required but not installed."
    echo "Install with: brew install jq (macOS) or apt-get install jq (Linux)"
    exit 1
fi

# Extract circuit config
CIRCUIT_CONFIG=$(jq -r ".circuits[] | select(.name == \"$CIRCUIT_NAME\")" "$CONFIG_FILE")

if [ -z "$CIRCUIT_CONFIG" ] || [ "$CIRCUIT_CONFIG" = "null" ]; then
    echo "Error: Circuit '$CIRCUIT_NAME' not found in $CONFIG_FILE"
    echo ""
    echo "Available circuits:"
    jq -r '.circuits[].name' "$CONFIG_FILE" | sed 's/^/  - /'
    exit 1
fi

# Extract circuit properties
DISPLAY_NAME=$(echo "$CIRCUIT_CONFIG" | jq -r '.displayName')
CIRCUIT_DIR=$(echo "$CIRCUIT_CONFIG" | jq -r '.dir')
MAIN_FILE=$(echo "$CIRCUIT_CONFIG" | jq -r '.mainFile')
PTAU_SIZE=$(echo "$CIRCUIT_CONFIG" | jq -r '.ptauSize')
DESCRIPTION=$(echo "$CIRCUIT_CONFIG" | jq -r '.description')
CONTRIBUTION_SEED=$(echo "$CIRCUIT_CONFIG" | jq -r '.contributionSeed // .name')

# Extract paths
NODE_MODULES=$(jq -r '.paths.nodeModules' "$CONFIG_FILE")
PTAU_DIR=$(jq -r '.paths.ptauDir' "$CONFIG_FILE")
PTAU_FILE_PATTERN=$(jq -r '.ptau.filePattern' "$CONFIG_FILE")
PTAU_FILE=$(echo "$PTAU_FILE_PATTERN" | sed "s/{size}/$PTAU_SIZE/")

# Make ptau path absolute (since we'll cd into circuit dir)
if [[ "$PTAU_DIR" = /* ]]; then
    PTAU_PATH="$PTAU_DIR/$PTAU_FILE"
else
    PTAU_PATH="$PWD/$PTAU_DIR/$PTAU_FILE"
fi

# Derived names
BASE_NAME=$(basename "$MAIN_FILE" .circom)

echo "==================================================================="
echo "  Compiling: $DISPLAY_NAME"
echo "==================================================================="
echo "Circuit:      $CIRCUIT_NAME"
echo "Description:  $DESCRIPTION"
echo "Directory:    $CIRCUIT_DIR"
echo "Main file:    $MAIN_FILE"
echo "ptau size:    $PTAU_SIZE"
echo "==================================================================="
echo ""

# Check ptau exists
if [ ! -f "$PTAU_PATH" ]; then
    echo "Error: ptau file not found: $PTAU_PATH"
    echo "Run compile_all.sh first to download it, or download manually:"
    PTAU_URL=$(jq -r '.ptau.baseUrl' "$CONFIG_FILE")
    echo "  curl -L -o $PTAU_PATH ${PTAU_URL}${PTAU_FILE}"
    exit 1
fi

# Navigate to circuit directory
cd "$CIRCUIT_DIR"

# Step 1: Compile circuit
echo "Step 1/4: Compiling $MAIN_FILE..."
circom "$MAIN_FILE" --r1cs --wasm --sym -l "$NODE_MODULES"

# Step 2: Generate proving key
echo "Step 2/4: Generating proving key..."
npx snarkjs groth16 setup "${BASE_NAME}.r1cs" "$PTAU_PATH" "${BASE_NAME}_0000.zkey"

# Step 3: Contribute randomness
echo "Step 3/4: Contributing randomness..."
echo "$CONTRIBUTION_SEED" | npx snarkjs zkc "${BASE_NAME}_0000.zkey" "${BASE_NAME}_final.zkey"

# Step 4: Export verification key
echo "Step 4/4: Exporting verification key..."
npx snarkjs zkey export verificationkey "${BASE_NAME}_final.zkey" verification_key.json

echo ""
echo "==================================================================="
echo "  ✅ $DISPLAY_NAME compiled successfully!"
echo "==================================================================="
echo ""

# Show circuit info
echo "Circuit stats:"
npx snarkjs r1cs info "${BASE_NAME}.r1cs" | grep -E "constraints|wires"

echo ""
echo "Generated files in $CIRCUIT_DIR/:"
echo "  - ${BASE_NAME}_final.zkey (proving key)"
echo "  - verification_key.json (verification key)"
echo "  - ${BASE_NAME}_js/ (witness generator)"
echo "  - ${BASE_NAME}.r1cs (constraint system)"
echo ""
