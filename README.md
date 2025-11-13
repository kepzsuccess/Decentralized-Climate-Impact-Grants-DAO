# Decentralized Climate Impact Grants DAO
A decentralized autonomous organization for funding climate innovation projects through community voting and escrowed funds.

## 🎯 Overview

The Climate Grants DAO enables communities to collectively fund eco-innovation proposals. Members stake STX to join, creators submit funding proposals, and the community votes to approve or reject projects. All funds are held in escrow during voting periods.

## ✨ Features

- 🏛️ **Membership System**: Stake STX to become a voting member
- 📝 **Proposal Creation**: Submit climate projects for funding
- 🗳️ **Democratic Voting**: Community decides which projects get funded
- 🔒 **Escrow Protection**: Funds held securely during voting
- ⚡ **Automatic Distribution**: Smart contract handles payouts
- 🛡️ **Governance Controls**: Owner-managed parameters

## 🚀 Getting Started

### Join the DAO
```clarity
(contract-call? .climate-grants-dao join-dao u500000)
```
*Minimum stake: 0.5 STX*

### Create a Proposal
```clarity
(contract-call? .climate-grants-dao create-proposal 
  "Solar School Initiative" 
  "Install solar panels in 10 rural schools to provide clean energy"
  u5000000 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)
```

### Vote on Proposals
```clarity
;; Vote YES
(contract-call? .climate-grants-dao vote-on-proposal u1 true)

;; Vote NO
(contract-call? .climate-grants-dao vote-on-proposal u1 false)
```

### Finalize Proposals
```clarity
(contract-call? .climate-grants-dao finalize-proposal u1)
```

## 📊 Read Functions

```clarity
;; Get proposal details
(contract-call? .climate-grants-dao get-proposal u1)

;; Check voting record
(contract-call? .climate-grants-dao get-voter-record u1 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; View member stake
(contract-call? .climate-grants-dao get-member-stake 'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7)

;; Check if voting is open
(contract-call? .climate-grants-dao is-voting-open u1)
```

## 🔄 Process Flow

1. **🎫 Join**: Stake STX to become a DAO member
2. **📤 Propose**: Submit climate project with funding request
3. **🗳️ Vote**: Members vote during 144-block period (~24 hours)
4. **✅ Finalize**: After voting ends, trigger fund distribution
5. **💰 Distribute**: 
   - **Approved**: Funds go to project recipient
   - **Rejected**: Funds return to proposal creator

## ⚙️ Default Settings

- **Minimum Stake**: 0.5 STX
- **Minimum Proposal**: 1 STX
- **Voting Duration**: 144 blocks (~24 hours)
- **Quorum Threshold**: 3 voters minimum

## 🛠️ Owner Functions

```clarity
;; Update voting duration
(contract-call? .climate-grants-dao update-voting-duration u288)

;; Change minimum proposal amount
(contract-call? .climate-grants-dao update-min-proposal-amount u2000000)

;; Adjust quorum threshold
(contract-call? .climate-grants-dao update-quorum-threshold u5)
```

## 📈 Proposal Status

- `"active"` - Currently accepting votes
- `"approved"` - Passed vote, funds distributed to recipient
- `"rejected"` - Failed vote, funds returned to creator

## 🌱 Climate Impact

Every approved proposal contributes to global climate action through:
- 🌞 Renewable energy projects
- 🌳 Reforestation initiatives  
- ♻️ Waste reduction programs
- 🚲 Sustainable transportation
- 💡 Green technology innovation

Join the movement and help fund the climate solutions of tomorrow! 🌍💚
```
