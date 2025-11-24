#!/bin/bash
# Contribute randomness to a Powers of Tau ceremony
# Usage: ./lib/contribute-ptau.sh <input_ptau> <output_ptau> [name]

set -e

INPUT_PTAU="$1"
OUTPUT_PTAU="$2"
CONTRIBUTOR_NAME="${3:-Anonymous}"

if [ -z "$INPUT_PTAU" ] || [ -z "$OUTPUT_PTAU" ]; then
    echo "Usage: $0 <input_ptau> <output_ptau> [contributor_name]"
    echo ""
    echo "Example:"
    echo "  $0 powersOfTau28_hez_final_18.ptau my_contribution_18.ptau \"My Name\""
    echo ""
    echo "This adds your random contribution to the ceremony."
    exit 1
fi

if [ ! -f "$INPUT_PTAU" ]; then
    echo "Error: Input ptau file not found: $INPUT_PTAU"
    exit 1
fi

if [ -f "$OUTPUT_PTAU" ]; then
    echo "Error: Output file already exists: $OUTPUT_PTAU"
    echo "Please choose a different output filename or remove the existing file."
    exit 1
fi

echo "==================================================================="
echo "  Powers of Tau Contribution"
echo "==================================================================="
echo "Input ptau:   $INPUT_PTAU"
echo "Output ptau:  $OUTPUT_PTAU"
echo "Contributor:  $CONTRIBUTOR_NAME"
echo "==================================================================="
echo ""
echo "You will be asked to provide random text/entropy."
echo "You can type random characters, move your mouse, or provide any random input."
echo ""
echo "Starting contribution..."
echo ""

# Contribute to the ceremony
npx snarkjs powersoftau contribute "$INPUT_PTAU" "$OUTPUT_PTAU" \
    --name="$CONTRIBUTOR_NAME" \
    -v

echo ""
echo "==================================================================="
echo "  ✅ Contribution completed successfully!"
echo "==================================================================="
echo ""
echo "Your contribution has been added to: $OUTPUT_PTAU"
echo ""
echo "Next steps:"
echo "  1. Verify the contribution:"
echo "     npx snarkjs powersoftau verify $OUTPUT_PTAU"
echo ""
echo "  2. (Optional) Share this ptau file with others for the ceremony"
echo "  3. Use this ptau file for circuit compilation"
echo "==================================================================="
