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
              Authorization
  //////////////////////////////////*/

  function testRely() public {
    reg.rely(address(0x1337));

    assertEq(reg.wards(address(0x1337)), 1);
  }

  function testDeny() public {
    reg.deny(address(this));

    assertEq(reg.wards(address(this)), 0);
  }

  /*//////////////////////////////////
     Supported Components Management
  //////////////////////////////////*/

  function testAddDefaultSupportedComponentsDuringDeployment() public {
    assertEq(reg.listSupportedComponents().length, 6);
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

  function testRevertAddExistingSupportedComponent() public {
    // bytes32 componentName_

    bytes32 componentName_ = "anything";
    reg.addSupportedComponent(componentName_);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.ComponentAlreadySupported.selector, componentName_));
    reg.addSupportedComponent(componentName_);
  }

  function testRevertUnautorizedAddSupportedComponent() public {
    // address sender_
    // if (sender_ == address(this)) {
    //   return;
    // }
    address sender_ = address(0x1337);

    vm.expectRevert(RwaRegistry.Unauthorized.selector);
    vm.prank(sender_);

    reg.addSupportedComponent("anything");
  }

  /*//////////////////////////////////
     Deals & Components Management
  //////////////////////////////////*/

  function testAddDealAndComponents() public {
    // bytes32 ilk_,
    // address token_,
    // address urn_,
    // address liquidationOracle_,
    // address outputConduit_,
    // address inputConduit_,
    // address jar_

    bytes32 ilk_ = "RWA1337-a";
    address token_ = address(0x1337);
    address urn_ = address(0x2448);
    address liquidationOracle_ = address(0x3559);
    address outputConduit_ = address(0x466a);
    address inputConduit_ = address(0x577b);
    address jar_ = address(0x688c);

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

  function testRevertAddDealWithUnsupportedComponent() public {
    // bytes32 ilk_,
    // address token_,
    // address someAddr,

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x1337);
    address someAddr_ = address(0x2448);

    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](2);

    components[0] = RwaRegistry.Component({name: "token", addr: token_, variant: 1});
    components[1] = RwaRegistry.Component({name: "something", addr: someAddr_, variant: 1});

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.UnsupportedComponent.selector, components[1].name));
    reg.add(ilk_, components);
  }

  function testAddDealAndComponentsAsTuple() public {
    // bytes32 ilk_,
    // address token_,
    // address urn_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x1337);
    address urn_ = address(0x2448);

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
    (bytes32[] memory actualNames, address[] memory actualAddrs, uint256[] memory actualVariants) = reg
      .listComponentsTupleOf(ilk_);

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));

    assertEq(actualNames[0], names[0], "Component mismatch: token");
    assertEq(actualNames[1], names[1], "Component mismatch: urn");

    assertEq(actualAddrs[0], addrs[0], "Component address mismatch: token");
    assertEq(actualAddrs[1], addrs[1], "Component address mismatch: urn");

    assertEq(actualVariants[0], variants[0], "Component variant mismatch: token");
    assertEq(actualVariants[1], variants[1], "Component variant mismatch: urn");
  }

  function testRevertAddDealWithUnsupportedComponentAsTuple() public {
    // bytes32 ilk_,
    // address token_,
    // address someAddr,

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x1337);
    address someAddr_ = address(0x2448);

    bytes32[] memory names = new bytes32[](2);
    names[0] = "token";
    names[1] = "something";

    address[] memory addrs = new address[](2);
    addrs[0] = token_;
    addrs[1] = someAddr_;

    uint256[] memory variants = new uint256[](2);
    variants[0] = 1;
    variants[1] = 1;

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.UnsupportedComponent.selector, names[1]));
    reg.add(ilk_, names, addrs, variants);
  }

  function testRevertAddDealWithComponentsAsTupleWithMismatchingParams() public {
    // bytes32 ilk_,
    // address token_,
    // address urn_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x1337);
    address urn_ = address(0x2448);

    bytes32[] memory names = new bytes32[](1);
    names[0] = "token";

    address[] memory addrs = new address[](2);
    addrs[0] = token_;
    addrs[1] = urn_;

    uint256[] memory variants = new uint256[](2);
    variants[0] = 1;
    variants[1] = 1;

    vm.expectRevert(RwaRegistry.MismatchingComponentParams.selector);
    reg.add(ilk_, names, addrs, variants);
  }

  function testRevertListComponentsOfUnexistingDeal() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealDoesNotExist.selector, ilk_));
    reg.listComponentsOf(ilk_);
  }

  function testRevertListComponentsTupleOfUnexistingDeal() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealDoesNotExist.selector, ilk_));
    reg.listComponentsTupleOf(ilk_);
  }

  function testAddDealWithEmptyComponentList() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    RwaRegistry.Component[] memory components;
    reg.add(ilk_, components);

    (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
    RwaRegistry.Component[] memory actualComponents = reg.listComponentsOf(ilk_);

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));
    assertTrue(actualComponents.length == 0);
  }

  function testAddDealWithNoComponents() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    reg.add(ilk_);

    (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
    RwaRegistry.Component[] memory actualComponents = reg.listComponentsOf(ilk_);

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));
    assertTrue(actualComponents.length == 0);
  }

  function testRevertAddExistingDeal() public {
    // bytes32 ilk_,

    bytes32 ilk_ = "RWA1337-A";
    reg.add(ilk_);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealAlreadyExists.selector, ilk_));
    reg.add(ilk_);
  }

  function testRevertUnautorizedAddDeal() public {
    // address sender_,
    // bytes32 ilk_,
    // address token_

    // if (sender_ == address(this)) {
    //   return;
    // }

    address sender_ = address(0x1337);
    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);

    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = RwaRegistry.Component({name: "token", addr: token_, variant: 1});

    vm.expectRevert(RwaRegistry.Unauthorized.selector);
    vm.prank(sender_);

    reg.add(ilk_, components);
  }

  function testListAllDealIlks() public {
    // bytes32 ilk1_, bytes32 ilk2_
    // if (ilk1_ == ilk2_) {
    //   return;
    // }

    bytes32 ilk1_ = "RWA1337-A";
    bytes32 ilk2_ = "RWA2448-A";

    reg.add(ilk1_);
    reg.add(ilk2_);

    bytes32[] memory actualIlks = reg.list();

    bytes32[] memory expectedIlks = new bytes32[](2);
    expectedIlks[0] = ilk1_;
    expectedIlks[1] = ilk2_;

    assertEq(actualIlks[0], expectedIlks[0]);
    assertEq(actualIlks[1], expectedIlks[1]);
  }

  function testiCountAllDealIlks() public {
    // bytes32[] memory ilks_
    // if (ilks_.length == 0) {
    //   return;
    // }

    bytes32[] memory ilks_ = new bytes32[](3);
    ilks_[0] = "RWA1337-A";
    ilks_[1] = "RWA2448-A";
    ilks_[2] = "RWA3559-A";

    uint256 duplicates = 0;
    for (uint256 i = 0; i < ilks_.length; i++) {
      try reg.add(ilks_[i]) {} catch {
        duplicates++;
      }
    }

    uint256 count = reg.count();

    uint256 expected = ilks_.length - duplicates;
    assertEq(count, expected);
  }

  function testAddNewDealComponent() public {
    // bytes32 ilk_,
    // address token_,
    // address urn_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x1337);
    address urn_ = address(0x3549);
    uint256 variant_ = 0x2830;

    RwaRegistry.Component memory originalComponent = RwaRegistry.Component({name: "token", addr: token_, variant: 1});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = originalComponent;
    reg.add(ilk_, components);

    RwaRegistry.Component memory newComponent = RwaRegistry.Component({name: "urn", addr: urn_, variant: variant_});
    reg.file(ilk_, "component", newComponent);

    RwaRegistry.Component memory actualComponent = reg.getComponent(ilk_, "urn");
    assertEq(actualComponent.addr, newComponent.addr, "Component address mismatch");
    assertEq(actualComponent.variant, newComponent.variant, "Component variant mismatch");
  }

  function testAddNewDealComponentAsTuple() public {
    // bytes32 ilk_,
    // address token_,
    // address urn_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x1337);
    address urn_ = address(0x3549);
    uint256 variant_ = 0x2830;

    RwaRegistry.Component memory originalComponent = RwaRegistry.Component({name: "token", addr: token_, variant: 1});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = originalComponent;
    reg.add(ilk_, components);

    reg.file(ilk_, "component", "urn", urn_, variant_);

    (, address actualAddr, uint256 actualVariant) = reg.getComponentTuple(ilk_, "urn");
    assertEq(actualAddr, urn_, "Component address mismatch");
    assertEq(actualVariant, variant_, "Component variant mismatch");
  }

  function testUpdateDealComponent() public {
    // bytes32 ilk_,
    // address token_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);
    uint256 variant_ = 0x2830;

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
    assertEq(actualComponent.addr, expectedComponent.addr, "Component address mismatch");
    assertEq(actualComponent.variant, expectedComponent.variant, "Component variant mismatch");
  }

  function testReverGetComponentForUnexistingDeal() public {
    // bytes32 ilk_,
    // address token_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);
    uint256 variant_ = 0x2830;

    RwaRegistry.Component memory component = RwaRegistry.Component({name: "token", addr: token_, variant: variant_});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = component;
    reg.add(ilk_, components);

    bytes32 wrongIlk = "RWA2448-A";
    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealDoesNotExist.selector, wrongIlk));
    reg.getComponent(wrongIlk, "token");
  }

  function testReverGetUnexistentComponentForExistingDeal() public {
    // bytes32 ilk_,
    // address token_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);
    uint256 variant_ = 0x2830;

    RwaRegistry.Component memory component = RwaRegistry.Component({name: "token", addr: token_, variant: variant_});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = component;
    reg.add(ilk_, components);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.ComponentDoesNotExist.selector, ilk_, bytes32("urn")));
    reg.getComponent(ilk_, "urn");
  }

  function testUpdateDealComponentAsTuple() public {
    // bytes32 ilk_,
    // address token_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);
    uint256 variant_ = 0x2830;

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
    assertEq(actualAddr, token_, "Component address mismatch");
    assertEq(actualVariant, variant_, "Component variant mismatch");
  }

  function testReverUpdateUnexistingParameter() public {
    // bytes32 ilk_,
    // address token_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);
    uint256 variant_ = 0x2830;

    reg.add(ilk_);

    vm.expectRevert(
      abi.encodeWithSelector(RwaRegistry.UnsupportedParameter.selector, ilk_, bytes32("unexistingParameter"))
    );
    reg.file(ilk_, "unexistingParameter", RwaRegistry.Component({name: "token", addr: token_, variant: variant_}));
  }

  function testReverUpdateUnexistingParameterAsTuple() public {
    // bytes32 ilk_,
    // address token_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);
    uint256 variant_ = 0x2830;

    reg.add(ilk_);

    vm.expectRevert(
      abi.encodeWithSelector(RwaRegistry.UnsupportedParameter.selector, ilk_, bytes32("unexistingParameter"))
    );
    reg.file(ilk_, "unexistingParameter", "token", token_, variant_);
  }

  function testReverGetComponentAsTupleForUnexistingDeal() public {
    // bytes32 ilk_,
    // address token_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);
    uint256 variant_ = 0x2830;

    RwaRegistry.Component memory component = RwaRegistry.Component({name: "token", addr: token_, variant: variant_});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = component;
    reg.add(ilk_, components);

    bytes32 wrongIlk = "RWA2448-A";
    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealDoesNotExist.selector, wrongIlk));
    reg.getComponentTuple(wrongIlk, "token");
  }

  function testReverGetUnexistentComponentAsTupleForExistingDeal() public {
    // bytes32 ilk_,
    // address token_,
    // uint256 variant_

    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);
    uint256 variant_ = 0x2830;

    RwaRegistry.Component memory component = RwaRegistry.Component({name: "token", addr: token_, variant: variant_});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = component;
    reg.add(ilk_, components);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.ComponentDoesNotExist.selector, ilk_, bytes32("urn")));
    reg.getComponentTuple(ilk_, "urn");
  }

  function testRevertUnautorizedUpdateDeal() public {
    // address sender_,
    // bytes32 ilk_,
    // address token_

    // if (sender_ == address(this)) {
    //   return;
    // }

    address sender_ = address(0x1337);
    bytes32 ilk_ = "RWA1337-A";
    address token_ = address(0x2448);

    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = RwaRegistry.Component({name: "token", addr: token_, variant: 1});
    reg.add(ilk_, components);

    vm.expectRevert(RwaRegistry.Unauthorized.selector);
    vm.prank(sender_);

    reg.file(ilk_, "component", RwaRegistry.Component({name: "token", addr: address(0x1337), variant: 1337}));
  }

  function testFinalizeComponent() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    RwaRegistry.Component memory component = RwaRegistry.Component({name: "token", addr: address(0x1337), variant: 1});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = component;
    reg.add(ilk_, components);

    reg.finalize(ilk_);

    (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);

    assertEq(uint256(status), uint256(RwaRegistry.DealStatus.FINALIZED));
  }

  function testRevertFinalizeUnexistingComponent() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    RwaRegistry.Component memory component = RwaRegistry.Component({name: "token", addr: address(0x1337), variant: 1});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = component;
    reg.add(ilk_, components);

    bytes32 wrongIlk = "RWA2448-A";
    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealIsNotActive.selector, wrongIlk));
    reg.finalize(wrongIlk);
  }

  function testRevertUpdateFinalizedComponent() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    RwaRegistry.Component memory component = RwaRegistry.Component({name: "token", addr: address(0x1337), variant: 1});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = component;
    reg.add(ilk_, components);
    reg.finalize(ilk_);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealIsNotActive.selector, ilk_));
    reg.file(ilk_, "component", RwaRegistry.Component({name: "token", addr: address(0x2448), variant: 2}));
  }

  function testRevertUpdateFinalizedComponentAsTuple() public {
    // bytes32 ilk_

    bytes32 ilk_ = "RWA1337-A";

    RwaRegistry.Component memory component = RwaRegistry.Component({name: "token", addr: address(0x1337), variant: 1});
    RwaRegistry.Component[] memory components = new RwaRegistry.Component[](1);
    components[0] = component;
    reg.add(ilk_, components);
    reg.finalize(ilk_);

    vm.expectRevert(abi.encodeWithSelector(RwaRegistry.DealIsNotActive.selector, ilk_));
    reg.file(ilk_, "component", "token", address(0x2448), 2);
  }
}
