#!/bin/bash
# Test a specific circuit: generate witness, create proof, verify proof
# Usage: ./scripts/test_circuit.sh <circuit_name>

set -e

CIRCUIT_NAME="$1"
CONFIG_FILE="circuits.config.json"

if [ -z "$CIRCUIT_NAME" ]; then
    echo "Usage: $0 <circuit_name>"
    echo ""
    ./lib/list-circuits.sh
    exit 1
fi

# Get circuit config
CIRCUIT_DIR=$(jq -r ".circuits[] | select(.name == \"$CIRCUIT_NAME\") | .dir" "$CONFIG_FILE")
MAIN_FILE=$(jq -r ".circuits[] | select(.name == \"$CIRCUIT_NAME\") | .mainFile" "$CONFIG_FILE")
BASE_NAME=$(basename "$MAIN_FILE" .circom)

if [ -z "$CIRCUIT_DIR" ] || [ "$CIRCUIT_DIR" = "null" ]; then
    echo "Error: Circuit '$CIRCUIT_NAME' not found"
    exit 1
fi

echo "==================================================================="
echo "  Testing Circuit: $CIRCUIT_NAME"
echo "==================================================================="
echo ""

# Step 1: Generate test input
echo "Step 1/4: Generating test input..."
node scripts/generate_test_input.js "$CIRCUIT_NAME" "test_input.json"

# Step 2: Generate witness
echo ""
echo "Step 2/4: Generating witness..."
cd "$CIRCUIT_DIR"

if [ ! -d "${BASE_NAME}_js" ]; then
    echo "Error: Circuit not compiled. Run ./scripts/compile.sh $CIRCUIT_NAME first"
    exit 1
fi

node "${BASE_NAME}_js/generate_witness.js" "${BASE_NAME}_js/${BASE_NAME}.wasm" "../test_input.json" witness.wtns

# Step 3: Generate proof
echo ""
echo "Step 3/4: Generating proof..."
TIME_START=$(date +%s%N)
npx snarkjs groth16 prove "${BASE_NAME}_final.zkey" witness.wtns proof.json public.json
TIME_END=$(date +%s%N)
PROVING_TIME_MS=$(( ($TIME_END - $TIME_START) / 1000000 ))

echo "✅ Proof generated in ${PROVING_TIME_MS}ms"

# Step 4: Verify proof
echo ""
echo "Step 4/4: Verifying proof..."
VERIFY_START=$(date +%s%N)
npx snarkjs groth16 verify verification_key.json public.json proof.json
VERIFY_EXIT=$?
VERIFY_END=$(date +%s%N)
VERIFY_TIME_MS=$(( ($VERIFY_END - $VERIFY_START) / 1000000 ))

echo "✅ Proof verified in ${VERIFY_TIME_MS}ms"

if [ $VERIFY_EXIT -eq 0 ]; then
    echo ""
    echo "==================================================================="
    echo "  ✅ Circuit test PASSED for $CIRCUIT_NAME"
    echo "==================================================================="
    echo "Proving time:      ${PROVING_TIME_MS}ms"
    echo "Verification time: ${VERIFY_TIME_MS}ms"
    echo "Proof file:        $CIRCUIT_DIR/proof.json"
    echo "Public signals:    $CIRCUIT_DIR/public.json"
    echo ""
else
    echo ""
    echo "❌ Circuit test FAILED for $CIRCUIT_NAME"
    exit 1
fi
