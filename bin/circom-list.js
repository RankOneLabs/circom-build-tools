#!/usr/bin/env node
/**
 * circom-list CLI
 * Lists all available circuits from config
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const configFile = 'circuits.config.json';

if (!fs.existsSync(configFile)) {
    console.error(`Error: Config file not found: ${configFile}`);
    console.error('Run "circom-init" to create a template config file.');
    process.exit(1);
}

const scriptPath = path.join(__dirname, '../lib/list-circuits.sh');

try {
    execSync(`bash "${scriptPath}" "${configFile}"`, {
        stdio: 'inherit',
        cwd: process.cwd()
    });
} catch (error) {
    process.exit(error.status || 1);
}
