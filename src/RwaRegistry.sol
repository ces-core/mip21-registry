// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.14;

import {EnumerableSet} from "./EnumerableSet.sol";

/**
 * @title RWA Registry
 * @author Henrique Barcelos <henrique@clio.finance>
 * @notice Registry for different deals onboarded into MCD.
 */
contract RwaRegistry {
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
    uint88 variant; // Variant of the component implementation (1, 2, ...). Any reserved values should be documented.
  }

  /// @notice Addresses with admin access on this contract. `wards[usr]`.
  mapping(address => uint256) public wards;

  /// @notice An enumerable set of all supported component names.
  EnumerableSet.Bytes32Set internal _supportedComponents;

  /// @notice An enumerable set of all registered ilks.
  EnumerableSet.Bytes32Set internal _ilks;

  /// @notice Maps a RWA ilk to the related deal. `_ilkToDeal[ilk]`
  mapping(bytes32 => Deal) internal _ilkToDeal;

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
  event SetComponent(bytes32 indexed ilk, bytes32 indexed name, address addr, uint88 variant);

  /**
   * @notice Revert reason when `msg.sender` does not have the required admin access.
   */
  error Unauthorized();

  /**
   * @notice Revert reason when trying to add an ilk which already exists.
   * @param ilk The ilk related to the deal being added.
   */
  error DealAlreadyExists(bytes32 ilk);

  /**
   * @notice Revert reason when trying to read or modify a deal for an ilk which does not exist.
   * @param ilk The ilk related to the deal being added.
   */
  error DealDoesNotExist(bytes32 ilk);

  /**
   * @notice Revert reason when trying to modify a deal which was already finalized.
   * @param ilk The ilk related to the deal being added.
   */
  error DealIsNotActive(bytes32 ilk);

  /**
   * @notice Revert reason when trying to add an unsupported component.
   * @param name The unsupported component name.
   */
  error UnsupportedComponent(bytes32 name);

  /**
   * @notice Revert reason when trying to add an supported component more than once.
   * @param name The component name.
   */
  error ComponentAlreadySupported(bytes32 name);

  /**
   * @notice Revert reason when trying to add a component with address set to `address(0)`.
   * @param ilk The ilk related to the deal being added.
   * @param name The component name.
   */
  error InvalidComponentAddress(bytes32 ilk, bytes32 name);

  /**
   * @notice Revert reason when trying to get a component `name` which does not exist for the deal identified by `ilk`
   * @param ilk The ilk name.
   * @param name The unsupported component name.
   */
  error ComponentDoesNotExist(bytes32 ilk, bytes32 name);

  /**
   * @notice Revert reason when trying to add components with mismatching params.
   */
  error MismatchingComponentParams();

  /**
   * @notice Revert reason when calling iterator methods with bad parameters.
   */
  error InvalidIteration();

  /**
   * @notice Only addresses with admin access can call methods with this modifier.
   */
  modifier auth() {
    if (wards[msg.sender] != 1) {
      revert Unauthorized();
    }
    _;
  }

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

    wards[msg.sender] = 1;
    emit Rely(msg.sender);
  }

  /*//////////////////////////////////
              Authorization
  //////////////////////////////////*/

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

  /*//////////////////////////////////
     Supported Components Management
  //////////////////////////////////*/

  /**
   * @notice Adds a supported component name to the registry.
   * @dev Adds a new type of component that should be supported.
   * @param name The "pascalCased" name of the component.
   */
  function addSupportedComponent(bytes32 name) external auth {
    if (_supportedComponents.contains(name)) {
      revert ComponentAlreadySupported(name);
    }

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
    uint88[] calldata variants
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

    if (deal.status != DealStatus.ACTIVE) {
      revert DealIsNotActive(ilk);
    }

    deal.status = DealStatus.FINALIZED;

    emit FinalizeDeal(ilk);
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
    uint88 variant
  ) external auth {
    Deal storage deal = _ilkToDeal[ilk];

    if (deal.status != DealStatus.ACTIVE) {
      revert DealIsNotActive(ilk);
    }

    _addOrUpdateComponent(ilk, name, addr, variant);
  }

  /**
   * @notice Removes a component from an existing `ilk`.
   * @param ilk The ilk name.
   * @param name The name of the component. Must be one of the supported ones.
   */
  function removeComponent(bytes32 ilk, bytes32 name) external auth {
    Deal storage deal = _ilkToDeal[ilk];

    if (deal.status != DealStatus.ACTIVE) {
      revert DealIsNotActive(ilk);
    }

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
   * @notice Lists all ilks present in the registry.
   * @return The list of ilks.
   */
  function list() external view returns (bytes32[] memory) {
    return _ilks.values();
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
    if (start > end) {
      revert InvalidIteration();
    }

    uint256 ilksLength = _ilks.length();
    end = end > ilksLength ? ilksLength : end;

    // Since `end` is exclusive, if start == end, then it should return an empty array;
    uint256 size = end - start;
    bytes32[] memory result = new bytes32[](size);

    for (uint256 i = 0; i < size; i++) {
      result[i] = _ilks.at(start + i);
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
   * @notice Returns the ilk at a given position.
   * @param pos The desired position.
   * @return The ilk.
   */
  function posToIlk(uint256 pos) external view returns (bytes32) {
    return _ilks.at(pos);
  }

  /**
   * @notice Returns the list of components associated to `ilk`.
   * @param ilk The ilk name.
   * @return The list of component names.
   */
  function listComponentNamesOf(bytes32 ilk) external view returns (bytes32[] memory) {
    Deal storage deal = _ilkToDeal[ilk];

    if (deal.status == DealStatus.NONE) {
      revert DealDoesNotExist(ilk);
    }

    return deal._components.values();
  }

  /**
   * @notice Returns the list of components associated to `ilk`.
   * @param ilk The ilk name.
   * @return names The list of component names.
   * @return addrs The list of component addresses.
   * @return variants The list of component variants.
   */
  function listComponentsOf(bytes32 ilk)
    external
    view
    returns (
      bytes32[] memory names,
      address[] memory addrs,
      uint88[] memory variants
    )
  {
    Deal storage deal = _ilkToDeal[ilk];

    if (deal.status == DealStatus.NONE) {
      revert DealDoesNotExist(ilk);
    }

    uint256 length = deal._components.length();

    names = deal._components.values();
    addrs = new address[](length);
    variants = new uint88[](length);

    for (uint256 i = 0; i < names.length; i++) {
      Component storage component = deal._nameToComponent[names[i]];

      addrs[i] = component.addr;
      variants[i] = component.variant;
    }
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
  function getComponent(bytes32 ilk, bytes32 name) external view returns (address addr, uint88 variant) {
    Deal storage deal = _ilkToDeal[ilk];

    if (deal.status == DealStatus.NONE) {
      revert DealDoesNotExist(ilk);
    }

    Component storage component = deal._nameToComponent[name];

    if (!component.exists) {
      revert ComponentDoesNotExist(ilk, name);
    }

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

    if (deal.status != DealStatus.NONE) {
      revert DealAlreadyExists(ilk);
    }

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
    uint88[] calldata variants
  ) internal {
    if (!(names.length == addrs.length && names.length == variants.length)) {
      revert MismatchingComponentParams();
    }

    for (uint256 i = 0; i < names.length; i++) {
      _addOrUpdateComponent(ilk, names[i], addrs[i], variants[i]);
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
    uint88 variant
  ) internal {
    if (!_supportedComponents.contains(name)) {
      revert UnsupportedComponent(name);
    }

    if (addr == address(0)) {
      revert InvalidComponentAddress(ilk, name);
    }

    Deal storage deal = _ilkToDeal[ilk];
    Component storage component = deal._nameToComponent[name];

    if (!component.exists) {
      deal._components.add(name);
      component.exists = true;
    }

    component.addr = addr;
    component.variant = variant;

    emit SetComponent(ilk, name, addr, variant);
  }
}
