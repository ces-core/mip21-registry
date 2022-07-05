// Copyright (C) 2022 Dai Foundation
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

/**
 * @title MIP-21 RWA Registry
 * @author Henrique Barcelos <henrique@clio.finance>
 * @notice Registry for different MIP-21 deals onboarded into MCD.
 */
contract RwaRegistry {
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
    bytes32[] components; // List of components for the deal.
    mapping(bytes32 => Component) nameToComponent; // Associate a component name to its params. nameToComponent[componentName].
  }

  // MIP-21 Architeture Components. `name` is not needed in storage because it is the mapping key.
  struct Component {
    bool exists; // Whether the component exists or not.
    address addr; // Address of the component.
    uint88 variant; // Variant of the component implementation (1, 2, ...). Any reserved values should be documented.
  }

  /// @notice Addresses with admin access on this contract. `wards[usr]`.
  mapping(address => uint256) public wards;

  /// @notice Append-only list of all supported component names.
  bytes32[] public supportedComponents;

  /// @notice Whether a component name is supported or not. `isSupportedComponent[name]`.
  mapping(bytes32 => uint256) public isSupportedComponent;

  /// @notice List of all RWA ilks in this registry.
  bytes32[] public ilks;

  /// @notice Maps a RWA ilk to the related deal. `ilkToDeal[ilk]`
  mapping(bytes32 => Deal) public ilkToDeal;

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
   * @notice Deal component `what` identified by `ilk` was updated in the registry.
   * @param ilk The ilk name.
   * @param what What is being changed. The only possible value for this signature is "component".
   * @param name The component name.
   * @param addr The component address.
   * @param variant The component variant.
   */
  event File(bytes32 indexed ilk, bytes32 indexed what, bytes32 name, address addr, uint88 variant);

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
   * @notice Revert reason when trying to modify an unsupported parameter.
   * @param ilk The ilk related to the deal being modified.
   * @param what The parameter name.
   */
  error UnsupportedParameter(bytes32 ilk, bytes32 what);

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
   * @notice Revert reason when trying to add components with mismatching params.
   */
  error MismatchingComponentParams();

  /**
   * @notice Revert reason when trying to get a component `name` which does not exist for the deal identified by `ilk`
   * @param ilk The ilk name.
   * @param name The unsupported component name.
   */
  error ComponentDoesNotExist(bytes32 ilk, bytes32 name);

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
    isSupportedComponent["urn"] = 1;
    supportedComponents.push("urn");

    isSupportedComponent["liquidationOracle"] = 1;
    supportedComponents.push("liquidationOracle");

    isSupportedComponent["outputConduit"] = 1;
    supportedComponents.push("outputConduit");

    isSupportedComponent["inputConduit"] = 1;
    supportedComponents.push("inputConduit");

    isSupportedComponent["jar"] = 1;
    supportedComponents.push("jar");

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
   * @dev Adds a new type of MIP-21 component that should be supported.
   * @param name_ The "pascalCased" name of the component.
   */
  function addSupportedComponent(bytes32 name_) external auth {
    if (isSupportedComponent[name_] != 0) {
      revert ComponentAlreadySupported(name_);
    }

    isSupportedComponent[name_] = 1;
    supportedComponents.push(name_);

    emit AddSupportedComponent(name_);
  }

  /**
   * @notice Lists the names of all types of components supported by the registry.
   * @return The list of component names.
   */
  function listSupportedComponents() external view returns (bytes32[] memory) {
    return supportedComponents;
  }

  /*//////////////////////////////////
     Deals & Components Management
  //////////////////////////////////*/

  /**
   * @notice Adds a deal identified by `ilk_` to the registry.
   * @param ilk_ The ilk name.
   */
  function add(bytes32 ilk_) external auth {
    _addDeal(ilk_);
  }

  /**
   * @notice Adds a deal identified by `ilk_` with its components to the registry.
   * @param ilk_ The ilk name.
   * @param names_ The list of component names.
   * @param addrs_ The list of component addresses.
   * @param variants_ The list of component variants.
   */
  function add(
    bytes32 ilk_,
    bytes32[] calldata names_,
    address[] calldata addrs_,
    uint88[] calldata variants_
  ) external auth {
    _addDeal(ilk_);
    _addComponents(ilk_, names_, addrs_, variants_);
  }

  /**
   * @notice Marks the deal identified by `ilk` as finalized. i
   * @dev Further registry updates for that deal will be forbidden.
   * @param ilk_ The ilk name.
   */
  function finalize(bytes32 ilk_) external auth {
    Deal storage deal = ilkToDeal[ilk_];

    if (deal.status != DealStatus.ACTIVE) {
      revert DealIsNotActive(ilk_);
    }

    deal.status = DealStatus.FINALIZED;

    emit FinalizeDeal(ilk_);
  }

  /**
   * @notice Updates the components of an existing `ilk_`.
   * @param ilk_ The ilk name.
   * @param what_ What is being changed. One of ["component"].
   * @param name_ The name of the component. Must be one of the supported ones.
   * @param addr_ The address of the component.
   * @param variant_ The variant of the component.
   */
  function file(
    bytes32 ilk_,
    bytes32 what_,
    bytes32 name_,
    address addr_,
    uint88 variant_
  ) external auth {
    if (what_ != "component") {
      revert UnsupportedParameter(ilk_, what_);
    }

    Deal storage deal = ilkToDeal[ilk_];

    if (deal.status != DealStatus.ACTIVE) {
      revert DealIsNotActive(ilk_);
    }

    _addOrUpdateComponent(ilk_, name_, addr_, variant_);
  }

  /**
   * @notice Lists all ilks present in the registry.
   * @return The list of ilks.
   */
  function list() external view returns (bytes32[] memory) {
    return ilks;
  }

  /**
   * @notice Returns the amount of ilks present in the registry.
   * @return The amount of ilks.
   */
  function count() external view returns (uint256) {
    return ilks.length;
  }

  /**
   * @notice Returns the list of components associated to `ilk_`.
   * @param ilk_ The ilk name.
   * @return names The list of component names.
   * @return addrs The list of component addresses.
   * @return variants The list of component variants.
   */
  function listComponentsOf(bytes32 ilk_)
    external
    view
    returns (
      bytes32[] memory names,
      address[] memory addrs,
      uint88[] memory variants
    )
  {
    Deal storage deal = ilkToDeal[ilk_];

    if (deal.status == DealStatus.NONE) {
      revert DealDoesNotExist(ilk_);
    }

    bytes32[] storage components = deal.components;
    names = new bytes32[](components.length);
    addrs = new address[](components.length);
    variants = new uint88[](components.length);

    for (uint256 i = 0; i < components.length; i++) {
      Component storage component = deal.nameToComponent[components[i]];

      names[i] = components[i];
      addrs[i] = component.addr;
      variants[i] = component.variant;
    }
  }

  /**
   * @notice Gets a specific component from a deal identified by `ilk`.
   * @dev It will revert if the deal or the component does not exist.
   * @param ilk_ The ilk name.
   * @param name_ The name of the component.
   * @return addr The component address.
   * @return variant The component variant.
   */
  function getComponent(bytes32 ilk_, bytes32 name_) external view returns (address addr, uint88 variant) {
    Deal storage deal = ilkToDeal[ilk_];

    if (deal.status == DealStatus.NONE) {
      revert DealDoesNotExist(ilk_);
    }

    Component storage component = deal.nameToComponent[name_];

    if (!component.exists) {
      revert ComponentDoesNotExist(ilk_, name_);
    }

    addr = component.addr;
    variant = component.variant;
  }

  /*//////////////////////////////////
            Internal Methods
  //////////////////////////////////*/

  /**
   * @notice Adds a deal identified by `ilk_` with its components to the registry.
   * @param ilk_ The ilk name.
   */
  function _addDeal(bytes32 ilk_) internal {
    Deal storage deal = ilkToDeal[ilk_];

    if (deal.status != DealStatus.NONE) {
      revert DealAlreadyExists(ilk_);
    }

    ilks.push(ilk_);

    deal.status = DealStatus.ACTIVE;
    deal.pos = uint248(ilks.length - 1);

    emit AddDeal(ilk_);
  }

  /**
   * @notice Adds the MIP-21 components associated to a deal identified by `ilk_`.
   * @dev All array arguments must have the same length and order.
   * @param ilk_ The ilk name.
   * @param names_ The list of component names.
   * @param addrs_ The list of component addresses.
   * @param variants_ The list of component variants.
   */
  function _addComponents(
    bytes32 ilk_,
    bytes32[] calldata names_,
    address[] calldata addrs_,
    uint88[] calldata variants_
  ) internal {
    if (names_.length != addrs_.length || names_.length != variants_.length) {
      revert MismatchingComponentParams();
    }

    for (uint256 i = 0; i < names_.length; i++) {
      _addOrUpdateComponent(ilk_, names_[i], addrs_[i], variants_[i]);
    }
  }

  /**
   * @notice Adds a component to or updates a componenet of an existing `ilk_`.
   * @param ilk_ The ilk name.
   * @param name_ The name of the component. Must be one of the supported ones.
   * @param addr_ The address of the component.
   * @param variant_ The variant of the component.
   */
  function _addOrUpdateComponent(
    bytes32 ilk_,
    bytes32 name_,
    address addr_,
    uint88 variant_
  ) internal {
    if (isSupportedComponent[name_] == 0) {
      revert UnsupportedComponent(name_);
    }

    Deal storage deal = ilkToDeal[ilk_];
    Component storage component = deal.nameToComponent[name_];

    if (!component.exists) {
      deal.components.push(name_);
      component.exists = true;
    }

    component.addr = addr_;
    component.variant = variant_;

    emit File(ilk_, "component", name_, addr_, variant_);
  }
}
