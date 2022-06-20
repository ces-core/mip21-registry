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
  /// @notice Addresses with admin access on this contract. `wards[usr]`
  mapping(address => uint256) public wards;

  /// @notice Maps a RWA ilk to the related info. `ilksToInfo[ilk]`
  mapping(bytes32 => Info) public ilkToInfo;

  /// @notice List of all RWA ilks in this registry.
  bytes32[] internal ilks;

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

  /// @notice Revert reason when `msg.sender` does not have the required admin access.
  error NotAuthorized();

  /**
   * @notice Revert reason when trying to add info for an ilk which already exists.
   * @param ilk The ilk being added.
   */
  error IlkAlreadyExists(bytes32 ilk);

  /**
   * @notice Revert reason when adding an OutputConduit different than the one returned by the Urn
   * @param urn The urn address.
   */
  error UrnOutputConduitMismatch(address urn);

  /**
   * @notice Only addresses with admin access can call methods with this modifier.
   */
  modifier auth() {
    if (wards[msg.sender] != 1) {
      revert NotAuthorized();
    }
    _;
  }

  // MIP-21 Architeture Components
  struct Component {
    address addr; // address of the component of the deal.
    uint96 variant; // variant of the component implementation (1, 2, ...). Any reserved values should be documented.
  }

  // Information about a RWA Deal
  struct Info {
    uint256 pos; // index in ilks array
    Component token; // address and variant of the RwaToken for the deal. [required]
    Component urn; // address and variant of the RwaUrn for the deal. [required]
    Component liquidationOracle; // address and variant of the RwaLiquidationOracle for the deal. [required]
    Component outputConduit; // address and variant of the RwaOutputConduit for the deal; variant should be `type(uint96).max` when it should be treated as an opaque address [required]
    Component inputConduit; // address and variant of the RwaInput for the deal. [optional]
    Component jar; // address and variant of the RwaJar for the deal. [optional]
  }

  /// @notice The deployer of the contract gains admin access to it.
  constructor() {
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

  /**
   * @notice Adds the components of MIP-21 associated to an `ilk_`
   * @param ilk_ The ilk name.
   * @param token_ address and variant of the RwaToken for the deal. [required]
   * @param urn_ address and variant of the RwaUrn for the deal. [required]
   * @param liquidationOracle_ address and variant of the RwaLiquidationOracle for the deal. [required]
   * @param outputConduit_ address and variant of the RwaOutputConduit for the deal;
   *        variant should be `type(uint96).max` when it should be treated as an opaque address [required]
   * @param _inputConduit address and variant of the RwaInput for the deal [optional];
   *        Provide [address(0), 0] if the component was not deployed.
   * @param _jar address and variant of the RwaJar for the deal [optional];
   *        Provide [address(0), 0] if the component was not deployed.
   */
  function add(
    bytes32 ilk_,
    Component calldata token_,
    Component calldata urn_,
    Component calldata liquidationOracle_,
    Component calldata outputConduit_,
    Component calldata inputConduit_,
    Component calldata jar_
  ) external auth {
    if (ilkToInfo[ilk_].token.addr != address(0)) {
      revert IlkAlreadyExists(ilk_);
    }

    if (RwaUrnLike(urn_.addr).outputConduit() != outputConduit_.addr) {
      revert UrnOutputConduitMismatch(urn_.addr);
    }

    ilks.push(ilk_);
    Info storage info = ilkToInfo[ilk_];

    info.pos = ilks.length - 1;
    info.token = token_;
    info.urn = urn_;
    info.liquidationOracle = liquidationOracle_;
    info.outputConduit = outputConduit_;
    info.inputConduit = inputConduit_;
    info.jar = jar_;
  }
}

interface RwaUrnLike {
  function outputConduit() external view returns (address);
}
