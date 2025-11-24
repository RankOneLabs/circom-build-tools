# @rankonelabs/circom-build-tools

Config-driven build and test tools for circom circuits.

## Features

✅ **Config-driven** - Define circuits in JSON, not bash scripts  
✅ **Automated compilation** - Compile circuits with one command  
✅ **Integrated testing** - Generate witness, proof, and verify  
✅ **Performance metrics** - Measure proving and verification time  
✅ **Portable** - Works across circom projects  

## Installation

### Global (recommended)
```bash
npm install -g @rankonelabs/circom-build-tools
```

### Per-project
```bash
npm install --save-dev @rankonelabs/circom-build-tools snarkjs
```

## Requirements

- **Node.js** >= 18.0.0
- **circom** - Circuit compiler
- **snarkjs** - Proof system tools (peer dependency)
- **jq** - JSON parser for bash
  ```bash
  # macOS
  brew install jq
  
  # Linux
  apt-get install jq
  ```
- **OS**: macOS or Linux (Windows not supported yet)

## Quick Start

```bash
# 1. Initialize config file
circom-init

# 2. Edit circuits.config.json to define your circuits

# 3. List available circuits
circom-list

# 4. Compile a circuit
circom-compile my-circuit

# 5. Test a circuit
circom-test my-circuit
```

## Configuration

Create `circuits.config.json` in your project root:

```json
{
  "circuits": [
    {
      "name": "auth",
      "displayName": "Authentication Circuit",
      "dir": "circuits/auth",
      "mainFile": "auth.circom",
      "ptauSize": 18,
      "description": "User authentication with ZK proofs",
      "contributionSeed": "auth-seed"
    }
  ],
  "paths": {
    "nodeModules": "./node_modules",
    "ptauDir": "./circuits",
    "circuitsRoot": "./circuits"
  },
  "ptau": {
    "baseUrl": "https://storage.googleapis.com/zkevm/ptau/",
    "filePattern": "powersOfTau28_hez_final_{size}.ptau"
  }
}
```

## CLI Commands

### `circom-init`
Initialize a template `circuits.config.json` file.

```bash
circom-init
```

### `circom-list`
List all available circuits from config.

```bash
circom-list
```

**Output:**
```
Available circuits in circuits.config.json:

  auth
    Display: Authentication Circuit
    Description: User authentication with ZK proofs
    Constraints: ~150k
    ptau: 18
```

### `circom-compile <circuit_name>`
Compile a circuit, generate proving key, and export verification key.

```bash
circom-compile auth
```

**Steps performed:**
1. Compile circuit with circom
2. Generate proving key with Groth16 setup
3. Contribute randomness
4. Export verification key

### `circom-test <circuit_name>`
End-to-end test: generate witness, create proof, verify.

```bash
circom-test auth
```

**Steps performed:**
1. Generate test input
2. Generate witness
3. Generate proof (timed)
4. Verify proof (timed)

### `circom-contribute <input_ptau> <output_ptau> [name]`
Add your random contribution to a Powers of Tau ceremony.

```bash
circom-contribute powersOfTau28_hez_final_18.ptau my_contribution_18.ptau "Alice"
```

**What it does:**
- Takes an existing ptau file
- Asks you to provide random entropy
- Creates a new ptau file with your contribution
- Allows participation in trusted setup ceremonies

**Output:**
```
===================================================================
  ✅ Circuit test PASSED for auth
===================================================================
Proving time:      8543ms
Verification time: 15ms
```

## Config Schema

### Circuit Definition

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Unique circuit identifier |
| `displayName` | string | Human-readable name |
| `dir` | string | Directory containing circuit files |
| `mainFile` | string | Main circom file (e.g., `main.circom`) |
| `ptauSize` | number | Powers of tau size (18, 19, etc.) |
| `description` | string | Circuit description |
| `contributionSeed` | string | Seed for randomness contribution |

### Paths

| Field | Type | Description |
|-------|------|-------------|
| `nodeModules` | string | Path to node_modules (for circom includes) |
| `ptauDir` | string | Directory for ptau files |
| `circuitsRoot` | string | Root directory for circuits |

## Examples

### Multiple Circuits

```json
{
  "circuits": [
    {
      "name": "auth",
      "dir": "circuits/auth",
      "mainFile": "auth.circom",
      "ptauSize": 18
    },
    {
      "name": "voting",
      "dir": "circuits/voting",
      "mainFile": "vote.circom",
      "ptauSize": 19
    }
  ]
}
```

```bash
circom-compile auth    # Compile auth circuit
circom-compile voting  # Compile voting circuit
```

## Development

### Local Testing

```bash
# Clone repo
git clone https://github.com/RankOneLabs/circom-build-tools.git
cd circom-build-tools

# Link locally
npm link

# Test in another project
cd /path/to/your/circuits
npm link @rankonelabs/circom-build-tools
circom-init
```

## Troubleshooting

### `jq: command not found`
Install jq:
```bash
brew install jq  # macOS
apt-get install jq  # Linux
```

### `Circuit not found in config`
- Check circuit name spelling
- Run `circom-list` to see available circuits
- Verify `circuits.config.json` syntax

### `ptau file not found`
The script will attempt to download ptau files automatically. If download fails:
```bash
curl -L -o circuits/powersOfTau28_hez_final_18.ptau \
  https://storage.googleapis.com/zkevm/ptau/powersOfTau28_hez_final_18.ptau
```

## License

MIT

## Contributing

Contributions welcome! Please submit issues and pull requests.

## Roadmap

- [ ] Windows support (PowerShell scripts or pure Node.js)
- [ ] TypeScript rewrite for better cross-platform support
- [ ] Config validation with JSON schema
- [ ] Batch compilation
- [ ] Watch mode for development
- [ ] Integration with popular circom frameworks
