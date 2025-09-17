# Hello FHEVM - Code Examples & Design Patterns

This guide provides practical code examples and proven patterns for building confidential applications with FHEVM.

## Table of Contents

1. [Basic FHE Operations](#basic-fhe-operations)
2. [Common Design Patterns](#common-design-patterns)
3. [Error Handling](#error-handling)
4. [Gas Optimization](#gas-optimization)
5. [Security Best Practices](#security-best-practices)
6. [Frontend Integration Patterns](#frontend-integration-patterns)

## Basic FHE Operations

### 1. Data Type Conversions

```solidity
// Converting plaintext to encrypted
function convertToEncrypted() external {
    uint32 plainValue = 42;
    euint32 encryptedValue = FHE.asEuint32(plainValue);

    // For different sizes
    uint64 bigPlainValue = 1234567890;
    euint64 bigEncryptedValue = FHE.asEuint64(bigPlainValue);

    // Boolean values
    bool plainBool = true;
    ebool encryptedBool = FHE.asEbool(plainBool);
}
```

### 2. Encrypted Comparisons

```solidity
// Pattern: Encrypted equality check
function checkEquality(uint64 input) external view returns (bool) {
    euint64 storedValue = userTemplates[msg.sender].data;
    euint64 inputEncrypted = FHE.asEuint64(input);

    ebool isEqual = FHE.eq(storedValue, inputEncrypted);

    // Convert to plaintext for return (use sparingly!)
    return FHE.decrypt(isEqual);
}

// Pattern: Greater than comparison
function checkThreshold(uint32 value, uint32 threshold) external pure returns (ebool) {
    euint32 encValue = FHE.asEuint32(value);
    euint32 encThreshold = FHE.asEuint32(threshold);

    return FHE.gt(encValue, encThreshold);
}

// Pattern: Range checking
function isInRange(uint32 value, uint32 min, uint32 max) external pure returns (ebool) {
    euint32 encValue = FHE.asEuint32(value);
    euint32 encMin = FHE.asEuint32(min);
    euint32 encMax = FHE.asEuint32(max);

    ebool aboveMin = FHE.ge(encValue, encMin);
    ebool belowMax = FHE.le(encValue, encMax);

    return FHE.and(aboveMin, belowMax);
}
```

### 3. Conditional Operations

```solidity
// Pattern: Conditional value selection
function selectValue(bool condition, uint32 valueA, uint32 valueB) external pure returns (euint32) {
    ebool encCondition = FHE.asEbool(condition);
    euint32 encValueA = FHE.asEuint32(valueA);
    euint32 encValueB = FHE.asEuint32(valueB);

    return FHE.select(encCondition, encValueA, encValueB);
}

// Pattern: Score calculation with conditions
function calculateScore(uint32[] memory factors, uint32[] memory weights) external pure returns (euint32) {
    require(factors.length == weights.length, "Arrays must be same length");

    euint32 totalScore = FHE.asEuint32(0);

    for (uint i = 0; i < factors.length; i++) {
        euint32 factor = FHE.asEuint32(factors[i]);
        euint32 weight = FHE.asEuint32(weights[i]);
        euint32 weighted = FHE.mul(factor, weight);
        totalScore = FHE.add(totalScore, weighted);
    }

    return totalScore;
}
```

### 4. Arithmetic Operations

```solidity
// Pattern: Safe arithmetic with bounds checking
function safeAdd(uint32 a, uint32 b, uint32 maxValue) external pure returns (euint32) {
    euint32 encA = FHE.asEuint32(a);
    euint32 encB = FHE.asEuint32(b);
    euint32 encMax = FHE.asEuint32(maxValue);

    euint32 sum = FHE.add(encA, encB);

    // Check if sum exceeds maximum
    ebool exceedsMax = FHE.gt(sum, encMax);

    // Return max value if exceeded, otherwise return sum
    return FHE.select(exceedsMax, encMax, sum);
}

// Pattern: Percentage calculation
function calculatePercentage(uint32 value, uint32 total) external pure returns (euint32) {
    euint32 encValue = FHE.asEuint32(value);
    euint32 encTotal = FHE.asEuint32(total);
    euint32 encHundred = FHE.asEuint32(100);

    euint32 scaled = FHE.mul(encValue, encHundred);
    return FHE.div(scaled, encTotal);
}
```

## Common Design Patterns

### 1. Encrypted Storage Pattern

```solidity
contract EncryptedStorage {
    struct EncryptedData {
        euint64 sensitiveValue;
        euint32 confidenceLevel;
        bool isActive;
        uint256 timestamp;
    }

    mapping(address => EncryptedData) private userStorage;
    mapping(address => bool) public authorizedUsers;

    modifier onlyAuthorized() {
        require(authorizedUsers[msg.sender], "Not authorized");
        _;
    }

    // Pattern: Secure data storage with access control
    function storeData(uint64 value, uint32 confidence) external {
        euint64 encValue = FHE.asEuint64(value);
        euint32 encConfidence = FHE.asEuint32(confidence);

        userStorage[msg.sender] = EncryptedData({
            sensitiveValue: encValue,
            confidenceLevel: encConfidence,
            isActive: true,
            timestamp: block.timestamp
        });

        // Set access permissions
        FHE.allowThis(encValue);
        FHE.allowThis(encConfidence);
        FHE.allow(encValue, msg.sender);
        FHE.allow(encConfidence, msg.sender);
    }

    // Pattern: Encrypted data retrieval with authorization
    function getData(address user) external view onlyAuthorized returns (bool, uint256) {
        EncryptedData storage data = userStorage[user];
        return (data.isActive, data.timestamp);
        // Note: Encrypted values require special handling for return
    }
}
```

### 2. Multi-Factor Verification Pattern

```solidity
contract MultiFactor {
    struct VerificationFactors {
        euint64 factor1;
        euint64 factor2;
        euint32 factor3;
        euint32 factor4;
    }

    mapping(address => VerificationFactors) private userFactors;

    // Pattern: Multi-factor verification with weighted scoring
    function verifyMultiFactor(
        uint64 f1, uint64 f2, uint32 f3, uint32 f4
    ) external returns (bool) {
        VerificationFactors storage stored = userFactors[msg.sender];

        // Convert inputs to encrypted form
        euint64 input1 = FHE.asEuint64(f1);
        euint64 input2 = FHE.asEuint64(f2);
        euint32 input3 = FHE.asEuint32(f3);
        euint32 input4 = FHE.asEuint32(f4);

        // Perform encrypted comparisons
        ebool match1 = FHE.eq(stored.factor1, input1);
        ebool match2 = FHE.eq(stored.factor2, input2);
        ebool match3 = FHE.eq(stored.factor3, input3);
        ebool match4 = FHE.eq(stored.factor4, input4);

        // Calculate weighted score (different weights for different factors)
        euint32 score = FHE.select(match1, FHE.asEuint32(30), FHE.asEuint32(0));
        score = FHE.add(score, FHE.select(match2, FHE.asEuint32(30), FHE.asEuint32(0)));
        score = FHE.add(score, FHE.select(match3, FHE.asEuint32(25), FHE.asEuint32(0)));
        score = FHE.add(score, FHE.select(match4, FHE.asEuint32(15), FHE.asEuint32(0)));

        // Require 80% confidence (80 out of 100)
        ebool passed = FHE.ge(score, FHE.asEuint32(80));

        // Use async decryption for final result
        bytes32[] memory cts = new bytes32[](1);
        cts[0] = FHE.toBytes32(passed);
        FHE.requestDecryption(cts, this.processVerificationResult.selector);

        return false; // Placeholder, real result comes via callback
    }

    function processVerificationResult(
        uint256 requestId,
        bool result,
        bytes memory signatures
    ) external {
        bytes memory decryptedResult = abi.encodePacked(result);
        FHE.checkSignatures(requestId, decryptedResult, signatures);

        // Handle verification result
        emit VerificationCompleted(msg.sender, result, block.timestamp);
    }

    event VerificationCompleted(address indexed user, bool result, uint256 timestamp);
}
```

### 3. Threshold-Based Access Pattern

```solidity
contract ThresholdAccess {
    struct AccessControl {
        euint32 userLevel;
        euint32 requiredLevel;
        bool isActive;
    }

    mapping(address => AccessControl) private accessControls;

    // Pattern: Threshold-based access with encrypted levels
    function checkAccess(address user, uint32 resourceLevel) external view returns (bool) {
        AccessControl storage control = accessControls[user];
        require(control.isActive, "User not active");

        euint32 required = FHE.asEuint32(resourceLevel);
        ebool hasAccess = FHE.ge(control.userLevel, required);

        // In practice, you'd use async decryption for this
        return FHE.decrypt(hasAccess);
    }

    // Pattern: Upgrade user level with validation
    function upgradeUserLevel(uint32 newLevel) external {
        AccessControl storage control = accessControls[msg.sender];
        euint32 encNewLevel = FHE.asEuint32(newLevel);

        // Ensure new level is higher than current
        ebool isUpgrade = FHE.gt(encNewLevel, control.userLevel);

        // Only update if it's an actual upgrade
        control.userLevel = FHE.select(
            isUpgrade,
            encNewLevel,
            control.userLevel
        );

        FHE.allowThis(control.userLevel);
        FHE.allow(control.userLevel, msg.sender);
    }
}
```

## Error Handling

### 1. Input Validation Patterns

```solidity
contract InputValidation {
    // Pattern: Validate encrypted inputs within range
    function validateRange(uint32 value, uint32 min, uint32 max) internal pure returns (bool) {
        require(value >= min && value <= max, "Value out of range");
        return true;
    }

    // Pattern: Comprehensive input validation
    function processSecureInput(
        uint64 sensitiveData,
        uint32 confidence,
        bytes32 salt
    ) external {
        // Validate ranges before encryption
        require(sensitiveData > 0, "Sensitive data cannot be zero");
        require(confidence <= 100, "Confidence cannot exceed 100%");
        require(salt != bytes32(0), "Salt cannot be empty");

        // Additional business logic validation
        validateRange(confidence, 1, 100);

        // Proceed with encryption only after validation
        euint64 encData = FHE.asEuint64(sensitiveData);
        euint32 encConfidence = FHE.asEuint32(confidence);

        // Store or process...
    }
}
```

### 2. Graceful Failure Patterns

```solidity
contract GracefulFailure {
    event OperationFailed(address indexed user, string reason, uint256 timestamp);

    // Pattern: Safe operation with fallback
    function safeOperation(uint64 input) external returns (bool success) {
        try this._internalOperation(input) {
            return true;
        } catch Error(string memory reason) {
            emit OperationFailed(msg.sender, reason, block.timestamp);
            return false;
        } catch {
            emit OperationFailed(msg.sender, "Unknown error", block.timestamp);
            return false;
        }
    }

    function _internalOperation(uint64 input) external {
        // Potentially failing operation
        require(input > 0, "Input must be positive");

        euint64 encInput = FHE.asEuint64(input);
        // Process encrypted input...
    }
}
```

## Gas Optimization

### 1. Efficient FHE Operations

```solidity
contract GasOptimized {
    // Pattern: Batch operations to reduce gas costs
    function batchCompare(
        uint64[] memory stored,
        uint64[] memory inputs
    ) external view returns (uint32) {
        require(stored.length == inputs.length, "Arrays must match");

        uint32 matches = 0;

        // Process in batches to optimize gas
        for (uint i = 0; i < stored.length; i++) {
            euint64 encStored = FHE.asEuint64(stored[i]);
            euint64 encInput = FHE.asEuint64(inputs[i]);

            ebool isMatch = FHE.eq(encStored, encInput);

            // Minimize decryption operations
            if (FHE.decrypt(isMatch)) {
                matches++;
            }
        }

        return matches;
    }

    // Pattern: Minimize storage operations
    struct OptimizedStorage {
        euint64 data1;
        euint64 data2;
        euint32 data3;
        // Pack related data together
        bool isActive;
        uint32 timestamp;
    }

    mapping(address => OptimizedStorage) private optimizedData;

    function storeOptimized(uint64 d1, uint64 d2, uint32 d3) external {
        OptimizedStorage storage data = optimizedData[msg.sender];

        // Batch encrypt operations
        data.data1 = FHE.asEuint64(d1);
        data.data2 = FHE.asEuint64(d2);
        data.data3 = FHE.asEuint32(d3);

        // Set all permissions at once
        FHE.allowThis(data.data1);
        FHE.allowThis(data.data2);
        FHE.allowThis(data.data3);

        data.isActive = true;
        data.timestamp = uint32(block.timestamp);
    }
}
```

### 2. Smart Decryption Patterns

```solidity
contract SmartDecryption {
    // Pattern: Minimize decryption requests
    function efficientVerification(uint64 input) external {
        euint64 stored = getUserData(msg.sender);
        euint64 encInput = FHE.asEuint64(input);

        ebool isMatch = FHE.eq(stored, encInput);

        // Only decrypt if necessary for business logic
        bytes32[] memory cts = new bytes32[](1);
        cts[0] = FHE.toBytes32(isMatch);
        FHE.requestDecryption(cts, this.handleResult.selector);
    }

    // Pattern: Batch decryption requests
    function batchDecryption(address[] memory users) external {
        bytes32[] memory cts = new bytes32[](users.length);

        for (uint i = 0; i < users.length; i++) {
            euint64 userData = getUserData(users[i]);
            euint64 threshold = FHE.asEuint64(1000);
            ebool meetsThreshold = FHE.ge(userData, threshold);
            cts[i] = FHE.toBytes32(meetsThreshold);
        }

        // Single decryption request for all users
        FHE.requestDecryption(cts, this.handleBatchResults.selector);
    }

    function getUserData(address user) internal view returns (euint64) {
        // Implementation details...
        return FHE.asEuint64(0); // Placeholder
    }

    function handleResult(uint256 requestId, bool result, bytes memory signatures) external {
        // Handle single result
    }

    function handleBatchResults(uint256 requestId, bool[] memory results, bytes memory signatures) external {
        // Handle multiple results
    }
}
```

## Security Best Practices

### 1. Access Control Patterns

```solidity
contract SecureAccess {
    address public owner;
    mapping(address => uint256) public userLevels;
    mapping(bytes32 => bool) public validSalts;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier onlyAuthorized(uint256 requiredLevel) {
        require(userLevels[msg.sender] >= requiredLevel, "Insufficient privileges");
        _;
    }

    // Pattern: Secure data access with multiple checks
    function secureDataAccess(
        uint64 sensitiveInput,
        bytes32 salt
    ) external onlyAuthorized(2) {
        require(validSalts[salt], "Invalid salt");
        require(sensitiveInput > 0, "Invalid input");

        // Additional security checks
        require(block.timestamp > lastAccess[msg.sender] + 1 minutes, "Rate limited");

        euint64 encInput = FHE.asEuint64(sensitiveInput);

        // Process securely...

        lastAccess[msg.sender] = block.timestamp;
    }

    mapping(address => uint256) private lastAccess;

    // Pattern: Secure salt management
    function registerSalt(bytes32 salt) external onlyOwner {
        require(salt != bytes32(0), "Salt cannot be empty");
        require(!validSalts[salt], "Salt already exists");

        validSalts[salt] = true;
    }
}
```

### 2. Data Integrity Patterns

```solidity
contract DataIntegrity {
    // Pattern: Checksums for encrypted data
    struct SecureData {
        euint64 data;
        bytes32 checksum;
        uint256 timestamp;
    }

    mapping(address => SecureData) private userData;

    function storeWithIntegrity(uint64 value, bytes32 providedChecksum) external {
        // Verify checksum before storing
        bytes32 calculatedChecksum = keccak256(abi.encodePacked(
            value,
            msg.sender,
            block.timestamp
        ));

        require(calculatedChecksum == providedChecksum, "Checksum mismatch");

        userData[msg.sender] = SecureData({
            data: FHE.asEuint64(value),
            checksum: calculatedChecksum,
            timestamp: block.timestamp
        });

        FHE.allowThis(userData[msg.sender].data);
        FHE.allow(userData[msg.sender].data, msg.sender);
    }

    // Pattern: Verify data integrity on retrieval
    function verifyIntegrity(address user) external view returns (bool) {
        SecureData storage data = userData[user];

        // Verify timestamp is reasonable
        require(data.timestamp > 0, "No data found");
        require(block.timestamp - data.timestamp < 365 days, "Data too old");

        return true; // Additional integrity checks...
    }
}
```

## Frontend Integration Patterns

### 1. React Hook Pattern

```javascript
// Custom hook for FHE contract interaction
import { useState, useEffect } from 'react';
import { ethers } from 'ethers';

export function useFHEContract(contractAddress, abi) {
    const [contract, setContract] = useState(null);
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        initializeContract();
    }, [contractAddress]);

    const initializeContract = async () => {
        try {
            setLoading(true);
            setError(null);

            if (!window.ethereum) {
                throw new Error('MetaMask not found');
            }

            const provider = new ethers.BrowserProvider(window.ethereum);
            const signer = await provider.getSigner();
            const contractInstance = new ethers.Contract(contractAddress, abi, signer);

            setContract(contractInstance);
        } catch (err) {
            setError(err.message);
        } finally {
            setLoading(false);
        }
    };

    const callFunction = async (functionName, args = [], options = {}) => {
        try {
            setLoading(true);
            setError(null);

            if (!contract) {
                throw new Error('Contract not initialized');
            }

            const tx = await contract[functionName](...args, options);
            const receipt = await tx.wait();

            return { tx, receipt };
        } catch (err) {
            setError(err.message);
            throw err;
        } finally {
            setLoading(false);
        }
    };

    return {
        contract,
        loading,
        error,
        callFunction,
        reinitialize: initializeContract
    };
}
```

### 2. Error Handling Component

```javascript
// ErrorBoundary for FHE applications
import React from 'react';

class FHEErrorBoundary extends React.Component {
    constructor(props) {
        super(props);
        this.state = { hasError: false, error: null };
    }

    static getDerivedStateFromError(error) {
        return { hasError: true, error };
    }

    componentDidCatch(error, errorInfo) {
        console.error('FHE Application Error:', error, errorInfo);

        // Log specific FHE-related errors
        if (error.message.includes('FHE')) {
            console.error('FHE-specific error detected');
        }
    }

    render() {
        if (this.state.hasError) {
            return (
                <div className="error-container">
                    <h2>Something went wrong with the confidential application</h2>
                    <details>
                        <summary>Error Details</summary>
                        <pre>{this.state.error.message}</pre>
                    </details>
                    <button onClick={() => this.setState({ hasError: false, error: null })}>
                        Try Again
                    </button>
                </div>
            );
        }

        return this.props.children;
    }
}

export default FHEErrorBoundary;
```

### 3. Status Management Pattern

```javascript
// Status management for FHE operations
export const FHEStatus = {
    IDLE: 'idle',
    CONNECTING: 'connecting',
    ENCRYPTING: 'encrypting',
    SUBMITTING: 'submitting',
    PROCESSING: 'processing',
    DECRYPTING: 'decrypting',
    SUCCESS: 'success',
    ERROR: 'error'
};

export function useFHEStatus() {
    const [status, setStatus] = useState(FHEStatus.IDLE);
    const [message, setMessage] = useState('');

    const updateStatus = (newStatus, newMessage = '') => {
        setStatus(newStatus);
        setMessage(newMessage);
    };

    const resetStatus = () => {
        setStatus(FHEStatus.IDLE);
        setMessage('');
    };

    return {
        status,
        message,
        updateStatus,
        resetStatus,
        isLoading: [
            FHEStatus.CONNECTING,
            FHEStatus.ENCRYPTING,
            FHEStatus.SUBMITTING,
            FHEStatus.PROCESSING,
            FHEStatus.DECRYPTING
        ].includes(status)
    };
}
```

These patterns provide a solid foundation for building robust, secure, and user-friendly confidential applications with FHEVM. Use them as starting points and adapt them to your specific use cases!