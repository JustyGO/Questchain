# Gaming Rewards Distribution Smart Contract

A Clarity smart contract for managing gaming rewards, player verification, achievements, and reward distribution on the Stacks blockchain.

## Overview

This smart contract enables game administrators to manage a reward system where players can earn and collect rewards based on their achievements and verification status. The contract implements a qualification system that requires players to be both verified and hold achievements before they can collect rewards.

## Features

- **Player Verification System**: Game master can verify/revoke player accounts
- **Achievement Tracking**: Track player achievements required for reward qualification
- **Reward Points Management**: Assign reward points to individual players
- **Batch Distribution**: Distribute rewards to multiple players simultaneously
- **Collection Controls**: Toggle reward distribution on/off
- **Comprehensive Status Checking**: Query player eligibility and reward status

## Constants

- `game-master`: The contract deployer (tx-sender) who has administrative privileges
- **Error Codes**:
  - `err-master-only (u100)`: Operation restricted to game master
  - `err-reward-taken (u101)`: Rewards already collected
  - `err-not-qualified (u102)`: Player not qualified to collect
  - `err-no-reward-pool (u103)`: No rewards assigned to player
  - `err-distribution-locked (u104)`: Distribution currently disabled
  - `err-invalid-player (u105)`: Invalid player principal
  - `err-invalid-reward (u106)`: Invalid reward amount

## Data Structures

### Data Variables
- `total-reward-pool`: Total available rewards (default: 5,000,000)
- `distribution-active`: Controls whether rewards can be collected

### Data Maps
- `player-rewards`: Maps players to their reward points
- `rewards-collected`: Tracks if player has collected rewards
- `achievement-holders`: Tracks achievement status
- `verified-players`: Tracks verified player accounts

## Public Functions

### Administrative Functions (Game Master Only)

#### `verify-player`
```clarity
(verify-player (player principal))
```
Verify a player account to make them eligible for rewards.

#### `revoke-verification`
```clarity
(revoke-verification (player principal))
```
Remove verification status from a player.

#### `grant-achievement`
```clarity
(grant-achievement (player principal) (has-achievement bool))
```
Grant or revoke achievement status for a player.

#### `set-reward-points`
```clarity
(set-reward-points (player principal) (points uint))
```
Assign reward points to a specific player. Points must be greater than 0 and within the reward pool limit.

#### `mass-distribute`
```clarity
(mass-distribute (players (list 200 principal)) (points (list 200 uint)))
```
Distribute rewards to multiple players at once. Lists must be equal length (max 200 players).

#### `toggle-distribution`
```clarity
(toggle-distribution)
```
Enable or disable reward collection globally.

### Player Functions

#### `collect-rewards`
```clarity
(collect-rewards)
```
Allows qualified players to collect their assigned rewards. Requirements:
- Distribution must be active
- Player must be verified
- Player must have achievement
- Rewards not previously collected
- Player must have assigned reward points

## Read-Only Functions

#### `get-player-rewards`
```clarity
(get-player-rewards (player principal))
```
Returns the reward points assigned to a player.

#### `has-collected`
```clarity
(has-collected (player principal))
```
Returns whether a player has collected their rewards.

#### `check-qualification`
```clarity
(check-qualification (player principal))
```
Returns whether a player meets qualification requirements (verified + achievement).

#### `get-distribution-status`
```clarity
(get-distribution-status)
```
Returns current distribution status (active/inactive).

#### `get-reward-pool`
```clarity
(get-reward-pool)
```
Returns total reward pool amount.

#### `get-player-status`
```clarity
(get-player-status (player principal))
```
Returns comprehensive player status including:
- `rewards`: Assigned reward points
- `collected`: Collection status
- `qualified`: Qualification status
- `verified`: Verification status
- `has-achievement`: Achievement status
- `can-collect`: Whether player can currently collect rewards

## Usage Flow

1. **Setup Phase** (Game Master):
   - Deploy contract
   - Verify player accounts using `verify-player`
   - Grant achievements using `grant-achievement`
   - Assign reward points using `set-reward-points` or `mass-distribute`

2. **Distribution Phase**:
   - Game master enables distribution using `toggle-distribution`
   - Qualified players call `collect-rewards` to claim their rewards

3. **Monitoring**:
   - Use read-only functions to check player status and eligibility
   - Use `get-player-status` for comprehensive status checks

## Security Features

- Only game master can perform administrative operations
- Players cannot collect rewards twice
- Qualification system prevents unauthorized collections
- Distribution can be disabled to pause reward collection
- Player validation prevents invalid addresses

## Example Usage

```clarity
;; Game master verifies a player
(contract-call? .gaming-rewards verify-player 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)

;; Grant achievement to player
(contract-call? .gaming-rewards grant-achievement 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM true)

;; Assign reward points
(contract-call? .gaming-rewards set-reward-points 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM u10000)

;; Enable distribution
(contract-call? .gaming-rewards toggle-distribution)

;; Player collects rewards
(contract-call? .gaming-rewards collect-rewards)

;; Check player status
(contract-call? .gaming-rewards get-player-status 'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```
