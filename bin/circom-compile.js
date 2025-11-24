#!/usr/bin/env node
/**
 * circom-compile CLI
 * Compiles circom circuits using config-driven approach
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const args = process.argv.slice(2);
const circuitName = args[0];
const configFile = args[1] || 'circuits.config.json';

// Check if config exists
if (!fs.existsSync(configFile)) {
    console.error(`Error: Config file not found: ${configFile}`);
    console.error('');
    console.error('Run "circom-init" to create a template config file.');
    process.exit(1);
}

// Get path to compile script
const scriptPath = path.join(__dirname, '../lib/compile-circuit.sh');

// Check if script exists
if (!fs.existsSync(scriptPath)) {
    console.error(`Error: Compile script not found: ${scriptPath}`);
    process.exit(1);
}

try {
    // Run the bash script
    execSync(`bash "${scriptPath}" "${circuitName}" "${configFile}"`, {
        stdio: 'inherit',
        cwd: process.cwd()
    });
} catch (error) {
    process.exit(error.status || 1);
}
