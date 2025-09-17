// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { FHE, euint32, euint64, ebool } from "@fhevm/solidity/lib/FHE.sol";
import { SepoliaConfig } from "@fhevm/solidity/config/ZamaConfig.sol";

contract PrivacyBiometric is SepoliaConfig {

    address public owner;
    uint256 public totalUsers;

    struct BiometricTemplate {
        euint64 fingerprintHash;
        euint64 faceTemplateHash;
        euint32 voicePrintHash;
        euint32 irisPattern;
        bool isActive;
        uint256 timestamp;
        uint256 accessCount;
    }

    struct AccessAttempt {
        euint64 submittedFingerprint;
        euint64 submittedFaceTemplate;
        euint32 submittedVoicePrint;
        euint32 submittedIris;
        bool verified;
        uint256 timestamp;
        uint256 confidenceScore;
    }

    struct BiometricScore {
        euint32 fingerprintMatch;
        euint32 faceMatch;
        euint32 voiceMatch;
        euint32 irisMatch;
        euint32 overallScore;
    }

    mapping(address => BiometricTemplate) public userTemplates;
    mapping(address => AccessAttempt[]) public accessHistory;
    mapping(address => BiometricScore) public lastVerificationScore;
    mapping(address => bool) public authorizedUsers;

    address[] public registeredUsers;

    event BiometricRegistered(address indexed user, uint256 timestamp);
    event AccessAttempted(address indexed user, bool verified, uint256 timestamp);
    event BiometricUpdated(address indexed user, uint256 timestamp);
    event UserAuthorized(address indexed user, address indexed authorizer);
    event UserDeauthorized(address indexed user, address indexed deauthorizer);
    event BiometricVerificationCompleted(address indexed user, uint256 confidenceScore);

    modifier onlyOwner() {
        require(msg.sender == owner, "Not authorized");
        _;
    }

    modifier onlyAuthorized() {
        require(authorizedUsers[msg.sender] || msg.sender == owner, "Not authorized user");
        _;
    }

    modifier onlyRegisteredUser() {
        require(userTemplates[msg.sender].isActive, "User not registered");
        _;
    }

    constructor() {
        owner = msg.sender;
        authorizedUsers[owner] = true;
        totalUsers = 0;
    }

    function registerBiometric(
        uint64 _fingerprintHash,
        uint64 _faceTemplateHash,
        uint32 _voicePrintHash,
        uint32 _irisPattern
    ) external {
        require(!userTemplates[msg.sender].isActive, "User already registered");

        euint64 encryptedFingerprint = FHE.asEuint64(_fingerprintHash);
        euint64 encryptedFaceTemplate = FHE.asEuint64(_faceTemplateHash);
        euint32 encryptedVoicePrint = FHE.asEuint32(_voicePrintHash);
        euint32 encryptedIris = FHE.asEuint32(_irisPattern);

        userTemplates[msg.sender] = BiometricTemplate({
            fingerprintHash: encryptedFingerprint,
            faceTemplateHash: encryptedFaceTemplate,
            voicePrintHash: encryptedVoicePrint,
            irisPattern: encryptedIris,
            isActive: true,
            timestamp: block.timestamp,
            accessCount: 0
        });

        registeredUsers.push(msg.sender);
        totalUsers++;

        FHE.allowThis(encryptedFingerprint);
        FHE.allowThis(encryptedFaceTemplate);
        FHE.allowThis(encryptedVoicePrint);
        FHE.allowThis(encryptedIris);

        FHE.allow(encryptedFingerprint, msg.sender);
        FHE.allow(encryptedFaceTemplate, msg.sender);
        FHE.allow(encryptedVoicePrint, msg.sender);
        FHE.allow(encryptedIris, msg.sender);

        emit BiometricRegistered(msg.sender, block.timestamp);
    }

    function verifyBiometric(
        uint64 _fingerprintHash,
        uint64 _faceTemplateHash,
        uint32 _voicePrintHash,
        uint32 _irisPattern
    ) external onlyRegisteredUser returns (bool) {
        BiometricTemplate storage template = userTemplates[msg.sender];

        euint64 submittedFingerprint = FHE.asEuint64(_fingerprintHash);
        euint64 submittedFaceTemplate = FHE.asEuint64(_faceTemplateHash);
        euint32 submittedVoicePrint = FHE.asEuint32(_voicePrintHash);
        euint32 submittedIris = FHE.asEuint32(_irisPattern);

        ebool fingerprintMatch = FHE.eq(template.fingerprintHash, submittedFingerprint);
        ebool faceMatch = FHE.eq(template.faceTemplateHash, submittedFaceTemplate);
        ebool voiceMatch = FHE.eq(template.voicePrintHash, submittedVoicePrint);
        ebool irisMatch = FHE.eq(template.irisPattern, submittedIris);

        euint32 matchScore = FHE.select(fingerprintMatch, FHE.asEuint32(25), FHE.asEuint32(0));
        matchScore = FHE.add(matchScore, FHE.select(faceMatch, FHE.asEuint32(25), FHE.asEuint32(0)));
        matchScore = FHE.add(matchScore, FHE.select(voiceMatch, FHE.asEuint32(25), FHE.asEuint32(0)));
        matchScore = FHE.add(matchScore, FHE.select(irisMatch, FHE.asEuint32(25), FHE.asEuint32(0)));

        ebool isVerified = FHE.ge(matchScore, FHE.asEuint32(75));

        lastVerificationScore[msg.sender] = BiometricScore({
            fingerprintMatch: FHE.select(fingerprintMatch, FHE.asEuint32(100), FHE.asEuint32(0)),
            faceMatch: FHE.select(faceMatch, FHE.asEuint32(100), FHE.asEuint32(0)),
            voiceMatch: FHE.select(voiceMatch, FHE.asEuint32(100), FHE.asEuint32(0)),
            irisMatch: FHE.select(irisMatch, FHE.asEuint32(100), FHE.asEuint32(0)),
            overallScore: matchScore
        });

        accessHistory[msg.sender].push(AccessAttempt({
            submittedFingerprint: submittedFingerprint,
            submittedFaceTemplate: submittedFaceTemplate,
            submittedVoicePrint: submittedVoicePrint,
            submittedIris: submittedIris,
            verified: false,
            timestamp: block.timestamp,
            confidenceScore: 0
        }));

        template.accessCount++;

        FHE.allowThis(submittedFingerprint);
        FHE.allowThis(submittedFaceTemplate);
        FHE.allowThis(submittedVoicePrint);
        FHE.allowThis(submittedIris);
        FHE.allowThis(matchScore);

        FHE.allow(matchScore, msg.sender);

        bytes32[] memory cts = new bytes32[](1);
        cts[0] = FHE.toBytes32(isVerified);
        FHE.requestDecryption(cts, this.processVerificationResult.selector);

        return false;
    }

    function processVerificationResult(
        uint256 requestId,
        bool verificationResult,
        bytes memory signatures
    ) external {
        bytes memory decryptedResult = abi.encodePacked(verificationResult);
        FHE.checkSignatures(requestId, decryptedResult, signatures);

        uint256 accessIndex = accessHistory[msg.sender].length - 1;
        accessHistory[msg.sender][accessIndex].verified = verificationResult;

        if (verificationResult) {
            accessHistory[msg.sender][accessIndex].confidenceScore = 95;
            emit BiometricVerificationCompleted(msg.sender, 95);
        } else {
            accessHistory[msg.sender][accessIndex].confidenceScore = 15;
            emit BiometricVerificationCompleted(msg.sender, 15);
        }

        emit AccessAttempted(msg.sender, verificationResult, block.timestamp);
    }

    function updateBiometric(
        uint64 _fingerprintHash,
        uint64 _faceTemplateHash,
        uint32 _voicePrintHash,
        uint32 _irisPattern
    ) external onlyRegisteredUser {
        BiometricTemplate storage template = userTemplates[msg.sender];

        template.fingerprintHash = FHE.asEuint64(_fingerprintHash);
        template.faceTemplateHash = FHE.asEuint64(_faceTemplateHash);
        template.voicePrintHash = FHE.asEuint32(_voicePrintHash);
        template.irisPattern = FHE.asEuint32(_irisPattern);
        template.timestamp = block.timestamp;

        FHE.allowThis(template.fingerprintHash);
        FHE.allowThis(template.faceTemplateHash);
        FHE.allowThis(template.voicePrintHash);
        FHE.allowThis(template.irisPattern);

        FHE.allow(template.fingerprintHash, msg.sender);
        FHE.allow(template.faceTemplateHash, msg.sender);
        FHE.allow(template.voicePrintHash, msg.sender);
        FHE.allow(template.irisPattern, msg.sender);

        emit BiometricUpdated(msg.sender, block.timestamp);
    }

    function deactivateBiometric() external onlyRegisteredUser {
        userTemplates[msg.sender].isActive = false;
    }

    function authorizeUser(address _user) external onlyOwner {
        require(_user != address(0), "Invalid address");
        authorizedUsers[_user] = true;
        emit UserAuthorized(_user, msg.sender);
    }

    function deauthorizeUser(address _user) external onlyOwner {
        require(_user != owner, "Cannot deauthorize owner");
        authorizedUsers[_user] = false;
        emit UserDeauthorized(_user, msg.sender);
    }

    function getUserBiometricStatus(address _user) external view returns (
        bool isActive,
        uint256 timestamp,
        uint256 accessCount
    ) {
        BiometricTemplate storage template = userTemplates[_user];
        return (
            template.isActive,
            template.timestamp,
            template.accessCount
        );
    }

    function getAccessHistoryLength(address _user) external view returns (uint256) {
        return accessHistory[_user].length;
    }

    function getAccessAttempt(address _user, uint256 _index) external view returns (
        bool verified,
        uint256 timestamp,
        uint256 confidenceScore
    ) {
        require(_index < accessHistory[_user].length, "Invalid index");
        AccessAttempt storage attempt = accessHistory[_user][_index];
        return (
            attempt.verified,
            attempt.timestamp,
            attempt.confidenceScore
        );
    }

    function getRegisteredUsersCount() external view returns (uint256) {
        return totalUsers;
    }

    function getAllRegisteredUsers() external view onlyAuthorized returns (address[] memory) {
        return registeredUsers;
    }

    function isUserAuthorized(address _user) external view returns (bool) {
        return authorizedUsers[_user];
    }

    function generateSecureBiometricHash(
        uint64 _rawBiometric,
        uint32 _salt
    ) external view returns (uint64) {
        bytes32 hash = keccak256(abi.encodePacked(_rawBiometric, _salt, block.timestamp));
        return uint64(uint256(hash) >> 192);
    }

    function emergencyDeactivateAll() external onlyOwner {
        for (uint256 i = 0; i < registeredUsers.length; i++) {
            userTemplates[registeredUsers[i]].isActive = false;
        }
    }

    function getContractStats() external view onlyAuthorized returns (
        uint256 _totalUsers,
        uint256 _totalAccessAttempts,
        uint256 _activeUsers
    ) {
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
}