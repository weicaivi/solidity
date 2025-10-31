# SimpleFitnessTracker

A compact on‑chain fitness tracker that teaches one powerful concept in Solidity: events. Users register profiles, log workouts, and trigger milestones that your frontend can react to in real time.

## Why Events?
Events don’t change contract state; they write logs that off‑chain systems can subscribe to. When Alice logs her 10th workout, the contract emits a signal. Your app can catch it to update the UI, unlock a badge, or store analytics—cheaply.

## Core Data Model
- UserProfile
  - name: string
  - weight: uint256 (kg)
  - isRegistered: bool

- WorkoutActivity
  - activityType: string (e.g., "Running")
  - duration: uint256 (seconds)
  - distance: uint256 (meters)
  - timestamp: uint256 (block timestamp)

## State
- userProfiles: mapping(address => UserProfile) public
- workoutHistory: mapping(address => WorkoutActivity[]) private
- totalWorkouts: mapping(address => uint256) public
- totalDistance: mapping(address => uint256) public

## Events
- UserRegistered(address indexed user, string name, uint256 timestamp)
- ProfileUpdated(address indexed user, uint256 newWeight, uint256 timestamp)
- WorkoutLogged(address indexed user, string activityType, uint256 duration, uint256 distance, uint256 timestamp)
- MilestoneAchieved(address indexed user, string milestone, uint256 timestamp)

Indexed parameters let you filter logs efficiently (e.g., show only one user’s activity). You can index up to three parameters per event.

## Access Control
- onlyRegistered: require the caller to be registered before using certain functions.

## Contract Walkthrough

### 1) registerUser(name, weight)
- Guard: must not already be registered.
- Action: writes UserProfile and sets isRegistered = true.
- Emit: UserRegistered(user, name, timestamp).

Frontend ideas:
- Show a welcome modal.
- Persist signup analytics off‑chain.
- Trigger a profile badge.

### 2) updateWeight(newWeight) onlyRegistered
- Read current weight from storage (not memory).
- If newWeight is at least 5% lower than previous weight:
  - Emit MilestoneAchieved("Weight Goal Reached").
- Update stored weight.
- Emit ProfileUpdated(user, newWeight, timestamp).

Reasoning:
- Using storage ensures updates persist on‑chain.
- The 5% rule filters out minor fluctuations.

### 3) logWorkout(activityType, duration, distance) onlyRegistered
- Create a WorkoutActivity in memory and push to workoutHistory (storage).
- Update totals:
  - totalWorkouts[user]++
  - totalDistance[user] += distance
- Emit WorkoutLogged(user, activityType, duration, distance, timestamp)
- Milestones:
  - If totalWorkouts == 10 → "10 Workouts Completed"
  - If totalWorkouts == 50 → "50 Workouts Completed"
  - If crossing 100,000 meters total (just crossed threshold) → "100K Total Distance"

Pattern:
- Build the activity object in memory (cheap).
- Persist via push into storage (durable).
- Emit events to drive UI, analytics, and rewards.

### 4) getUserWorkoutCount() view onlyRegistered
- Returns workoutHistory[user].length.

## Gas Notes
- Emitting events costs gas, but less than storing additional state.
- Use events for reactive UI and analytics; store only essential on‑chain data.


## Example Interface Hooks
- Listen for UserRegistered to show onboarding UI.
- Listen for WorkoutLogged to update charts and progress bars.
- Listen for MilestoneAchieved to mint a badge/NFT or unlock rewards.

## Skeleton Code
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract SimpleFitnessTracker {
    struct UserProfile {
        string name;
        uint256 weight; // kg
        bool isRegistered;
    }

    struct WorkoutActivity {
        string activityType;
        uint256 duration;  // seconds
        uint256 distance;  // meters
        uint256 timestamp;
    }

    mapping(address => UserProfile) public userProfiles;
    mapping(address => WorkoutActivity[]) private workoutHistory;
    mapping(address => uint256) public totalWorkouts;
    mapping(address => uint256) public totalDistance;

    event UserRegistered(address indexed userAddress, string name, uint256 timestamp);
    event ProfileUpdated(address indexed userAddress, uint256 newWeight, uint256 timestamp);
    event WorkoutLogged(
        address indexed userAddress,
        string activityType,
        uint256 duration,
        uint256 distance,
        uint256 timestamp
    );
    event MilestoneAchieved(address indexed userAddress, string milestone, uint256 timestamp);

    modifier onlyRegistered() {
        require(userProfiles[msg.sender].isRegistered, "User not registered");
        _;
    }

    function registerUser(string memory _name, uint256 _weight) public {
        require(!userProfiles[msg.sender].isRegistered, "User already registered");
        userProfiles[msg.sender] = UserProfile({ name: _name, weight: _weight, isRegistered: true });
        emit UserRegistered(msg.sender, _name, block.timestamp);
    }

    function updateWeight(uint256 _newWeight) public onlyRegistered {
        UserProfile storage profile = userProfiles[msg.sender];

        if (_newWeight < profile.weight && (profile.weight - _newWeight) * 100 / profile.weight >= 5) {
            emit MilestoneAchieved(msg.sender, "Weight Goal Reached", block.timestamp);
        }

        profile.weight = _newWeight;
        emit ProfileUpdated(msg.sender, _newWeight, block.timestamp);
    }

    function logWorkout(string memory _activityType, uint256 _duration, uint256 _distance) public onlyRegistered {
        WorkoutActivity memory newWorkout = WorkoutActivity({
            activityType: _activityType,
            duration: _duration,
            distance: _distance,
            timestamp: block.timestamp
        });

        workoutHistory[msg.sender].push(newWorkout);

        totalWorkouts[msg.sender] += 1;
        totalDistance[msg.sender] += _distance;

        emit WorkoutLogged(msg.sender, _activityType, _duration, _distance, block.timestamp);

        if (totalWorkouts[msg.sender] == 10) {
            emit MilestoneAchieved(msg.sender, "10 Workouts Completed", block.timestamp);
        } else if (totalWorkouts[msg.sender] == 50) {
            emit MilestoneAchieved(msg.sender, "50 Workouts Completed", block.timestamp);
        }

        if (totalDistance[msg.sender] >= 100000 && totalDistance[msg.sender] - _distance < 100000) {
            emit MilestoneAchieved(msg.sender, "100K Total Distance", block.timestamp);
        }
    }

    function getUserWorkoutCount() public view onlyRegistered returns (uint256) {
        return workoutHistory[msg.sender].length;
    }
}
```

## Implementation Notes
- Use memory for temporary structs; storage for persistent state.
- Keep event parameter order consistent and descriptive.
- Consider additional milestones (e.g., weekly streaks) or NFT mint hooks off-chain when events fire.
- Privacy: name and weight are public in this example; for privacy, consider emitting minimal public state and keeping sensitive data off-chain.

## Frontend Integration Tips
- Subscribe to events via your provider or SDK.
- Derive charts and dashboards from events or public getters.
- Store analytic aggregates off-chain to reduce state writes.
- Debounce UI reactions if multiple events fire in one transaction.
