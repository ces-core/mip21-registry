// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later AND MIT

pragma solidity ^0.8.14;

import {EnumerableSet} from "./EnumerableSet.sol";

/**
 * @title RWA Registry
 * @author Henrique Barcelos <henrique@clio.finance>
 * @notice Registry for different deals onboarded into MCD.
 */
contract RwaRegistry {
    /*//////////////////////////////////
          MCD-style Authorization
    //////////////////////////////////*/

    /// @notice Addresses with admin access on this contract. `wards[usr]`.
    mapping(address => uint256) public wards;

    /**
     * @notice `usr` was granted admin access.
     * @param usr The user address.
     */
    event Rely(address indexed usr);

    /**
     * @notice `usr` admin access was revoked.
     * @param usr The user address.
     */
    event Deny(address indexed usr);

    /**
     * @notice Only addresses with admin access can call methods with this modifier.
     */
    modifier auth() {
        require(wards[msg.sender] == 1, "RwaRegistry/not-authorized");
        _;
    }

    /**
     * @notice Grants `usr` admin access to this contract.
     * @param usr The user address.
     */
    function rely(address usr) external auth {
        wards[usr] = 1;
        emit Rely(usr);
    }

    /**
     * @notice Revokes `usr` admin access from this contract.
     * @param usr The user address.
     */
    function deny(address usr) external auth {
        wards[usr] = 0;
        emit Deny(usr);
    }

    // ------------------------------------

    using EnumerableSet for EnumerableSet.Bytes32Set;

    /**
     * ┌──────┐     add()    ┌────────┐  finalize()  ┌───────────┐
     * │ NONE ├─────────────►│ ACTIVE ├─────────────►│ FINALIZED │
     * └──────┘              └────────┘              └───────────┘
     */
    enum DealStatus {
        NONE, // The deal does not exist.
        ACTIVE, // The deal is active.
        FINALIZED // The deal was finalized.
    }

    // Information about a RWA Deal
    struct Deal {
        DealStatus status; // Whether the deal exists or not.
        uint248 pos; // Index in ilks array.
        EnumerableSet.Bytes32Set _components; // Set of components for the deal.
        mapping(bytes32 => Component) _nameToComponent; // Associate a component name to its params. _nameToComponent[componentName].
    }

    // Architeture Components. `name` is not needed in storage because it is the mapping key.
    struct Component {
        bool exists; // Whether the component exists or not.
        address addr; // Address of the component.
        uint8 variant; // Variant of the component implementation (1, 2, ...). Any reserved values should be documented.
    }

    /// @notice An enumerable set of all supported component names.
    EnumerableSet.Bytes32Set internal _supportedComponents;

    /// @notice An enumerable set of all registered ilks.
    EnumerableSet.Bytes32Set internal _ilks;

    /// @notice Maps a RWA ilk to the related deal. `_ilkToDeal[ilk]`
    mapping(bytes32 => Deal) internal _ilkToDeal;

    /**
     * @notice The deal identified by `ilk` was added to the registry.
     * @param ilk The ilk name.
     */
    event AddDeal(bytes32 indexed ilk);

    /**
     * @notice The deal identified by `ilk` was finalized.
     * @param ilk The ilk name.
     */
    event FinalizeDeal(bytes32 indexed ilk);

    /**
     * @notice Supported component `component` was added to the registry.
     * @param component The new supported component name.
     */
    event AddSupportedComponent(bytes32 indexed component);

    /**
     * @notice A Deal component for `ilk` was set.
     * @param ilk The ilk name.
     * @param name The component name.
     * @param addr The component address.
     * @param variant The component variant.
     */
    event SetComponent(bytes32 indexed ilk, bytes32 indexed name, address addr, uint256 variant);

    /**
     * @notice The deployer of the contract gains admin access to it.
     * @dev Adds the default supported component names to the registry.
     */
    constructor() {
        _supportedComponents.add("urn");
        emit AddSupportedComponent("urn");

        _supportedComponents.add("liquidationOracle");
        emit AddSupportedComponent("liquidationOracle");

        _supportedComponents.add("outputConduit");
        emit AddSupportedComponent("outputConduit");

        _supportedComponents.add("inputConduit");
        emit AddSupportedComponent("inputConduit");

        _supportedComponents.add("jar");
        emit AddSupportedComponent("jar");

        _supportedComponents.add("jarInputConduit");
        emit AddSupportedComponent("jarInputConduit");

        wards[msg.sender] = 1;
        emit Rely(msg.sender);
    }

    /*//////////////////////////////////
      Supported Components Management
    //////////////////////////////////*/

    /**
     * @notice Adds a supported component name to the registry.
     * @dev Adds a new type of component that should be supported.
     * @param name The "pascalCased" name of the component.
     */
    function addSupportedComponent(bytes32 name) external auth {
        require(!_supportedComponents.contains(name), "RwaRegistry/component-already-supported");
        _supportedComponents.add(name);

        emit AddSupportedComponent(name);
    }

    /**
     * @notice Returns whether a component name is supported or not.
     * @param name The "pascalCased" name of the component.
     * @return Whether a component name is supported or not.
     */
    function isSupportedComponent(bytes32 name) external view returns (bool) {
        return _supportedComponents.contains(name);
    }

    /**
     * @notice Lists the names of all types of components supported by the registry.
     * @return The list of component names.
     */
    function listSupportedComponents() external view returns (bytes32[] memory) {
        return _supportedComponents.values();
    }

    /*//////////////////////////////////
       Deals & Components Management
    //////////////////////////////////*/

    /**
     * @notice Adds a deal identified by `ilk` to the registry.
     * @param ilk The ilk name.
     */
    function add(bytes32 ilk) external auth {
        _addDeal(ilk);
    }

    /**
     * @notice Adds a deal identified by `ilk` with its components to the registry.
     * @param ilk The ilk name.
     * @param names The list of component names.
     * @param addrs The list of component addresses.
     * @param variants The list of component variants.
     */
    function add(
        bytes32 ilk,
        bytes32[] calldata names,
        address[] calldata addrs,
        uint256[] calldata variants
    ) external auth {
        _addDeal(ilk);
        _addComponents(ilk, names, addrs, variants);
    }

    /**
     * @notice Marks the deal identified by `ilk` as finalized. i
     * @dev Further registry updates for that deal will be forbidden.
     * @param ilk The ilk name.
     */
    function finalize(bytes32 ilk) external auth {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status == DealStatus.ACTIVE, "RwaRegistry/deal-not-active");

        deal.status = DealStatus.FINALIZED;

        emit FinalizeDeal(ilk);
    }

    /**
     * @notice Removes a deal identified by `ilk`.
     * @dev A deal cannot be removed before all of its components have been removed.
     * @param ilk The ilk name.
     */
    function remove(bytes32 ilk) external auth {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status != DealStatus.NONE, "RwaRegistry/invalid-deal");
        require(deal._components.length() == 0, "RwaRegistry/deal-dangling-components");

        delete deal.status;
        delete deal.pos;
        _ilks.remove(ilk);
    }

    /**
     * @notice Adds or updates a component of an existing `ilk`.
     * @param ilk The ilk name.
     * @param name The name of the component. Must be one of the supported ones.
     * @param addr The address of the component.
     * @param variant The variant of the component.
     */
    function setComponent(
        bytes32 ilk,
        bytes32 name,
        address addr,
        uint256 variant
    ) external auth {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status == DealStatus.ACTIVE, "RwaRegistry/deal-not-active");

        _addOrUpdateComponent(ilk, name, addr, variant);
    }

    /**
     * @notice Removes a component from an existing `ilk`.
     * @param ilk The ilk name.
     * @param name The name of the component. Must be one of the supported ones.
     */
    function removeComponent(bytes32 ilk, bytes32 name) external auth {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status == DealStatus.ACTIVE, "RwaRegistry/deal-not-active");

        deal._components.remove(name);
        delete deal._nameToComponent[name];
    }

    /**
     * @notice Returns the deal info for the given ilk.
     * @param ilk The ilk name.
     * @return status The deal status.
     * @return pos The ilk position in the ilk set.
     */
    function ilkToDeal(bytes32 ilk) external view returns (DealStatus status, uint256 pos) {
        Deal storage deal = _ilkToDeal[ilk];
        return (deal.status, deal.pos);
    }

    /**
     * @notice Returns the ilk at a given position.
     * @param pos The desired position.
     * @return The ilk.
     */
    function posToIlk(uint256 pos) external view returns (bytes32) {
        return _ilks.at(pos);
    }

    /**
     * @notice Lists all ilks present in the registry.
     * @return The list of ilks.
     */
    function list() external view returns (bytes32[] memory) {
        return _ilks.values();
    }

    /**
     * @notice Returns whether the deal identified by `ilk` is in the registry or not.
     * @param ilk The ilk name.
     * @return Whether the deal exists or not;
     */
    function has(bytes32 ilk) external view returns (bool) {
        return _ilkToDeal[ilk].status != DealStatus.NONE;
    }

    /**
     * @notice Iterates through ilks present in the registry from `start` (inclusive) to `end` (exclusive).
     * @dev If `end > items.length`, it will stop the iteration at `items.length`.
     * @dev Examples:
     *    - iter(0,10) will return 10 elements, from 0 to 9 if the ilks array have at least 10 elements.
     *    - iter(0,10) will return 3 elements, from 0 to 2 if the ilks array have only 3 elements.
     * @param start The 0-based index to start the iteration (inclusive).
     * @param end The 0-based index to stop the iteration (exclusive).
     * @return The list of ilks.
     */
    function iter(uint256 start, uint256 end) external view returns (bytes32[] memory) {
        uint256 ilksLength = _ilks.length();
        end = end > ilksLength ? ilksLength : end;
        require(start <= end, "RwaRegistry/invalid-iteration");

        // Since `end` is exclusive, if start == end, then it should return an empty array;
        uint256 size;
        unchecked {
            size = end - start;
        }
        bytes32[] memory result = new bytes32[](size);

        for (uint256 i = 0; i < size; ) {
            result[i] = _ilks.at(start + i);

            unchecked {
                i++;
            }
        }

        return result;
    }

    /**
     * @notice Returns the amount of ilks present in the registry.
     * @return The amount of ilks.
     */
    function count() external view returns (uint256) {
        return _ilks.length();
    }

    /**
     * @notice Returns the list of components associated to `ilk`.
     * @param ilk The ilk name.
     * @return The list of component names.
     */
    function listComponentNames(bytes32 ilk) external view returns (bytes32[] memory) {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status != DealStatus.NONE, "RwaRegistry/invalid-deal");

        return deal._components.values();
    }

    /**
     * @notice Iterates through component names of a deal from `start` (inclusive) to `end` (exclusive).
     * @dev If `end > items.length`, it will stop the iteration at `items.length`.
     * @dev Examples:
     *    - iterComponentNamess(0,10) will return 10 elements, from 0 to 9 if the components array have at least 10 elements.
     *    - iterComponentNamess(0,10) will return 3 elements, from 0 to 2 if the components array have only 3 elements.
     * @param ilk The ilk name.
     * @param start The 0-based index to start the iteration (inclusive).
     * @param end The 0-based index to stop the iteration (exclusive).
     * @return The list of component names.
     */
    function iterComponentNames(
        bytes32 ilk,
        uint256 start,
        uint256 end
    ) external view returns (bytes32[] memory) {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status != DealStatus.NONE, "RwaRegistry/invalid-deal");

        uint256 componentsLength = deal._components.length();
        end = end > componentsLength ? componentsLength : end;
        require(start <= end, "RwaRegistry/invalid-iteration");

        // Since `end` is exclusive, if start == end, then it should return an empty array;
        uint256 size;
        unchecked {
            size = end - start;
        }
        bytes32[] memory names = new bytes32[](size);

        for (uint256 i = 0; i < size; ) {
            names[i] = deal._components.at(start + i);

            unchecked {
                i++;
            }
        }

        return names;
    }

    /**
     * @notice Returns the list of components associated to `ilk`.
     * @param ilk The ilk name.
     * @return names The list of component names.
     * @return addrs The list of component addresses.
     * @return variants The list of component variants.
     */
    function listComponents(bytes32 ilk)
        external
        view
        returns (
            bytes32[] memory names,
            address[] memory addrs,
            uint256[] memory variants
        )
    {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status != DealStatus.NONE, "RwaRegistry/invalid-deal");

        uint256 length = deal._components.length();

        names = deal._components.values();
        addrs = new address[](length);
        variants = new uint256[](length);

        for (uint256 i = 0; i < names.length; ) {
            Component storage component = deal._nameToComponent[names[i]];

            addrs[i] = component.addr;
            variants[i] = component.variant;

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Iterates through components of a deal from `start` (inclusive) to `end` (exclusive).
     * @dev If `end > items.length`, it will stop the iteration at `items.length`.
     * @dev Examples:
     *    - iterComponentNamess(0,10) will return 10 elements, from 0 to 9 if the components array have at least 10 elements.
     *    - iterComponentNamess(0,10) will return 3 elements, from 0 to 2 if the components array have only 3 elements.
     * @param ilk The ilk name.
     * @param start The 0-based index to start the iteration (inclusive).
     * @param end The 0-based index to stop the iteration (exclusive).
     * @return names The list of component names.
     * @return addrs The list of component addresses.
     * @return variants The list of component variants.
     */
    function iterComponents(
        bytes32 ilk,
        uint256 start,
        uint256 end
    )
        external
        view
        returns (
            bytes32[] memory names,
            address[] memory addrs,
            uint256[] memory variants
        )
    {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status != DealStatus.NONE, "RwaRegistry/invalid-deal");

        uint256 componentsLength = deal._components.length();
        end = end > componentsLength ? componentsLength : end;
        require(start <= end, "RwaRegistry/invalid-iteration");

        // Since `end` is exclusive, if start == end, then it should return an empty array;
        uint256 size;
        unchecked {
            size = end - start;
        }

        names = new bytes32[](size);
        addrs = new address[](size);
        variants = new uint256[](size);

        for (uint256 i = 0; i < size; ) {
            names[i] = deal._components.at(start + i);

            Component storage component = deal._nameToComponent[names[i]];
            addrs[i] = component.addr;
            variants[i] = component.variant;

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Returns the number of components associated to `ilk`.
     * @param ilk The ilk name.
     * @return The number of components;
     */
    function countComponents(bytes32 ilk) external view returns (uint256) {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status != DealStatus.NONE, "RwaRegistry/invalid-deal");

        return deal._components.length();
    }

    /**
     * @notice Check a specific component from a deal identified by `ilk` exists.
     * @dev Returns `false` if the deal or the component does not exist.
     * @param ilk The ilk name.
     * @param name The name of the component.
     * @return Whether the component exists or not.
     */
    function hasComponent(bytes32 ilk, bytes32 name) external view returns (bool) {
        return _ilkToDeal[ilk]._nameToComponent[name].exists;
    }

    /**
     * @notice Gets a specific component from a deal identified by `ilk`.
     * @dev It will revert if the deal or the component does not exist.
     * @param ilk The ilk name.
     * @param name The name of the component.
     * @return addr The component address.
     * @return variant The component variant.
     */
    function getComponent(bytes32 ilk, bytes32 name) external view returns (address addr, uint256 variant) {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status != DealStatus.NONE, "RwaRegistry/invalid-deal");

        Component storage component = deal._nameToComponent[name];
        require(component.exists, string(abi.encodePacked("RwaRegistry/invalid-component-", name)));

        addr = component.addr;
        variant = component.variant;
    }

    /*//////////////////////////////////
              Internal Methods
    //////////////////////////////////*/

    /**
     * @notice Adds a deal identified by `ilk` with its components to the registry.
     * @param ilk The ilk name.
     */
    function _addDeal(bytes32 ilk) internal {
        Deal storage deal = _ilkToDeal[ilk];
        require(deal.status == DealStatus.NONE, "RwaRegistry/deal-already-exists");

        _ilks.add(ilk);

        deal.status = DealStatus.ACTIVE;
        deal.pos = uint248(_ilks.length());

        emit AddDeal(ilk);
    }

    /**
     * @notice Adds the components associated to a deal identified by `ilk`.
     * @dev All array arguments must have the same length and order.
     * @param ilk The ilk name.
     * @param names The list of component names.
     * @param addrs The list of component addresses.
     * @param variants The list of component variants.
     */
    function _addComponents(
        bytes32 ilk,
        bytes32[] calldata names,
        address[] calldata addrs,
        uint256[] calldata variants
    ) internal {
        require(
            names.length == addrs.length && names.length == variants.length,
            "RwaRegistry/mismatching-component-params"
        );

        for (uint256 i = 0; i < names.length; ) {
            _addOrUpdateComponent(ilk, names[i], addrs[i], variants[i]);

            unchecked {
                i++;
            }
        }
    }

    /**
     * @notice Adds a component to or updates a componenet of an existing `ilk`.
     * @param ilk The ilk name.
     * @param name The name of the component. Must be one of the supported ones.
     * @param addr The address of the component.
     * @param variant The variant of the component.
     */
    function _addOrUpdateComponent(
        bytes32 ilk,
        bytes32 name,
        address addr,
        uint256 variant
    ) internal {
        require(_supportedComponents.contains(name), "RwaRegistry/unsupported-component");
        require(addr != address(0), "RwaRegistry/invalid-component-addr");
        require(variant <= type(uint8).max, "RwaRegistry/invalid-variant");

        Deal storage deal = _ilkToDeal[ilk];
        Component storage component = deal._nameToComponent[name];

        if (!component.exists) {
            deal._components.add(name);
            component.exists = true;
        }

        component.addr = addr;
        component.variant = uint8(variant);

        emit SetComponent(ilk, name, addr, variant);
    }
}
