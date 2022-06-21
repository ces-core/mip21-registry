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
  // MIP-21 Architeture Components. `name` is not needed because it is the mapping key.
  struct Component {
    bool exists; // Whether the component exists or not.
    address addr; // Address of the component.
    uint88 variant; // Variant of the component implementation (1, 2, ...). Any reserved values should be documented.
  }

  // MIP-21 Architeture Components type for function parameters and return.
  struct ComponentIO {
    bytes32 name; // Name of the component (i.e.: urn, token, outputConduit...).
    address addr; // Address of the component.
    uint88 variant; // Variant of the component implementation (1, 2, ...). Any reserved values should be documented.
  }

  // Information about a RWA Deal
  struct Item {
    bool exists; // Whether the item exists or not.
    uint248 pos; // Index in ilks array.
    bytes32[] components; // List of components for the item.
    mapping(bytes32 => Component) nameToComponent;
  }

  /// @notice Addresses with admin access on this contract. `wards[usr]`.
  mapping(address => uint256) public wards;

  /// @notice Append-only list of all supported component names.
  bytes32[] public supportedComponents;

  /// @notice Whether a component name is supported or not. `isSupportedComponent[name]`.
  mapping(bytes32 => uint256) public isSupportedComponent;

  /// @notice List of all RWA ilks in this registry.
  bytes32[] public ilks;

  /// @notice Maps a RWA ilk to the related item. `ilkToItem[ilk]`
  mapping(bytes32 => Item) public ilkToItem;

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
   * @notice Revert reason when `msg.sender` does not have the required admin access.
   */
  error Unauthorized();

  /**
   * @notice Revert reason when trying to add an ilk which already exists.
   * @param ilk The ilk being added.
   */
  error IlkAlreadyExists(bytes32 ilk);

  /**
   * @notice Revert reason when trying to `file` an item for an ilk which does not exist.
   * @param ilk The ilk being added.
   */
  error IlkDoesNotExist(bytes32 ilk);

  /**
   * @notice Revert reason when trying to add an unsupported component.
   * @param name The unsupported component name.
   */
  error UnsupportedComponent(bytes32 name);

  /**
   * @notice Revert reason when trying to add an ilk without any components.
   */
  error EmptyComponentList();

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
    isSupportedComponent["token"] = 1;
    supportedComponents.push("token");

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
   * @param componentName_ The "pascalCased" name of the component.
   */
  function addSupportedComponent(bytes32 componentName_) external auth {
    if (isSupportedComponent[componentName_] == 0) {
      isSupportedComponent[componentName_] = 1;
      supportedComponents.push(componentName_);
    }
  }

  /**
   * @notice Lists the names of all types of components supported by the registry.
   * @return The list of component names.
   */
  function listSupportedComponents() external view returns (bytes32[] memory) {
    return supportedComponents;
  }

  /*//////////////////////////////////
          Components Management
  //////////////////////////////////*/

  /**
   * @notice Adds the components of MIP-21 associated to an `ilk_`
   * @param ilk_ The ilk name.
   * @param componentIOs_ The list of components associated with `ilk_`.
   */
  function add(bytes32 ilk_, ComponentIO[] calldata componentIOs_) external auth {
    if (componentIOs_.length == 0) {
      revert EmptyComponentList();
    }

    Item storage item = ilkToItem[ilk_];

    if (item.exists) {
      revert IlkAlreadyExists(ilk_);
    }

    ilks.push(ilk_);

    item.exists = true;
    item.pos = uint248(ilks.length - 1);

    for (uint256 i = 0; i < componentIOs_.length; i++) {
      ComponentIO calldata componentIO = componentIOs_[i];

      if (isSupportedComponent[componentIO.name] == 0) {
        revert UnsupportedComponent(componentIO.name);
      }

      item.components.push(componentIO.name);

      Component storage component = item.nameToComponent[componentIO.name];

      component.exists = true;
      component.addr = componentIO.addr;
      component.variant = componentIO.variant;
    }
  }

  /**
   * @notice Updates the components of an existing `ilk_`.
   * @dev Uses only primitive types as input.
   * @param ilk_ The ilk name.
   * @param componentName_ The name of the component. Must be one of the supported ones.
   * @param componentAddr_ The address of the component.
   * @param componentVariant_ The variant of the component.
   */
  function file(
    bytes32 ilk_,
    bytes32 componentName_,
    address componentAddr_,
    uint256 componentVariant_
  ) external auth {
    Item storage item = ilkToItem[ilk_];

    if (!item.exists) {
      revert IlkDoesNotExist(ilk_);
    }

    Component storage component = item.nameToComponent[componentName_];

    if (!component.exists) {
      item.components.push(componentName_);
      component.exists = true;
    }

    component.addr = componentAddr_;
    component.variant = uint88(componentVariant_);
  }

  /**
   * @notice Updates the components of an existing `ilk_`.
   * @param ilk_ The ilk name.
   * @param componentIO_ The component parameters.
   */
  function file(bytes32 ilk_, ComponentIO calldata componentIO_) external auth {
    Item storage item = ilkToItem[ilk_];

    if (!item.exists) {
      revert IlkDoesNotExist(ilk_);
    }

    Component storage component = item.nameToComponent[componentIO_.name];

    if (!component.exists) {
      item.components.push(componentIO_.name);
      component.exists = true;
    }

    component.addr = componentIO_.addr;
    component.variant = componentIO_.variant;
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
   * @dev Returns a tuple of primitive types arrays for consumers incompatible with abicoderv2.
   * @return names The list of component names.
   * @return addrs The list of component addresses.
   * @return variants The list of component variants.
   */
  function listComponentsTupleOf(bytes32 ilk_)
    external
    view
    returns (
      bytes32[] memory names,
      address[] memory addrs,
      uint256[] memory variants
    )
  {
    Item storage item = ilkToItem[ilk_];

    if (!item.exists) {
      revert IlkDoesNotExist(ilk_);
    }

    bytes32[] storage components = item.components;
    names = new bytes32[](components.length);
    addrs = new address[](components.length);
    variants = new uint256[](components.length);

    for (uint256 i = 0; i < components.length; i++) {
      Component storage component = item.nameToComponent[components[i]];

      names[i] = components[i];
      addrs[i] = component.addr;
      variants[i] = component.variant;
    }
  }

  /**
   * @notice Returns the list of components associated to `ilk_`.
   * @param ilk_ The ilk name.
   * @return The list of components.
   */
  function listComponentsOf(bytes32 ilk_) external view returns (ComponentIO[] memory) {
    Item storage item = ilkToItem[ilk_];

    if (!item.exists) {
      revert IlkDoesNotExist(ilk_);
    }

    bytes32[] storage components = item.components;
    ComponentIO[] memory outputComponents = new ComponentIO[](components.length);

    for (uint256 i = 0; i < components.length; i++) {
      Component storage component = item.nameToComponent[components[i]];

      outputComponents[i] = ComponentIO({name: components[i], addr: component.addr, variant: component.variant});
    }

    return outputComponents;
  }
}
