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

import "forge-std/Test.sol";
import {RwaRegistry} from "./RwaRegistry.sol";

contract RwaRegistryTest is Test {
  RwaRegistry internal reg;

  function setUp() public {
    reg = new RwaRegistry();
  }

  /*//////////////////////////////////
     Supported Components Management
  //////////////////////////////////*/

  function testAddDefaultSupportedComponentsDuringDeployment() public {
    assertEq(reg.isSupportedComponent("token"), 1);
    assertEq(reg.isSupportedComponent("urn"), 1);
    assertEq(reg.isSupportedComponent("liquidationOracle"), 1);
    assertEq(reg.isSupportedComponent("outputConduit"), 1);
    assertEq(reg.isSupportedComponent("inputConduit"), 1);
    assertEq(reg.isSupportedComponent("jar"), 1);
  }

  function testAddSupportedComponent() public {
    reg.addSupportedComponent("somethingElse");

    assertEq(reg.isSupportedComponent("somethingElse"), 1);
  }

  function testFuzzRevertUnautorizedAddSupportedComponent(address sender_) public {
    vm.expectRevert(RwaRegistry.Unauthorized.selector);

    vm.prank(sender_);
    reg.addSupportedComponent("anything");
  }

  function testFuzzRevertAddExistingSupportedComponent(bytes32 componentName_) public {
    reg.addSupportedComponent(componentName_);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.ComponentAlreadySupported.selector, componentName_));
    reg.addSupportedComponent(componentName_);
  }

  /*//////////////////////////////////
     Deals & Components Management
  //////////////////////////////////*/

  function testFuzzAddDealAndItsComponents(
    bytes32 ilk_,
    address token_,
    address urn_,
    address liquidationOracle_,
    address outputConduit_,
    address inputConduit_,
    address jar_
  ) public {
    RwaRegistry.Component[] memory expectedComponents = new RwaRegistry.Component[](6);

    expectedComponents[0] = RwaRegistry.Component({name: "token", addr: token_, variant: 1});
    expectedComponents[1] = RwaRegistry.Component({name: "urn", addr: urn_, variant: 1});
    expectedComponents[2] = RwaRegistry.Component({name: "liquidationOracle", addr: liquidationOracle_, variant: 1});
    expectedComponents[3] = RwaRegistry.Component({name: "outputConduit", addr: outputConduit_, variant: 1});
    expectedComponents[4] = RwaRegistry.Component({name: "inputConduit", addr: inputConduit_, variant: 1});
    expectedComponents[5] = RwaRegistry.Component({name: "jar", addr: jar_, variant: 1});

    reg.add(ilk_, expectedComponents);

    (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
    RwaRegistry.Component[] memory actualComponents = reg.listComponentsOf(ilk_);

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));

    assertEq(actualComponents[0].name, expectedComponents[0].name, "Component mismatch: token");
    assertEq(actualComponents[1].name, expectedComponents[1].name, "Component mismatch: urn");
    assertEq(actualComponents[2].name, expectedComponents[2].name, "Component mismatch: liquidationOracle");
    assertEq(actualComponents[3].name, expectedComponents[3].name, "Component mismatch: outputConduit");
    assertEq(actualComponents[4].name, expectedComponents[4].name, "Component mismatch: inputConduit");
    assertEq(actualComponents[5].name, expectedComponents[5].name, "Component mismatch: jar");

    assertEq(actualComponents[0].addr, expectedComponents[0].addr, "Component address mismatch: token");
    assertEq(actualComponents[1].addr, expectedComponents[1].addr, "Component address mismatch: urn");
    assertEq(actualComponents[2].addr, expectedComponents[2].addr, "Component address mismatch: liquidationOracle");
    assertEq(actualComponents[3].addr, expectedComponents[3].addr, "Component address mismatch: outputConduit");
    assertEq(actualComponents[4].addr, expectedComponents[4].addr, "Component address mismatch: inputConduit");
    assertEq(actualComponents[5].addr, expectedComponents[5].addr, "Component address mismatch: jar");

    assertEq(actualComponents[0].variant, expectedComponents[0].variant, "Component variant mismatch: token");
    assertEq(actualComponents[1].variant, expectedComponents[1].variant, "Component variant mismatch: urn");
    assertEq(
      actualComponents[2].variant,
      expectedComponents[2].variant,
      "Component variant mismatch: liquidationOracle"
    );
    assertEq(actualComponents[3].variant, expectedComponents[3].variant, "Component variant mismatch: outputConduit");
    assertEq(actualComponents[4].variant, expectedComponents[4].variant, "Component variant mismatch: inputConduit");
    assertEq(actualComponents[5].variant, expectedComponents[5].variant, "Component variant mismatch: jar");
  }

  function testFuzzAddDealAndItsComponentsAsTuple(
    bytes32 ilk_,
    address token_,
    address urn_
  ) public {
    bytes32[] memory names = new bytes32[](2);
    names[0] = "token";
    names[1] = "urn";

    address[] memory addrs = new address[](2);
    addrs[0] = token_;
    addrs[1] = urn_;

    uint256[] memory variants = new uint256[](2);
    variants[0] = 1;
    variants[1] = 1;

    reg.add(ilk_, names, addrs, variants);

    (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
    RwaRegistry.Component[] memory actualComponents = reg.listComponentsOf(ilk_);

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));

    assertEq(actualComponents[0].name, names[0], "Component mismatch: token");
    assertEq(actualComponents[1].name, names[1], "Component mismatch: urn");

    assertEq(actualComponents[0].addr, addrs[0], "Component address mismatch: token");
    assertEq(actualComponents[1].addr, addrs[1], "Component address mismatch: urn");

    assertEq(actualComponents[0].variant, variants[0], "Component variant mismatch: token");
    assertEq(actualComponents[1].variant, variants[1], "Component variant mismatch: urn");
  }

  function testUpdateDealComponent(
    bytes32 ilk_,
    address token_,
    uint256 variant_
  ) public {
    RwaRegistry.Component memory originalComponent = RwaRegistry.Component({
      name: "token",
      addr: address(0x1337),
      variant: 1
    });
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = originalComponent;
    reg.add(ilk_, components);

    RwaRegistry.Component memory expectedComponent = RwaRegistry.Component({
      name: "token",
      addr: token_,
      variant: variant_
    });
    reg.file(ilk_, "component", expectedComponent);

    RwaRegistry.Component memory actualComponent = reg.getComponent(ilk_, "token");
    assertEq(actualComponent.addr, expectedComponent.addr, "Component address mismatch: token");
    assertEq(actualComponent.variant, expectedComponent.variant, "Component variant mismatch: token");
  }

  function testUpdateDealComponentAsTuple(
    bytes32 ilk_,
    address token_,
    uint256 variant_
  ) public {
    RwaRegistry.Component memory originalComponent = RwaRegistry.Component({
      name: "token",
      addr: address(0x1337),
      variant: 1
    });
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = originalComponent;
    reg.add(ilk_, components);

    reg.file(ilk_, "component", "token", token_, variant_);

    (, address actualAddr, uint256 actualVariant) = reg.getComponentTuple(ilk_, "token");
    assertEq(actualAddr, token_, "Component address mismatch: token");
    assertEq(actualVariant, variant_, "Component variant mismatch: token");
  }
}
