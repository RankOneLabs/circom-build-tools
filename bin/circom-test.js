#!/usr/bin/env node
/**
 * circom-test CLI
 * Tests circom circuits with witness generation and proof verification
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const args = process.argv.slice(2);
const circuitName = args[0];

if (!circuitName) {
    console.error('Usage: circom-test <circuit_name>');
    console.error('');
    console.error('Run "circom-list" to see available circuits.');
    process.exit(1);
}

// Check if config exists
const configFile = 'circuits.config.json';
if (!fs.existsSync(configFile)) {
    console.error(`Error: Config file not found: ${configFile}`);
    console.error('Run "circom-init" to create a template config file.');
    process.exit(1);
}

// Get path to test script
const scriptPath = path.join(__dirname, '../lib/test_circuit.sh');

try {
    execSync(`bash "${scriptPath}" "${circuitName}"`, {
        stdio: 'inherit',
        cwd: process.cwd()
    });
} catch (error) {
    process.exit(error.status || 1);
}
