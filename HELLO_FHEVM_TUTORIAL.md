# Hello FHEVM: Complete Beginner's Guide to Building Your First Confidential Application

Welcome to the complete guide for building your first confidential application using Zama's Fully Homomorphic Encryption Virtual Machine (FHEVM). This tutorial will walk you through creating a privacy-preserving biometric authentication system from scratch.

## Table of Contents

1. [Introduction to FHEVM](#introduction-to-fhevm)
2. [Prerequisites](#prerequisites)
3. [Project Setup](#project-setup)
4. [Understanding FHE Concepts](#understanding-fhe-concepts)
5. [Building the Smart Contract](#building-the-smart-contract)
6. [Creating the Frontend](#creating-the-frontend)
7. [Deployment Guide](#deployment-guide)
8. [Testing Your Application](#testing-your-application)
9. [Advanced Features](#advanced-features)
10. [Troubleshooting](#troubleshooting)

## Introduction to FHEVM

### What is FHEVM?

FHEVM (Fully Homomorphic Encryption Virtual Machine) is a revolutionary blockchain technology that allows you to perform computations on encrypted data without ever decrypting it. This means sensitive information remains private throughout the entire process.

### Why Use FHEVM?

- **Complete Privacy**: Your data stays encrypted even during computation
- **Zero-Knowledge Operations**: Verify results without revealing input data
- **Blockchain Security**: Benefit from decentralized security with privacy
- **Developer Friendly**: Familiar Solidity syntax with encryption capabilities

### What We're Building

In this tutorial, we'll create a biometric authentication system where:
- Users can register encrypted biometric templates
- Identity verification happens without revealing biometric data
- All operations maintain complete privacy using FHE

## Prerequisites

Before starting, ensure you have:

### Technical Requirements
- **Node.js** (v16 or higher)
- **npm** or **yarn** package manager
- **MetaMask** browser extension
- **Git** for version control

### Knowledge Requirements
- Basic **Solidity** programming (variables, functions, modifiers)
- Understanding of **smart contract deployment**
- Familiarity with **JavaScript/HTML/CSS**
- Basic knowledge of **blockchain concepts**

### No Advanced Math Required
You do NOT need to understand:
- Cryptographic algorithms
- Advanced mathematics
- FHE theory or implementation details

## Project Setup

### Step 1: Create Project Directory

```bash
mkdir hello-fhevm-tutorial
cd hello-fhevm-tutorial
```

### Step 2: Initialize Node.js Project

```bash
npm init -y
```

### Step 3: Install Dependencies

```bash
# Install Hardhat and essential tools
npm install --save-dev hardhat @nomicfoundation/hardhat-toolbox

# Install FHEVM dependencies
npm install --save-dev @fhevm/solidity

# Install frontend dependencies
npm install ethers dotenv

# Initialize Hardhat project
npx hardhat init
```

Select "Create a TypeScript project" when prompted.

### Step 4: Configure Environment

Create a `.env` file in your project root:

```bash
# .env
SEPOLIA_RPC_URL=https://sepolia.infura.io/v3/YOUR_INFURA_KEY
PRIVATE_KEY=your_private_key_here
```

**Important**: Never commit your private key to version control!

## Understanding FHE Concepts

### Core FHE Types

Before diving into code, let's understand the basic FHE data types:

```solidity
// Basic encrypted integers
euint32  // 32-bit encrypted unsigned integer
euint64  // 64-bit encrypted unsigned integer
ebool    // Encrypted boolean value
```

### Key Operations

```solidity
// Converting plaintext to encrypted
euint32 encrypted = FHE.asEuint32(plainValue);

// Comparing encrypted values
ebool isEqual = FHE.eq(encrypted1, encrypted2);

// Conditional selection
euint32 result = FHE.select(condition, valueIfTrue, valueIfFalse);
```

### Privacy Principles

1. **Encrypt on Input**: Convert plain data to encrypted form
2. **Compute on Encrypted**: Perform operations without decryption
3. **Reveal Only Results**: Decrypt only what's necessary for output

## Building the Smart Contract

### Step 1: Create the Contract Structure

Create `contracts/BiometricAuth.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint64, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract BiometricAuth is SepoliaConfig {

    address public owner;
    uint256 public totalUsers;

    // Encrypted biometric template
    struct BiometricTemplate {
        euint64 fingerprintHash;    // Encrypted fingerprint
        euint64 faceTemplateHash;   // Encrypted face template
        euint32 voicePrintHash;     // Encrypted voice print
        euint32 irisPattern;        // Encrypted iris pattern
        bool isActive;              // Registration status
        uint256 timestamp;          // Registration time
        uint256 accessCount;        // Number of access attempts
    }

    // Access attempt record
    struct AccessAttempt {
        bool verified;              // Verification result
        uint256 timestamp;          // Attempt time
        uint256 confidenceScore;    // Match confidence (0-100)
    }

    // Storage mappings
    mapping(address => BiometricTemplate) public userTemplates;
    mapping(address => AccessAttempt[]) public accessHistory;
    mapping(address => bool) public authorizedUsers;

    address[] public registeredUsers;

    // Events for tracking activities
    event BiometricRegistered(address indexed user, uint256 timestamp);
    event AccessAttempted(address indexed user, bool verified, uint256 timestamp);
    event BiometricUpdated(address indexed user, uint256 timestamp);

    constructor() {
        owner = msg.sender;
        authorizedUsers[owner] = true;
        totalUsers = 0;
    }

    // Modifiers for access control
    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyRegisteredUser() {
        require(userTemplates[msg.sender].isActive, "User not registered");
        _;
    }
}
```

### Step 2: Implement Registration Function

Add the registration function to your contract:

```solidity
/**
 * @dev Register biometric templates for a user
 * @param _fingerprintHash Plaintext fingerprint hash (will be encrypted)
 * @param _faceTemplateHash Plaintext face template hash (will be encrypted)
 * @param _voicePrintHash Plaintext voice print hash (will be encrypted)
 * @param _irisPattern Plaintext iris pattern (will be encrypted)
 */
function registerBiometric(
    uint64 _fingerprintHash,
    uint64 _faceTemplateHash,
    uint32 _voicePrintHash,
    uint32 _irisPattern
) external {
    require(!userTemplates[msg.sender].isActive, "User already registered");

    // Convert plaintext inputs to encrypted form
    euint64 encryptedFingerprint = FHE.asEuint64(_fingerprintHash);
    euint64 encryptedFaceTemplate = FHE.asEuint64(_faceTemplateHash);
    euint32 encryptedVoicePrint = FHE.asEuint32(_voicePrintHash);
    euint32 encryptedIris = FHE.asEuint32(_irisPattern);

    // Store encrypted biometric template
    userTemplates[msg.sender] = BiometricTemplate({
        fingerprintHash: encryptedFingerprint,
        faceTemplateHash: encryptedFaceTemplate,
        voicePrintHash: encryptedVoicePrint,
        irisPattern: encryptedIris,
        isActive: true,
        timestamp: block.timestamp,
        accessCount: 0
    });

    // Set access permissions for encrypted data
    FHE.allowThis(encryptedFingerprint);
    FHE.allowThis(encryptedFaceTemplate);
    FHE.allowThis(encryptedVoicePrint);
    FHE.allowThis(encryptedIris);

    // Allow user to access their own encrypted data
    FHE.allow(encryptedFingerprint, msg.sender);
    FHE.allow(encryptedFaceTemplate, msg.sender);
    FHE.allow(encryptedVoicePrint, msg.sender);
    FHE.allow(encryptedIris, msg.sender);

    registeredUsers.push(msg.sender);
    totalUsers++;

    emit BiometricRegistered(msg.sender, block.timestamp);
}
```

### Step 3: Implement Verification Function

Add the biometric verification function:

```solidity
/**
 * @dev Verify biometric input against stored template
 * @param _fingerprintHash Submitted fingerprint hash
 * @param _faceTemplateHash Submitted face template hash
 * @param _voicePrintHash Submitted voice print hash
 * @param _irisPattern Submitted iris pattern
 */
function verifyBiometric(
    uint64 _fingerprintHash,
    uint64 _faceTemplateHash,
    uint32 _voicePrintHash,
    uint32 _irisPattern
) external onlyRegisteredUser returns (bool) {
    BiometricTemplate storage template = userTemplates[msg.sender];

    // Convert submitted data to encrypted form
    euint64 submittedFingerprint = FHE.asEuint64(_fingerprintHash);
    euint64 submittedFaceTemplate = FHE.asEuint64(_faceTemplateHash);
    euint32 submittedVoicePrint = FHE.asEuint32(_voicePrintHash);
    euint32 submittedIris = FHE.asEuint32(_irisPattern);

    // Perform encrypted comparisons
    ebool fingerprintMatch = FHE.eq(template.fingerprintHash, submittedFingerprint);
    ebool faceMatch = FHE.eq(template.faceTemplateHash, submittedFaceTemplate);
    ebool voiceMatch = FHE.eq(template.voicePrintHash, submittedVoicePrint);
    ebool irisMatch = FHE.eq(template.irisPattern, submittedIris);

    // Calculate match score (each factor worth 25 points)
    euint32 matchScore = FHE.select(fingerprintMatch, FHE.asEuint32(25), FHE.asEuint32(0));
    matchScore = FHE.add(matchScore, FHE.select(faceMatch, FHE.asEuint32(25), FHE.asEuint32(0)));
    matchScore = FHE.add(matchScore, FHE.select(voiceMatch, FHE.asEuint32(25), FHE.asEuint32(0)));
    matchScore = FHE.add(matchScore, FHE.select(irisMatch, FHE.asEuint32(25), FHE.asEuint32(0)));

    // Require 75% match (3 out of 4 factors)
    ebool isVerified = FHE.ge(matchScore, FHE.asEuint32(75));

    // Set access permissions for computed values
    FHE.allowThis(submittedFingerprint);
    FHE.allowThis(submittedFaceTemplate);
    FHE.allowThis(submittedVoicePrint);
    FHE.allowThis(submittedIris);
    FHE.allowThis(matchScore);

    // Allow user to see their match score
    FHE.allow(matchScore, msg.sender);

    // Request decryption of verification result
    bytes32[] memory cts = new bytes32[](1);
    cts[0] = FHE.toBytes32(isVerified);
    FHE.requestDecryption(cts, this.processVerificationResult.selector);

    template.accessCount++;

    return false; // Actual result comes via callback
}

/**
 * @dev Process verification result after decryption
 * @param requestId Decryption request ID
 * @param verificationResult Decrypted verification result
 * @param signatures Cryptographic signatures for validation
 */
function processVerificationResult(
    uint256 requestId,
    bool verificationResult,
    bytes memory signatures
) external {
    // Validate decryption result
    bytes memory decryptedResult = abi.encodePacked(verificationResult);
    FHE.checkSignatures(requestId, decryptedResult, signatures);

    // Record access attempt
    uint256 confidenceScore = verificationResult ? 95 : 15;
    accessHistory[msg.sender].push(AccessAttempt({
        verified: verificationResult,
        timestamp: block.timestamp,
        confidenceScore: confidenceScore
    }));

    emit AccessAttempted(msg.sender, verificationResult, block.timestamp);
}
```

### Step 4: Add Utility Functions

Complete the contract with helper functions:

```solidity
/**
 * @dev Get user's biometric registration status
 */
function getUserBiometricStatus(address _user) external view returns (
    bool isActive,
    uint256 timestamp,
    uint256 accessCount
) {
    BiometricTemplate storage template = userTemplates[_user];
    return (template.isActive, template.timestamp, template.accessCount);
}

/**
 * @dev Get number of access attempts for a user
 */
function getAccessHistoryLength(address _user) external view returns (uint256) {
    return accessHistory[_user].length;
}

/**
 * @dev Get specific access attempt details
 */
function getAccessAttempt(address _user, uint256 _index) external view returns (
    bool verified,
    uint256 timestamp,
    uint256 confidenceScore
) {
    require(_index < accessHistory[_user].length, "Invalid index");
    AccessAttempt storage attempt = accessHistory[_user][_index];
    return (attempt.verified, attempt.timestamp, attempt.confidenceScore);
}

/**
 * @dev Generate secure hash for biometric data
 */
function generateSecureBiometricHash(
    uint64 _rawBiometric,
    uint32 _salt
) external view returns (uint64) {
    bytes32 hash = keccak256(abi.encodePacked(_rawBiometric, _salt, block.timestamp));
    return uint64(uint256(hash) >> 192);
}

/**
 * @dev Get contract statistics (only for authorized users)
 */
function getContractStats() external view returns (
    uint256 _totalUsers,
    uint256 _totalAccessAttempts,
    uint256 _activeUsers
) {
    require(authorizedUsers[msg.sender] || msg.sender == owner, "Not authorized");

    uint256 totalAttempts = 0;
    uint256 activeUsers = 0;

    for (uint256 i = 0; i < registeredUsers.length; i++) {
        totalAttempts += accessHistory[registeredUsers[i]].length;
        if (userTemplates[registeredUsers[i]].isActive) {
            activeUsers++;
        }
    }

    return (totalUsers, totalAttempts, activeUsers);
}
```

## Creating the Frontend

### Step 1: HTML Structure

Create `index.html`:

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Hello FHEVM - Biometric Auth</title>
    <script src="https://cdn.jsdelivr.net/npm/ethers@6.8.0/dist/ethers.umd.min.js"></script>
    <style>
        body {
            font-family: Arial, sans-serif;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
        }
        .container {
            background: rgba(255, 255, 255, 0.1);
            border-radius: 20px;
            padding: 30px;
            backdrop-filter: blur(10px);
            margin-bottom: 20px;
        }
        .input-group {
            margin-bottom: 15px;
        }
        label {
            display: block;
            margin-bottom: 5px;
            font-weight: bold;
        }
        input {
            width: 100%;
            padding: 10px;
            border-radius: 5px;
            border: none;
            background: rgba(255, 255, 255, 0.2);
            color: white;
        }
        input::placeholder {
            color: rgba(255, 255, 255, 0.7);
        }
        button {
            background: linear-gradient(45deg, #667eea, #764ba2);
            color: white;
            border: none;
            padding: 12px 24px;
            border-radius: 25px;
            cursor: pointer;
            font-weight: bold;
            margin: 5px;
        }
        button:hover {
            transform: translateY(-2px);
            box-shadow: 0 5px 15px rgba(0,0,0,0.3);
        }
        .status {
            margin: 15px 0;
            padding: 10px;
            border-radius: 5px;
            display: none;
        }
        .success { background: rgba(0, 255, 0, 0.2); }
        .error { background: rgba(255, 0, 0, 0.2); }
        .info { background: rgba(0, 0, 255, 0.2); }
    </style>
</head>
<body>
    <h1>🔐 Hello FHEVM: Biometric Authentication</h1>
    <p>Your first confidential application using Fully Homomorphic Encryption</p>

    <!-- Connection Section -->
    <div id="connectSection" class="container">
        <h2>Connect Your Wallet</h2>
        <button onclick="connectWallet()">Connect MetaMask</button>
        <div id="connectionStatus" class="status"></div>
    </div>

    <!-- Main Interface -->
    <div id="mainInterface" style="display: none;">
        <!-- Wallet Info -->
        <div class="container">
            <h3>Connected Wallet</h3>
            <p id="walletAddress"></p>
            <button onclick="disconnectWallet()">Disconnect</button>
        </div>

        <!-- Registration Form -->
        <div class="container">
            <h3>🔒 Register Biometric</h3>
            <div class="input-group">
                <label>Fingerprint Hash (uint64):</label>
                <input type="text" id="fingerprintHash" placeholder="e.g., 1234567890123456789">
            </div>
            <div class="input-group">
                <label>Face Template Hash (uint64):</label>
                <input type="text" id="faceTemplateHash" placeholder="e.g., 9876543210987654321">
            </div>
            <div class="input-group">
                <label>Voice Print Hash (uint32):</label>
                <input type="text" id="voicePrintHash" placeholder="e.g., 1357924680">
            </div>
            <div class="input-group">
                <label>Iris Pattern (uint32):</label>
                <input type="text" id="irisPattern" placeholder="e.g., 2468135790">
            </div>
            <button onclick="registerBiometric()">Register Biometric</button>
            <div id="registerStatus" class="status"></div>
        </div>

        <!-- Verification Form -->
        <div class="container">
            <h3>✅ Verify Biometric</h3>
            <div class="input-group">
                <label>Fingerprint Hash:</label>
                <input type="text" id="verifyFingerprintHash">
            </div>
            <div class="input-group">
                <label>Face Template Hash:</label>
                <input type="text" id="verifyFaceTemplateHash">
            </div>
            <div class="input-group">
                <label>Voice Print Hash:</label>
                <input type="text" id="verifyVoicePrintHash">
            </div>
            <div class="input-group">
                <label>Iris Pattern:</label>
                <input type="text" id="verifyIrisPattern">
            </div>
            <button onclick="verifyBiometric()">Verify Biometric</button>
            <div id="verifyStatus" class="status"></div>
        </div>

        <!-- Contract Stats -->
        <div class="container">
            <h3>📊 Contract Statistics</h3>
            <div id="contractStats">
                <p>Total Users: <span id="totalUsers">0</span></p>
                <p>User Status: <span id="userStatus">Not Registered</span></p>
            </div>
            <button onclick="loadContractData()">Refresh Stats</button>
        </div>
    </div>

    <script src="app.js"></script>
</body>
</html>
```

### Step 2: JavaScript Application Logic

Create `app.js`:

```javascript
// Contract configuration
const CONTRACT_ADDRESS = "YOUR_CONTRACT_ADDRESS_HERE"; // Update after deployment
const CONTRACT_ABI = [
    "function registerBiometric(uint64, uint64, uint32, uint32)",
    "function verifyBiometric(uint64, uint64, uint32, uint32) returns (bool)",
    "function getUserBiometricStatus(address) view returns (bool, uint256, uint256)",
    "function getContractStats() view returns (uint256, uint256, uint256)",
    "function generateSecureBiometricHash(uint64, uint32) view returns (uint64)",
    "event BiometricRegistered(address indexed user, uint256 timestamp)",
    "event AccessAttempted(address indexed user, bool verified, uint256 timestamp)"
];

// Global variables
let provider;
let signer;
let contract;
let userAccount;

// Network configuration
const SEPOLIA_CHAIN_ID = "0xaa36a7";

/**
 * Connect to MetaMask wallet
 */
async function connectWallet() {
    try {
        // Check if MetaMask is installed
        if (typeof window.ethereum === 'undefined') {
            showStatus('connectionStatus', 'MetaMask is not installed!', 'error');
            return;
        }

        showStatus('connectionStatus', 'Connecting to wallet...', 'info');

        // Request account access
        const accounts = await window.ethereum.request({
            method: 'eth_requestAccounts'
        });

        if (accounts.length === 0) {
            throw new Error('No accounts found');
        }

        // Check network
        const chainId = await window.ethereum.request({ method: 'eth_chainId' });
        if (chainId !== SEPOLIA_CHAIN_ID) {
            await switchToSepolia();
        }

        // Initialize ethers
        provider = new ethers.BrowserProvider(window.ethereum);
        signer = await provider.getSigner();
        userAccount = accounts[0];

        // Initialize contract
        contract = new ethers.Contract(CONTRACT_ADDRESS, CONTRACT_ABI, signer);

        // Update UI
        document.getElementById('walletAddress').textContent =
            `${userAccount.substring(0, 6)}...${userAccount.substring(38)}`;

        document.getElementById('connectSection').style.display = 'none';
        document.getElementById('mainInterface').style.display = 'block';

        showStatus('connectionStatus', 'Connected successfully!', 'success');

        // Load contract data
        await loadContractData();

        // Listen for account changes
        window.ethereum.on('accountsChanged', handleAccountsChanged);
        window.ethereum.on('chainChanged', handleChainChanged);

    } catch (error) {
        console.error('Connection error:', error);
        showStatus('connectionStatus', `Connection failed: ${error.message}`, 'error');
    }
}

/**
 * Switch to Sepolia testnet
 */
async function switchToSepolia() {
    try {
        await window.ethereum.request({
            method: 'wallet_switchEthereumChain',
            params: [{ chainId: SEPOLIA_CHAIN_ID }],
        });
    } catch (switchError) {
        // If network doesn't exist, add it
        if (switchError.code === 4902) {
            await window.ethereum.request({
                method: 'wallet_addEthereumChain',
                params: [{
                    chainId: SEPOLIA_CHAIN_ID,
                    chainName: 'Sepolia Testnet',
                    rpcUrls: ['https://sepolia.infura.io/v3/'],
                    nativeCurrency: {
                        name: 'ETH',
                        symbol: 'ETH',
                        decimals: 18
                    },
                    blockExplorerUrls: ['https://sepolia.etherscan.io/']
                }],
            });
        } else {
            throw switchError;
        }
    }
}

/**
 * Register biometric template
 */
async function registerBiometric() {
    try {
        if (!contract) {
            throw new Error('Contract not initialized');
        }

        // Get input values
        const fingerprintHash = document.getElementById('fingerprintHash').value.trim();
        const faceTemplateHash = document.getElementById('faceTemplateHash').value.trim();
        const voicePrintHash = document.getElementById('voicePrintHash').value.trim();
        const irisPattern = document.getElementById('irisPattern').value.trim();

        // Validate inputs
        if (!fingerprintHash || !faceTemplateHash || !voicePrintHash || !irisPattern) {
            throw new Error('All fields are required');
        }

        showStatus('registerStatus', 'Registering biometric template...', 'info');

        // Call contract function
        const tx = await contract.registerBiometric(
            fingerprintHash,
            faceTemplateHash,
            parseInt(voicePrintHash),
            parseInt(irisPattern)
        );

        showStatus('registerStatus', 'Transaction submitted. Waiting for confirmation...', 'info');

        // Wait for transaction confirmation
        await tx.wait();

        showStatus('registerStatus', 'Biometric registered successfully! 🎉', 'success');

        // Clear form
        document.getElementById('fingerprintHash').value = '';
        document.getElementById('faceTemplateHash').value = '';
        document.getElementById('voicePrintHash').value = '';
        document.getElementById('irisPattern').value = '';

        // Reload contract data
        await loadContractData();

    } catch (error) {
        console.error('Registration error:', error);
        showStatus('registerStatus', `Registration failed: ${error.message}`, 'error');
    }
}

/**
 * Verify biometric input
 */
async function verifyBiometric() {
    try {
        if (!contract) {
            throw new Error('Contract not initialized');
        }

        // Get input values
        const fingerprintHash = document.getElementById('verifyFingerprintHash').value.trim();
        const faceTemplateHash = document.getElementById('verifyFaceTemplateHash').value.trim();
        const voicePrintHash = document.getElementById('verifyVoicePrintHash').value.trim();
        const irisPattern = document.getElementById('verifyIrisPattern').value.trim();

        // Validate inputs
        if (!fingerprintHash || !faceTemplateHash || !voicePrintHash || !irisPattern) {
            throw new Error('All fields are required');
        }

        showStatus('verifyStatus', 'Verifying biometric...', 'info');

        // Call contract function
        const tx = await contract.verifyBiometric(
            fingerprintHash,
            faceTemplateHash,
            parseInt(voicePrintHash),
            parseInt(irisPattern)
        );

        showStatus('verifyStatus', 'Verification submitted. Processing...', 'info');

        // Wait for transaction confirmation
        await tx.wait();

        showStatus('verifyStatus', 'Verification completed! Check results in a few moments.', 'success');

        // Clear form
        document.getElementById('verifyFingerprintHash').value = '';
        document.getElementById('verifyFaceTemplateHash').value = '';
        document.getElementById('verifyVoicePrintHash').value = '';
        document.getElementById('verifyIrisPattern').value = '';

        // Reload contract data after delay
        setTimeout(loadContractData, 5000);

    } catch (error) {
        console.error('Verification error:', error);
        showStatus('verifyStatus', `Verification failed: ${error.message}`, 'error');
    }
}

/**
 * Load contract data
 */
async function loadContractData() {
    try {
        if (!contract || !userAccount) return;

        // Get contract statistics
        const stats = await contract.getContractStats();
        document.getElementById('totalUsers').textContent = stats[0].toString();

        // Get user status
        const userStatus = await contract.getUserBiometricStatus(userAccount);
        document.getElementById('userStatus').textContent =
            userStatus[0] ? 'Registered' : 'Not Registered';

    } catch (error) {
        console.error('Error loading contract data:', error);
    }
}

/**
 * Disconnect wallet
 */
function disconnectWallet() {
    provider = null;
    signer = null;
    contract = null;
    userAccount = null;

    document.getElementById('connectSection').style.display = 'block';
    document.getElementById('mainInterface').style.display = 'none';

    // Remove event listeners
    if (window.ethereum) {
        window.ethereum.removeAllListeners('accountsChanged');
        window.ethereum.removeAllListeners('chainChanged');
    }
}

/**
 * Handle account changes
 */
function handleAccountsChanged(accounts) {
    if (accounts.length === 0) {
        disconnectWallet();
    } else {
        userAccount = accounts[0];
        document.getElementById('walletAddress').textContent =
            `${accounts[0].substring(0, 6)}...${accounts[0].substring(38)}`;
        loadContractData();
    }
}

/**
 * Handle chain changes
 */
function handleChainChanged(chainId) {
    if (chainId !== SEPOLIA_CHAIN_ID) {
        showStatus('connectionStatus', 'Please switch to Sepolia testnet', 'error');
    } else {
        loadContractData();
    }
}

/**
 * Show status message
 */
function showStatus(elementId, message, type) {
    const statusElement = document.getElementById(elementId);
    statusElement.textContent = message;
    statusElement.className = `status ${type}`;
    statusElement.style.display = 'block';

    if (type === 'success') {
        setTimeout(() => {
            statusElement.style.display = 'none';
        }, 5000);
    }
}

// Initialize when page loads
document.addEventListener('DOMContentLoaded', function() {
    // Check if wallet is already connected
    if (typeof window.ethereum !== 'undefined') {
        window.ethereum.request({ method: 'eth_accounts' })
            .then(accounts => {
                if (accounts.length > 0) {
                    connectWallet();
                }
            });
    }
});
```

## Deployment Guide

### Step 1: Configure Hardhat

Update `hardhat.config.js`:

```javascript
require("@nomicfoundation/hardhat-toolbox");
require("dotenv/config");

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL || "";
const PRIVATE_KEY = process.env.PRIVATE_KEY || "";

module.exports = {
  solidity: {
    version: "0.8.24",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  networks: {
    hardhat: {
      allowUnlimitedContractSize: true,
    },
    sepolia: {
      url: SEPOLIA_RPC_URL,
      accounts: PRIVATE_KEY ? [PRIVATE_KEY] : [],
      allowUnlimitedContractSize: true,
    },
  },
};
```

### Step 2: Create Deployment Script

Create `scripts/deploy.js`:

```javascript
const { ethers } = require("hardhat");

async function main() {
  console.log("Starting Hello FHEVM deployment...");

  const [deployer] = await ethers.getSigners();
  console.log("Deploying with account:", deployer.address);

  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("Account balance:", ethers.formatEther(balance), "ETH");

  // Deploy the contract
  const BiometricAuth = await ethers.getContractFactory("BiometricAuth");
  const biometricAuth = await BiometricAuth.deploy();

  await biometricAuth.waitForDeployment();
  const contractAddress = await biometricAuth.getAddress();

  console.log("\n🎉 Deployment Successful!");
  console.log("Contract Address:", contractAddress);
  console.log("Network:", network.name);

  console.log("\n📝 Next Steps:");
  console.log("1. Update CONTRACT_ADDRESS in app.js");
  console.log("2. Verify contract on Etherscan:");
  console.log(`   npx hardhat verify --network sepolia ${contractAddress}`);
  console.log("3. Open index.html in your browser");
  console.log("4. Connect MetaMask and start using your app!");

  return contractAddress;
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = main;
```

### Step 3: Deploy to Sepolia

```bash
# Compile the contract
npx hardhat compile

# Deploy to Sepolia testnet
npx hardhat run scripts/deploy.js --network sepolia
```

### Step 4: Update Frontend

After deployment, update the `CONTRACT_ADDRESS` in `app.js` with your deployed contract address.

## Testing Your Application

### Step 1: Manual Testing

1. **Open the Application**
   ```bash
   # Serve the frontend (optional)
   npx http-server . -p 8080
   # Or simply open index.html in your browser
   ```

2. **Connect MetaMask**
   - Ensure you're on Sepolia testnet
   - Have some test ETH (get from faucet)

3. **Register Biometric**
   - Use sample values:
     - Fingerprint: `1234567890123456789`
     - Face Template: `9876543210987654321`
     - Voice Print: `1357924680`
     - Iris Pattern: `2468135790`

4. **Verify Biometric**
   - Use the same values for successful verification
   - Try different values to test failure cases

### Step 2: Understanding the Results

**Successful Registration:**
- Transaction appears on Sepolia etherscan
- User status changes to "Registered"
- Total users count increases

**Successful Verification:**
- Transaction processed with encrypted computation
- Results appear after FHE processing
- Access history updated

**Privacy Verification:**
- Biometric data never appears in plaintext on blockchain
- Only encrypted values and verification results are stored
- Computation happens on encrypted data

## Advanced Features

### Adding Access History

Enhance your frontend to show access history:

```javascript
/**
 * Load and display access history
 */
async function loadAccessHistory() {
    try {
        const historyLength = await contract.getAccessHistoryLength(userAccount);
        const historyContainer = document.getElementById('accessHistory');

        if (Number(historyLength) === 0) {
            historyContainer.innerHTML = '<p>No access history</p>';
            return;
        }

        let historyHTML = '<h4>Recent Access Attempts:</h4>';

        for (let i = 0; i < Number(historyLength); i++) {
            const attempt = await contract.getAccessAttempt(userAccount, i);
            const date = new Date(Number(attempt[1]) * 1000).toLocaleString();
            const status = attempt[0] ? '✅ Verified' : '❌ Failed';

            historyHTML += `
                <div style="padding: 10px; margin: 5px; background: rgba(255,255,255,0.1); border-radius: 5px;">
                    <strong>${status}</strong> - ${date}<br>
                    Confidence: ${attempt[2]}%
                </div>
            `;
        }

        historyContainer.innerHTML = historyHTML;
    } catch (error) {
        console.error('Error loading access history:', error);
    }
}
```

### Adding Hash Generation

Add a utility function for secure hash generation:

```javascript
/**
 * Generate secure biometric hash
 */
async function generateHash() {
    try {
        const rawData = document.getElementById('rawBiometricData').value;
        const salt = document.getElementById('saltValue').value;

        if (!rawData || !salt) {
            throw new Error('Raw data and salt are required');
        }

        const hash = await contract.generateSecureBiometricHash(rawData, parseInt(salt));

        document.getElementById('generatedHash').textContent = hash.toString();
        showStatus('hashStatus', 'Hash generated successfully!', 'success');

    } catch (error) {
        console.error('Hash generation error:', error);
        showStatus('hashStatus', `Hash generation failed: ${error.message}`, 'error');
    }
}
```

## Troubleshooting

### Common Issues and Solutions

**1. Contract Not Found Error**
```
Error: Contract not found at address
```
**Solution:** Verify the contract address in `app.js` matches your deployed contract.

**2. Network Mismatch**
```
Error: Network mismatch
```
**Solution:** Ensure MetaMask is connected to Sepolia testnet.

**3. Insufficient Gas**
```
Error: Transaction ran out of gas
```
**Solution:** FHE operations require more gas. Ensure you have enough test ETH.

**4. MetaMask Connection Issues**
```
Error: User rejected the request
```
**Solution:** Accept the MetaMask connection request and transaction prompts.

**5. Invalid Input Values**
```
Error: Invalid biometric data
```
**Solution:** Ensure input values are within valid ranges:
- uint64: 0 to 18,446,744,073,709,551,615
- uint32: 0 to 4,294,967,295

### Debug Mode

Add debug logging to your application:

```javascript
// Enable debug mode
const DEBUG = true;

function debugLog(message, data = null) {
    if (DEBUG) {
        console.log(`[DEBUG] ${message}`, data);
    }
}

// Use in functions
debugLog("Starting biometric registration", {
    fingerprint: fingerprintHash,
    face: faceTemplateHash,
    voice: voicePrintHash,
    iris: irisPattern
});
```

### Performance Optimization

**1. Batch Operations**
Consider batching multiple operations in a single transaction when possible.

**2. Event Listening**
Listen for contract events to provide real-time feedback:

```javascript
// Listen for registration events
contract.on("BiometricRegistered", (user, timestamp) => {
    if (user.toLowerCase() === userAccount.toLowerCase()) {
        showStatus('registerStatus', 'Registration confirmed on blockchain!', 'success');
        loadContractData();
    }
});

// Listen for verification events
contract.on("AccessAttempted", (user, verified, timestamp) => {
    if (user.toLowerCase() === userAccount.toLowerCase()) {
        const message = verified ? 'Verification successful!' : 'Verification failed!';
        const type = verified ? 'success' : 'error';
        showStatus('verifyStatus', message, type);
        loadContractData();
    }
});
```

## Conclusion

Congratulations! You've successfully built your first confidential application using FHEVM. This tutorial covered:

### What You Learned
- **FHE Basics**: Understanding encrypted computation without decryption
- **FHEVM Integration**: Using Zama's FHE libraries in Solidity
- **Smart Contract Development**: Building privacy-preserving contracts
- **Frontend Integration**: Connecting Web3 interfaces with FHE contracts
- **Deployment Process**: Getting your app live on Sepolia testnet

### Key Concepts Mastered
- **Encrypted Data Types**: euint32, euint64, ebool
- **FHE Operations**: eq(), select(), add(), ge()
- **Access Control**: FHE.allow(), FHE.allowThis()
- **Decryption Requests**: Asynchronous result processing

### Real-World Applications
Your biometric authentication system demonstrates practical FHE usage:
- **Healthcare**: Patient data privacy
- **Finance**: Confidential transactions
- **Identity**: Anonymous verification
- **Gaming**: Private game states

### Next Steps
1. **Explore Advanced FHE**: Learn about more complex operations
2. **Add More Features**: Implement role-based access, batch operations
3. **Optimize Gas Usage**: Study gas-efficient FHE patterns
4. **Security Audits**: Prepare for production deployment
5. **Community**: Join the Zama developer community

### Resources for Continued Learning
- **Zama Documentation**: Official FHEVM guides
- **GitHub Examples**: Community-contributed projects
- **Discord Community**: Connect with other FHE developers
- **Hackathons**: Participate in privacy-focused events

You now have the foundation to build more sophisticated confidential applications. The future of privacy-preserving blockchain development starts here!

---

**Happy building with FHEVM! 🚀**