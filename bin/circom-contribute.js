#!/usr/bin/env node
/**
 * circom-contribute CLI
 * Contribute randomness to Powers of Tau ceremony
 */

const { execSync } = require('child_process');
const path = require('path');

const args = process.argv.slice(2);

if (args.length < 2) {
    console.error('Usage: circom-contribute <input_ptau> <output_ptau> [contributor_name]');
    console.error('');
    console.error('Example:');
    console.error('  circom-contribute powersOfTau28_hez_final_18.ptau my_contribution_18.ptau "Alice"');
    console.error('');
    console.error('This adds your random contribution to the Powers of Tau ceremony.');
    process.exit(1);
}

const inputPtau = args[0];
const outputPtau = args[1];
const contributorName = args[2] || 'Anonymous';

const scriptPath = path.join(__dirname, '../lib/contribute-ptau.sh');

try {
    execSync(`bash "${scriptPath}" "${inputPtau}" "${outputPtau}" "${contributorName}"`, {
        stdio: 'inherit',
        cwd: process.cwd()
    });
} catch (error) {
    process.exit(error.status || 1);
}
