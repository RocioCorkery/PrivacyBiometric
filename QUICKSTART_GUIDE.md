# Hello FHEVM - Quick Start Guide

Get your first confidential application running in 15 minutes!

## Prerequisites Checklist

- [ ] Node.js (v16+) installed
- [ ] MetaMask browser extension
- [ ] Some Sepolia testnet ETH
- [ ] Basic Solidity knowledge

## 1. Project Setup (2 minutes)

```bash
# Clone and setup
git clone <your-repo-url>
cd hello-fhevm-tutorial
npm install

# Configure environment
cp .env.example .env
# Edit .env with your Sepolia RPC URL and private key
```

## 2. Deploy Contract (3 minutes)

```bash
# Compile contract
npx hardhat compile

# Deploy to Sepolia
npx hardhat run scripts/deploy.js --network sepolia
```

Copy the contract address from the output.

## 3. Configure Frontend (1 minute)

Update `app.js`:
```javascript
const CONTRACT_ADDRESS = "YOUR_DEPLOYED_CONTRACT_ADDRESS";
```

## 4. Test Your App (5 minutes)

1. Open `index.html` in your browser
2. Connect MetaMask (Sepolia network)
3. Register biometric with sample data:
   - Fingerprint: `1234567890123456789`
   - Face: `9876543210987654321`
   - Voice: `1357924680`
   - Iris: `2468135790`

4. Verify with the same data
5. Check results!

## 5. Understanding What Happened (4 minutes)

### Privacy Magic ✨
- Your biometric data was encrypted before reaching the blockchain
- Verification happened on encrypted data (never decrypted!)
- Only the final result was revealed

### FHE Operations Used
```solidity
// Convert to encrypted
euint64 encrypted = FHE.asEuint64(plainValue);

// Compare encrypted values
ebool match = FHE.eq(stored, submitted);

// Calculate score on encrypted data
euint32 score = FHE.select(match, points, zero);
```

## Next Steps

- Read the [full tutorial](HELLO_FHEVM_TUTORIAL.md) for deep understanding
- Experiment with different biometric values
- Add more features like access history
- Join the Zama community for advanced FHE techniques

## Need Help?

**Common Issues:**
- Contract address mismatch → Check deployment output
- Network error → Switch to Sepolia in MetaMask
- Gas issues → Get more test ETH from faucet

**Community:**
- Zama Discord for FHE questions
- GitHub issues for code problems

Congratulations! You've built your first confidential application! 🎉