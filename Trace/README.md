# ChainTrace

> Decentralized Supply Chain Tracking on Stacks Blockchain

ChainTrace is a blockchain-based supply chain tracker that leverages the security of Bitcoin through the Stacks blockchain. It enables transparent, immutable tracking of products from manufacture to delivery, with built-in verification mechanisms.

## Features

- **Product Registration**: Manufacturers can register products with unique identifiers and QR codes
- **Transfer Tracking**: Track product transfers between parties with location and timestamp data
- **Delivery Confirmation**: Recipients can confirm product delivery on-chain
- **Third-Party Verification**: Authorized verifiers can validate product authenticity
- **Complete History**: Immutable audit trail of all product events
- **QR Code Integration**: Link physical products to blockchain records

## Smart Contract Architecture

### Core Functions

#### Registration
- `register-product`: Create a new product on-chain with QR code and metadata
- `add-verifier`: Owner can authorize third-party verifiers
- `remove-verifier`: Owner can revoke verifier authorization

#### Tracking
- `transfer-product`: Current holder transfers product to new holder
- `confirm-delivery`: Recipient confirms product delivery
- `verify-product`: Authorized verifier validates product authenticity

#### Queries
- `get-product`: Retrieve product details
- `get-product-event`: Fetch specific event in product history
- `get-event-count`: Get total number of events for a product
- `verify-qr-code`: Validate QR code matches product record

### Product Status Flow

```
MANUFACTURED → IN-TRANSIT → DELIVERED → VERIFIED
```

## Getting Started

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) installed
- Stacks wallet for testing

### Installation

```bash
# Clone the repository
git clone https://github.com/onyinye560/ChainTrace.git
cd chaintrace

# Initialize Clarinet project (if not already done)
clarinet integrate

# Check contract
clarinet check

### Deployment

#### Testnet
```bash
clarinet deploy --testnet
```

#### Mainnet
```bash
clarinet deploy --mainnet
```

## Usage Examples

### Register a Product

```clarity
(contract-call? .chaintrace register-product 
  "Organic Coffee Beans - Batch #1234" 
  "QR_ABC123XYZ" 
  "Factory A, Colombia")
```

### Transfer Product

```clarity
(contract-call? .chaintrace transfer-product 
  u1 
  'ST2JHG361ZXG51QTKY2NQCVBPPRRE2KZB1HR05NNC
  "Warehouse B, Miami"
  "Transferred to distributor")
```

### Confirm Delivery

```clarity
(contract-call? .chaintrace confirm-delivery 
  u1 
  "Retail Store, New York"
  "Product received in good condition")
```

### Query Product

```clarity
(contract-call? .chaintrace get-product u1)
```

## Use Cases

- **Food & Beverage**: Track organic certifications and origin
- **Pharmaceuticals**: Verify authenticity and prevent counterfeits
- **Electronics**: Warranty tracking and ownership history
- **Luxury Goods**: Prove authenticity and ownership chain
- **Agriculture**: Farm-to-table traceability

## Error Codes

- `u100`: Owner-only operation
- `u101`: Product not found
- `u102`: Product already exists
- `u103`: Unauthorized action
- `u104`: Invalid status

## Project Structure

```
chaintrace/
├── contracts/
│   └── chaintrace.clar
├── tests/
│   └── chaintrace_test.ts
├── settings/
│   └── Devnet.toml
├── Clarinet.toml
└── README.md
```

## Roadmap

- [ ] Multi-signature transfers for high-value items
- [ ] Integration with IoT sensors for automated updates
- [ ] NFT-based product certificates
- [ ] Cross-chain bridge for Ethereum/Polygon
- [ ] Mobile app with QR scanner
- [ ] Analytics dashboard for supply chain insights