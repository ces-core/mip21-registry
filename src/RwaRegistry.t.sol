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

  function testShouldAddDefaultSupportedComponentsDuringDeployment() public {
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

  function testRevertUnautorizedAddressAddsSupportedComponent() public {
    vm.expectRevert(RwaRegistry.Unauthorized.selector);

    vm.prank(address(0x1337));
    reg.addSupportedComponent("anything");
  }
}
