#!/usr/bin/env node
/**
 * circom-init CLI
 * Initialize a circuits.config.json template
 */

const fs = require('fs');
const path = require('path');

const configFile = 'circuits.config.json';

if (fs.existsSync(configFile)) {
    console.error(`Error: ${configFile} already exists!`);
    console.error('Remove it first or edit it manually.');
    process.exit(1);
}

// Copy template from package
const templatePath = path.join(__dirname, '../templates/circuits.config.json');
const template = fs.readFileSync(templatePath, 'utf-8');

fs.writeFileSync(configFile, template);

console.log(`✅ Created ${configFile}`);
console.log('');
console.log('Next steps:');
console.log('  1. Edit circuits.config.json to define your circuits');
console.log('  2. Run "circom-list" to see available circuits');
console.log('  3. Run "circom-compile <circuit_name>" to compile');
console.log('  4. Run "circom-test <circuit_name>" to test');
