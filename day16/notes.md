# Modular Player Profile System with PluginStore

A practical pattern for Web3 games: keep a lightweight core player profile on-chain, and attach optional feature modules (“plugins”) for achievements, weapons, inventory, social activity, and more. This delivers modularity, upgradeability, and maintainability without bloating a single contract.

## Why Modular Profiles?

- Single mega-contracts become hard to upgrade, risk storage limits, and lose flexibility.
- A small core holds the essentials (name, avatar).
- Optional plugins implement specific features and can be added, replaced, or upgraded independently.
- The core calls plugins dynamically for write or read actions.

## Solidity Calls: call, delegatecall, staticcall

- call: Execute a function in another contract using its own storage/state. Use for state changes in external plugin contracts.
- delegatecall: Borrow logic but execute in the caller’s storage context. Use for upgradeable proxy patterns or shared storage (advanced; requires careful storage layout).
- staticcall: Read-only call to another contract. Use for view/pure functions in plugins.

## Architecture Overview

- PluginStore (core hub)
  - Stores base player profile: name, avatar
  - Registers plugin contracts by keys (e.g., "achievements", "weapon")
  - Dispatches write calls via call and read calls via staticcall
- Plugins (feature modules)
  - AchievementsPlugin: track latest achievement per user
  - WeaponStorePlugin: track currently equipped weapon per user
  - Future plugins: friends, battle logs, token inventory (ERC-20/NFT), etc.

### Data Flow (conceptual)

- Register: admin maps a plugin key to its contract address
- Write: PluginStore call → plugin executes and updates its own storage
- Read: PluginStore staticcall → plugin returns data (e.g., strings)


## Usage Examples

- Register plugins:
  - registerPlugin("weapon", 0x...WeaponStorePluginAddress)
  - registerPlugin("achievements", 0x...AchievementsPluginAddress)

- Write via core:
  - runPlugin("weapon", "setWeapon(address,string)", msg.sender, "Golden Axe")
  - runPlugin("achievements", "setAchievement(address,string)", msg.sender, "First Blood")

- Read via core:
  - runPluginView("weapon", "getWeapon(address)", userAddress)
  - runPluginView("achievements", "getAchievement(address)", userAddress)

## Design Considerations

- Access Control: Restrict registerPlugin and potentially runPlugin to authorized users/workflows (Ownable, Roles).
- Input Validation: Validate function signatures and arguments; consider typed interfaces when possible.
- Error Handling: Low-level calls return (success, data). Handle and bubble meaningful failures.
- Gas and UX: staticcall for reads keeps UI responsive; modular plugins isolate state and limit core storage growth.
- Security: Be cautious with delegatecall; only use trusted logic and maintain strict storage layout discipline.
- Extensibility: Add new plugins without touching core; swap implementations by updating plugin address under a key.

## Next Steps

- Implement FriendsPlugin, BattleLogPlugin, TokenInventoryPlugin (ERC-20/NFT tracking).
- Add events for profile and plugin updates to support indexing and off-chain UI.
- Introduce role-based access control (OpenZeppelin Ownable/AccessControl).
- Consider standardizing plugin interfaces (e.g., function selectors) to reduce signature-string errors.
- If exploring delegatecall, design a storage layout registry and rigorous upgrade path.

## minimal example of delegatecall 
The idea: keep player storage inside PluginStore, and let plugins provide logic that writes into PluginStore’s storage via delegatecall. That requires the plugin and core to share an identical storage layout for the parts they touch.

PluginStore.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Core idea:
 * - Keep all player data in PluginStore storage.
 * - Allow plugins to execute logic via delegatecall, writing to PluginStore storage.
 * - Enforce identical storage layout between PluginStore and delegatecall plugins for touched slots.
 *
 * SECURITY:
 * - Only delegatecall to trusted plugin contracts.
 * - Gate registerPlugin and runPluginDelegate (e.g., Ownable / AccessControl).
 */
contract PluginStore {
    struct PlayerProfile {
        string name;
        string avatar;
    }

    // Storage layout (must match plugins that use delegatecall)
    mapping(address => PlayerProfile) public profiles;

    // Example additional storage managed via delegatecall:
    // user => latest achievement
    mapping(address => string) public latestAchievement;
    // user => equipped weapon
    mapping(address => string) public equippedWeapon;

    // plugin key => plugin address
    mapping(string => address) public plugins;

    // --- Core Profile Logic ---
    function setProfile(string memory _name, string memory _avatar) external {
        profiles[msg.sender] = PlayerProfile(_name, _avatar);
    }

    function getProfile(address user)
        external
        view
        returns (string memory, string memory)
    {
        PlayerProfile memory profile = profiles[user];
        return (profile.name, profile.avatar);
    }

    // --- Plugin Management ---
    function registerPlugin(string memory key, address pluginAddress) external {
        // In production: add access control and validation
        plugins[key] = pluginAddress;
    }

    function getPlugin(string memory key) external view returns (address) {
        return plugins[key];
    }

    // --- Delegatecall Execution ---
    // Example: functionSignature = "setAchievementDelegate(address,string)"
    function runPluginDelegate(
        string memory key,
        string memory functionSignature,
        address user,
        string memory argument
    ) external {
        address plugin = plugins[key];
        require(plugin != address(0), "Plugin not registered");

        bytes memory data = abi.encodeWithSignature(functionSignature, user, argument);

        (bool success, bytes memory ret) = plugin.delegatecall(data);
        if (!success) {
            // Bubble up revert reason if present
            if (ret.length > 0) {
                assembly {
                    revert(add(ret, 32), mload(ret))
                }
            }
            revert("Delegatecall failed");
        }
    }

    // Read paths still use normal view getters from PluginStore storage
    function getAchievement(address user) external view returns (string memory) {
        return latestAchievement[user];
    }

    function getWeapon(address user) external view returns (string memory) {
        return equippedWeapon[user];
    }
}
```

DelegateAchievementsPlugin.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Delegatecall plugin: writes to PluginStore storage via delegatecall.
 *
 * IMPORTANT: Must match the storage layout for the slots it touches in PluginStore.
 * Here we only touch `latestAchievement` (mapping(address => string)).
 *
 * Do NOT declare new state variables that would change the relative slot positions
 * used by the core contract for the same mappings you intend to touch.
 *
 * Best practice: operate via internal library patterns or minimal contracts that
 * only contain functions and no extra storage declarations beyond the ones that
 * must match the caller’s storage.
 */
contract DelegateAchievementsPlugin {
    // These declarations MUST match PluginStore for touched slots.
    // We include only the mapping we intend to modify via delegatecall.
    mapping(address => string) public latestAchievement;

    /**
     * Writes the latest achievement into the caller's storage (PluginStore),
     * because this function will be invoked via delegatecall.
     */
    function setAchievementDelegate(address user, string memory achievement) public {
        latestAchievement[user] = achievement;
    }
}
```

DelegateWeaponPlugin.sol
```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * Delegatecall plugin for weapons. Matches the storage used by PluginStore.
 */
contract DelegateWeaponPlugin {
    mapping(address => string) public equippedWeapon;

    function setWeaponDelegate(address user, string memory weapon) public {
        equippedWeapon[user] = weapon;
    }
}
```

Example usage (pseudo sequence):
1) Deploy PluginStore
2) Deploy DelegateAchievementsPlugin
3) Deploy DelegateWeaponPlugin
4) Register plugins under keys

    `PluginStore.registerPlugin("achievementsDelegate", <DelegateAchievementsPlugin_addr>);`
    `PluginStore.registerPlugin("weaponDelegate", <DelegateWeaponPlugin_addr>);`

5) Write via delegatecall into PluginStore's storage
    `PluginStore.runPluginDelegate("achievementsDelegate", "setAchievementDelegate(address string)", msg.sender, "First Blood" );`

    `PluginStore.runPluginDelegate("weaponDelegate", "setWeaponDelegate(address,string)", msg.sender, "Golden Axe");`

6) Read directly from PluginStore's storage (no delegatecall needed)
    `PluginStore.getAchievement(userAddress)  // => "First Blood"`
    `PluginStore.getWeapon(userAddress)       // => "Golden Axe"`
