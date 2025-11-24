const crypto = require('crypto');
const fs = require('fs');
const path = require('path');

/**
 * Generate test inputs for voting circuits
 * Creates realistic DKIM-signed email headers for testing
 */

function bigIntToChunked(bigint, k, n) {
    const chunks = [];
    const mask = (1n << BigInt(n)) - 1n;
    for (let i = 0; i < k; i++) {
        chunks.push((bigint >> (BigInt(n) * BigInt(i))) & mask);
    }
    return chunks.map(c => c.toString());
}

function generateTestInput(options = {}) {
    const {
        surveyId = '123456',
        voteChoice = '1',
        secret = '987654321',
        emailFormat = 'hybrid', // 'hybrid', 'fixed-position', or 'full-regex'
        maxHeaderBytes = 128
    } = options;

    // Generate RSA Key Pair (simulating DKIM)
    const { publicKey, privateKey } = crypto.generateKeyPairSync('rsa', {
        modulusLength: 2048,
        publicKeyEncoding: { type: 'spki', format: 'pem' },
        privateKeyEncoding: { type: 'pkcs8', format: 'pem' }
    });

    const pubKeyObj = crypto.createPublicKey(publicKey);
    const pubKeyExport = pubKeyObj.export({ format: 'jwk' });
    const modulus = BigInt('0x' + Buffer.from(pubKeyExport.n, 'base64url').toString('hex'));

    // Create email header based on format
    let emailHeader;
    switch (emailFormat) {
        case 'fixed-position':
            // Format: "Survey #NNNNNN" at fixed position
            emailHeader = `From: voter@example.com\r\nSubject: Survey #${surveyId}\r\n`;
            break;
        case 'full-regex':
            // Format: flexible, # anywhere in subject
            emailHeader = `From: voter@example.com\r\nSubject: Vote on issue #${surveyId} please\r\n`;
            break;
        case 'hybrid':
        default:
            // No survey ID in subject
            emailHeader = `From: voter@example.com\r\nSubject: My Vote\r\n`;
            break;
    }

    const headerBuffer = Buffer.from(emailHeader);

    // Pad header to maxHeaderBytes with SHA256 padding
    const paddedHeader = Buffer.alloc(maxHeaderBytes);
    headerBuffer.copy(paddedHeader);

    const originalLength = headerBuffer.length;
    let paddingOffset = originalLength;

    // SHA256 padding
    paddedHeader[paddingOffset++] = 0x80; // Append 1 bit

    // Calculate padding
    let padK = 0;
    while ((originalLength + 1 + padK + 8) % 64 !== 0) {
        padK++;
    }
    paddingOffset += padK;

    // Write length in bits (Big Endian, 64-bit)
    const lengthBits = originalLength * 8;
    paddedHeader.writeBigUInt64BE(BigInt(lengthBits), paddingOffset);

    const usedLength = paddingOffset + 8;

    // Convert to int array
    const headerInts = Array.from(paddedHeader).map(b => b.toString());

    // Sign the original header
    const sign = crypto.createSign('SHA256');
    sign.update(headerBuffer);
    sign.end();
    const signature = sign.sign(privateKey);
    const signatureBigInt = BigInt('0x' + signature.toString('hex'));

    // Format for circuit (k=17, n=121 for RSA-2048)
    const k = 17;
    const n_bits = 121;

    const pubkeyChunks = bigIntToChunked(modulus, k, n_bits);
    const signatureChunks = bigIntToChunked(signatureBigInt, k, n_bits);

    const input = {
        emailHeader: headerInts,
        emailHeaderLength: usedLength.toString(),
        pubkey: pubkeyChunks,
        signature: signatureChunks,
        surveyId: surveyId.toString(),
        voteChoice: voteChoice.toString(),
        secret: secret.toString()
    };

    return {
        input,
        metadata: {
            emailFormat,
            surveyId,
            voteChoice,
            originalHeader: emailHeader,
            headerLength: originalLength,
            paddedLength: usedLength
        }
    };
}

// CLI usage
if (require.main === module) {
    const args = process.argv.slice(2);
    const format = args[0] || 'hybrid';
    const outputFile = args[1] || `test_input_${format}.json`;

    const maxHeaderBytes = format === 'full-regex' ? 512 :
        format === 'fixed-position' ? 256 : 128;

    const { input, metadata } = generateTestInput({
        surveyId: '123456',
        voteChoice: '1',
        secret: '987654321',
        emailFormat: format,
        maxHeaderBytes
    });

    const outputPath = path.join(__dirname, outputFile);
    fs.writeFileSync(outputPath, JSON.stringify(input, null, 2));

    console.log(`✅ Generated test input for ${format} circuit`);
    console.log(`📄 Output: ${outputPath}`);
    console.log(`📧 Email header: ${metadata.originalHeader.replace(/\r\n/g, '\\r\\n')}`);
    console.log(`📊 Header length: ${metadata.headerLength} bytes (padded to ${metadata.paddedLength})`);
}

module.exports = { generateTestInput };
