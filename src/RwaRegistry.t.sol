// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: AGPL-3.0-or-later

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

    function testWardsSlot0x0() public {
        // Load memory slot 0x0
        bytes32 rWards = vm.load(address(reg), keccak256(abi.encode(address(this), uint256(0))));

        // reg wards
        assertEq(reg.wards(address(this)), uint256(rWards)); // Assert wards = slot wards
        assertEq(uint256(rWards), 1); // Assert slot wards == 1
    }

    function testRely() public {
        vm.expectEmit(true, false, false, false);
        emit Rely(address(0x1337));

        reg.rely(address(0x1337));

        assertEq(reg.wards(address(0x1337)), 1);
    }

    function testDeny() public {
        vm.expectEmit(true, false, false, false);
        emit Deny(address(this));

        reg.deny(address(this));

        assertEq(reg.wards(address(this)), 0);
    }

    /*//////////////////////////////////
        Supported Components Management
    //////////////////////////////////*/

    function testAddDefaultSupportedComponentsDuringDeployment() public {
        assertEq(reg.listSupportedComponents().length, 6);
        assertEq(reg.isSupportedComponent("urn"), true);
        assertEq(reg.isSupportedComponent("liquidationOracle"), true);
        assertEq(reg.isSupportedComponent("outputConduit"), true);
        assertEq(reg.isSupportedComponent("inputConduit"), true);
        assertEq(reg.isSupportedComponent("jar"), true);
        assertEq(reg.isSupportedComponent("jarInputConduit"), true);
    }

    function testAddSupportedComponent() public {
        vm.expectEmit(true, false, false, false);
        emit AddSupportedComponent("somethingElse");

        reg.addSupportedComponent("somethingElse");

        assertEq(reg.isSupportedComponent("somethingElse"), true);
    }

    function testRevertAddExistingSupportedComponent() public {
        bytes32 componentName_ = "anything";
        reg.addSupportedComponent(componentName_);

        vm.expectRevert("RwaRegistry/component-already-supported");
        reg.addSupportedComponent(componentName_);
    }

    function testRevertUnautorizedAddSupportedComponent() public {
        address sender_ = address(0x1337);

        vm.expectRevert("RwaRegistry/not-authorized");
        vm.prank(sender_);

        reg.addSupportedComponent("anything");
    }

    /*//////////////////////////////////
        Deals & Components Management
    //////////////////////////////////*/

    function testAddDealAndComponents() public {
        bytes32 ilk_ = "RWA1337-a";
        address urn_ = address(0x2448);
        address liquidationOracle_ = address(0x3559);
        address outputConduit_ = address(0x466a);
        address inputConduit_ = address(0x577b);
        address jar_ = address(0x688c);

        bytes32[] memory names = new bytes32[](5);
        names[0] = "urn";
        names[1] = "liquidationOracle";
        names[2] = "outputConduit";
        names[3] = "inputConduit";
        names[4] = "jar";

        address[] memory addrs = new address[](5);
        addrs[0] = urn_;
        addrs[1] = liquidationOracle_;
        addrs[2] = outputConduit_;
        addrs[3] = inputConduit_;
        addrs[4] = jar_;

        uint8[] memory variants = new uint8[](5);
        variants[0] = 1;
        variants[1] = 1;
        variants[2] = 1;
        variants[3] = 1;
        variants[4] = 1;

        vm.expectEmit(true, false, false, false);
        emit AddDeal(ilk_);

        for (uint256 i = 0; i < names.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit SetComponent(ilk_, names[i], addrs[i], variants[i]);
        }

        reg.add(ilk_, names, addrs, variants);

        (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
        (bytes32[] memory actualNames, address[] memory actualAddrs, uint8[] memory actualVariants) = reg
            .listComponents(ilk_);

        assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));

        assertEq(actualNames[0], names[0], "Component mismatch: urn");
        assertEq(actualNames[1], names[1], "Component mismatch: liquidationOracle");
        assertEq(actualNames[2], names[2], "Component mismatch: outputConduit");
        assertEq(actualNames[3], names[3], "Component mismatch: inputConduit");
        assertEq(actualNames[4], names[4], "Component mismatch: jar");

        assertEq(actualAddrs[0], addrs[0], "Component address mismatch: urn");
        assertEq(actualAddrs[1], addrs[1], "Component address mismatch: liquidationOracle");
        assertEq(actualAddrs[2], addrs[2], "Component address mismatch: outputConduit");
        assertEq(actualAddrs[3], addrs[3], "Component address mismatch: inputConduit");
        assertEq(actualAddrs[4], addrs[4], "Component address mismatch: jar");

        assertEq(actualVariants[0], variants[0], "Component variant mismatch: urn");
        assertEq(actualVariants[1], variants[1], "Component variant mismatch: liquidationOracle");
        assertEq(actualVariants[2], variants[2], "Component variant mismatch: outputConduit");
        assertEq(actualVariants[3], variants[3], "Component variant mismatch: inputConduit");
        assertEq(actualVariants[4], variants[4], "Component variant mismatch: jar");
    }

    function testIterateOverDealComponentNames() public {
        bytes32 ilk_ = "RWA1337-a";
        address urn_ = address(0x2448);
        address liquidationOracle_ = address(0x3559);
        address outputConduit_ = address(0x466a);
        address inputConduit_ = address(0x577b);
        address jar_ = address(0x688c);

        bytes32[] memory names = new bytes32[](5);
        names[0] = "urn";
        names[1] = "liquidationOracle";
        names[2] = "outputConduit";
        names[3] = "inputConduit";
        names[4] = "jar";

        address[] memory addrs = new address[](5);
        addrs[0] = urn_;
        addrs[1] = liquidationOracle_;
        addrs[2] = outputConduit_;
        addrs[3] = inputConduit_;
        addrs[4] = jar_;

        uint8[] memory variants = new uint8[](5);
        variants[0] = 1;
        variants[1] = 1;
        variants[2] = 1;
        variants[3] = 1;
        variants[4] = 1;

        vm.expectEmit(true, false, false, false);
        emit AddDeal(ilk_);

        for (uint256 i = 0; i < names.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit SetComponent(ilk_, names[i], addrs[i], variants[i]);
        }

        reg.add(ilk_, names, addrs, variants);

        (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
        bytes32[] memory actualNames = reg.iterComponentNames(ilk_, 1, 3);

        assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));

        assertEq(actualNames[0], names[1], "Component mismatch: liquidationOracle");
        assertEq(actualNames[1], names[2], "Component mismatch: outputConduit");
    }

    function testIterateOverDealComponents() public {
        bytes32 ilk_ = "RWA1337-a";
        address urn_ = address(0x2448);
        address liquidationOracle_ = address(0x3559);
        address outputConduit_ = address(0x466a);
        address inputConduit_ = address(0x577b);
        address jar_ = address(0x688c);

        bytes32[] memory names = new bytes32[](5);
        names[0] = "urn";
        names[1] = "liquidationOracle";
        names[2] = "outputConduit";
        names[3] = "inputConduit";
        names[4] = "jar";

        address[] memory addrs = new address[](5);
        addrs[0] = urn_;
        addrs[1] = liquidationOracle_;
        addrs[2] = outputConduit_;
        addrs[3] = inputConduit_;
        addrs[4] = jar_;

        uint8[] memory variants = new uint8[](5);
        variants[0] = 1;
        variants[1] = 1;
        variants[2] = 1;
        variants[3] = 1;
        variants[4] = 1;

        vm.expectEmit(true, false, false, false);
        emit AddDeal(ilk_);

        for (uint256 i = 0; i < names.length; i++) {
            vm.expectEmit(true, true, true, true);
            emit SetComponent(ilk_, names[i], addrs[i], variants[i]);
        }

        reg.add(ilk_, names, addrs, variants);

        (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
        (bytes32[] memory actualNames, address[] memory actualAddrs, uint8[] memory actualVariants) = reg
            .iterComponents(ilk_, 1, 3);

        assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));

        assertEq(actualNames[0], names[1], "Component mismatch: liquidationOracle");
        assertEq(actualNames[1], names[2], "Component mismatch: outputConduit");

        assertEq(actualAddrs[0], addrs[1], "Component address mismatch: liquidationOracle");
        assertEq(actualAddrs[1], addrs[2], "Component address mismatch: outputConduit");

        assertEq(actualVariants[0], variants[1], "Component variant mismatch: liquidationOracle");
        assertEq(actualVariants[1], variants[2], "Component variant mismatch: outputConduit");
    }

    function testRevertAddDealWithUnsupportedComponent() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x1337);
        address someAddr_ = address(0x2448);

        bytes32[] memory names = new bytes32[](5);
        names[0] = "urn";
        names[1] = "something";

        address[] memory addrs = new address[](5);
        addrs[0] = urn_;
        addrs[1] = someAddr_;

        uint8[] memory variants = new uint8[](5);
        variants[0] = 1;
        variants[1] = 1;

        vm.expectRevert("RwaRegistry/unsupported-component");
        reg.add(ilk_, names, addrs, variants);
    }

    function testRevertAddDealWithComponentWithInvalidAddress() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0);

        bytes32[] memory names = new bytes32[](1);
        names[0] = "urn";

        address[] memory addrs = new address[](1);
        addrs[0] = urn_;

        uint8[] memory variants = new uint8[](1);
        variants[0] = 1;

        vm.expectRevert("RwaRegistry/invalid-component-addr");
        reg.add(ilk_, names, addrs, variants);
    }

    function testRevertAddDealWithComponentsWithMismatchingParams() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x1337);
        address liquidationOracle_ = address(0x2448);

        bytes32[] memory names = new bytes32[](1);
        names[0] = "urn";

        address[] memory addrs = new address[](2);
        addrs[0] = urn_;
        addrs[1] = liquidationOracle_;

        uint8[] memory variants = new uint8[](2);
        variants[0] = 1;
        variants[1] = 1;

        vm.expectRevert("RwaRegistry/mismatching-component-params");
        reg.add(ilk_, names, addrs, variants);
    }

    function testRevertListComponentsUnexistingDeal() public {
        bytes32 ilk_ = "RWA1337-A";

        vm.expectRevert("RwaRegistry/invalid-deal");
        reg.listComponents(ilk_);
    }

    function testRemoveDeal() public {
        bytes32 ilk_ = "RWA1337-A";

        bytes32[] memory names;
        address[] memory addrs;
        uint8[] memory variants;
        reg.add(ilk_, names, addrs, variants);

        (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);

        assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));

        reg.remove(ilk_);

        (RwaRegistry.DealStatus status_, ) = reg.ilkToDeal(ilk_);

        assertEq(uint256(status_), uint256(RwaRegistry.DealStatus.NONE));
        assertEq(reg.count(), 0, "Deal was not removed");
    }

    function testRevertRemoveWithDanglingComponentsDeal() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x1337);
        address liquidationOracle_ = address(0x2448);

        bytes32[] memory names = new bytes32[](2);
        names[0] = "urn";
        names[1] = "liquidationOracle";

        address[] memory addrs = new address[](2);
        addrs[0] = urn_;
        addrs[1] = liquidationOracle_;

        uint8[] memory variants = new uint8[](2);
        variants[0] = 1;
        variants[1] = 1;

        reg.add(ilk_, names, addrs, variants);

        (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);

        assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));

        vm.expectRevert("RwaRegistry/deal-dangling-components");
        reg.remove(ilk_);
    }

    function testAddDealWithEmptyComponentList() public {
        bytes32 ilk_ = "RWA1337-A";

        bytes32[] memory names;
        address[] memory addrs;
        uint8[] memory variants;
        reg.add(ilk_, names, addrs, variants);

        (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);
        (bytes32[] memory actualNames, address[] memory actualAddrs, uint8[] memory actualVariants) = reg
            .listComponents(ilk_);

        assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));
        assertEq(actualNames.length, 0, "Name list is not empty");
        assertEq(actualAddrs.length, 0, "Address list is not empty");
        assertEq(actualVariants.length, 0, "Variant list is not empty");
    }

    function testCountDealComponents() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x1337);
        address liquidationOracle_ = address(0x2448);

        bytes32[] memory originalNames = new bytes32[](2);
        address[] memory originalAddrs = new address[](2);
        uint8[] memory originalVariants = new uint8[](2);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        originalNames[1] = "liquidationOracle";
        originalAddrs[1] = liquidationOracle_;
        originalVariants[1] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);

        assertEq(reg.countComponents(ilk_), originalNames.length);
    }

    function testListAllDealComponentNames() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x1337);
        address liquidationOracle_ = address(0x2448);

        bytes32[] memory originalNames = new bytes32[](2);
        address[] memory originalAddrs = new address[](2);
        uint8[] memory originalVariants = new uint8[](2);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        originalNames[1] = "liquidationOracle";
        originalAddrs[1] = liquidationOracle_;
        originalVariants[1] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);

        bytes32[] memory actualNames = reg.listComponentNames(ilk_);

        assertEq(actualNames[0], originalNames[0]);
        assertEq(actualNames[1], originalNames[1]);
    }

    function testRevertListComponentNamesUnexistingDeal() public {
        bytes32 ilk_ = "RWA1337-A";

        vm.expectRevert("RwaRegistry/invalid-deal");
        reg.listComponentNames(ilk_);
    }

    function testAddDealWithNoComponents() public {
        bytes32 ilk_ = "RWA1337-A";

        reg.add(ilk_);

        (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);

        (bytes32[] memory names, address[] memory addrs, uint8[] memory variants) = reg.listComponents(ilk_);

        assertEq(uint256(status), uint256(RwaRegistry.DealStatus.ACTIVE));
        assertEq(names.length, 0, "Name list is not empty");
        assertEq(addrs.length, 0, "Address list is not empty");
        assertEq(variants.length, 0, "Variant list is not empty");
    }

    function testRevertAddExistingDeal() public {
        bytes32 ilk_ = "RWA1337-A";
        reg.add(ilk_);

        vm.expectRevert("RwaRegistry/deal-already-exists");
        reg.add(ilk_);
    }

    function testRevertUnautorizedAddDeal() public {
        address sender_ = address(0x1337);
        bytes32 ilk_ = "RWA1337-A";

        vm.expectRevert("RwaRegistry/not-authorized");
        vm.prank(sender_);

        reg.add(ilk_);
    }

    function testListAllDealIlks() public {
        bytes32 ilk0_ = "RWA1337-A";
        bytes32 ilk1_ = "RWA2448-A";

        reg.add(ilk0_);
        reg.add(ilk1_);

        assertTrue(reg.has(ilk0_));
        assertTrue(reg.has(ilk1_));

        bytes32[] memory actualIlks = reg.list();

        assertEq(actualIlks[0], ilk0_);
        assertEq(actualIlks[1], ilk1_);
    }

    function testCountAllDealIlks() public {
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
        assertEq(count, expected, "Wrong count");
    }

    function testSetPosToIlkReverseMapping() public {
        bytes32[] memory ilks_ = new bytes32[](3);
        ilks_[0] = "RWA1337-A";
        ilks_[1] = "RWA2448-A";
        ilks_[2] = "RWA3559-A";

        for (uint256 i = 0; i < ilks_.length; i++) {
            reg.add(ilks_[i]);
        }

        assertEq(reg.posToIlk(0), ilks_[0], "Invalid ilk pos: 0");
        assertEq(reg.posToIlk(1), ilks_[1], "Invalid ilk pos: 1");
        assertEq(reg.posToIlk(2), ilks_[2], "Invalid ilk pos: 2");
    }

    function testIterDealIlksWithinBounds() public {
        bytes32[] memory ilks_ = new bytes32[](4);
        ilks_[0] = "RWA1337-A";
        ilks_[1] = "RWA2448-A";
        ilks_[2] = "RWA3559-A";
        ilks_[3] = "RWA4660-A";

        for (uint256 i = 0; i < ilks_.length; i++) {
            reg.add(ilks_[i]);
        }

        bytes32[] memory actualIlks = reg.iter(1, 3);

        assertEq(actualIlks.length, 2, "Wrong count");
        assertEq(actualIlks[0], ilks_[1], "Wrong element at pos: 0");
        assertEq(actualIlks[1], ilks_[2], "Wrong element at pos: 1");
    }

    function testIterDealIlksEndOutBounds() public {
        bytes32[] memory ilks_ = new bytes32[](4);
        ilks_[0] = "RWA1337-A";
        ilks_[1] = "RWA2448-A";
        ilks_[2] = "RWA3559-A";
        ilks_[3] = "RWA4660-A";

        for (uint256 i = 0; i < ilks_.length; i++) {
            reg.add(ilks_[i]);
        }

        bytes32[] memory actualIlks = reg.iter(1, 10);

        // We are starting form index 1, so there will be only 3 elements in the array
        assertEq(actualIlks.length, 3, "Wrong count");
        assertEq(actualIlks[0], ilks_[1], "Wrong element at pos: 0");
        assertEq(actualIlks[1], ilks_[2], "Wrong element at pos: 1");
        assertEq(actualIlks[2], ilks_[3], "Wrong element at pos: 2");
    }

    function testIterDealIlksFromZeroToLargeNumberIsEquivalentToList() public {
        bytes32[] memory ilks_ = new bytes32[](4);
        ilks_[0] = "RWA1337-A";
        ilks_[1] = "RWA2448-A";
        ilks_[2] = "RWA3559-A";
        ilks_[3] = "RWA4660-A";

        for (uint256 i = 0; i < ilks_.length; i++) {
            reg.add(ilks_[i]);
        }

        bytes32[] memory iterIlks = reg.iter(0, 10);
        bytes32[] memory listIlks = reg.list();

        assertEq(abi.encodePacked(iterIlks), abi.encodePacked(listIlks), "Lists are not equal");
    }

    function testIterDealIlksEmptyIterationParams() public {
        bytes32[] memory ilks_ = new bytes32[](4);
        ilks_[0] = "RWA1337-A";
        ilks_[1] = "RWA2448-A";
        ilks_[2] = "RWA3559-A";
        ilks_[3] = "RWA4660-A";

        for (uint256 i = 0; i < ilks_.length; i++) {
            reg.add(ilks_[i]);
        }

        bytes32[] memory iterIlks = reg.iter(0, 0);

        assertEq(iterIlks.length, 0, "Should return an empty list");
    }

    function testReverIterDealIlksInvalidIterationParams() public {
        bytes32[] memory ilks_ = new bytes32[](4);
        ilks_[0] = "RWA1337-A";
        ilks_[1] = "RWA2448-A";
        ilks_[2] = "RWA3559-A";
        ilks_[3] = "RWA4660-A";

        for (uint256 i = 0; i < ilks_.length; i++) {
            reg.add(ilks_[i]);
        }

        vm.expectRevert("RwaRegistry/invalid-iteration");
        reg.iter(10, 0);
    }

    function testReverIterDealIlksStartIsOutBounds() public {
        bytes32[] memory ilks_ = new bytes32[](4);
        ilks_[0] = "RWA1337-A";
        ilks_[1] = "RWA2448-A";
        ilks_[2] = "RWA3559-A";
        ilks_[3] = "RWA4660-A";

        for (uint256 i = 0; i < ilks_.length; i++) {
            reg.add(ilks_[i]);
        }

        vm.expectRevert("RwaRegistry/invalid-iteration");
        reg.iter(5, 10);
    }

    function testAddNewComponentToDeal() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x3549);
        uint8 variant_ = 0x28;
        reg.add(ilk_);

        reg.setComponent(ilk_, "urn", urn_, variant_);

        assertTrue(reg.hasComponent(ilk_, "urn"));
        (address addr, uint8 variant) = reg.getComponent(ilk_, "urn");
        assertEq(addr, urn_, "Component address mismatch");
        assertEq(variant, variant_, "Component variant mismatch");
    }

    function testUpdateDealComponent() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x3549);

        bytes32[] memory originalNames = new bytes32[](1);
        address[] memory originalAddrs = new address[](1);
        uint8[] memory originalVariants = new uint8[](1);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);

        uint8 variant_ = 0x28;
        reg.setComponent(ilk_, "urn", urn_, variant_);

        (, uint8 updatedVariant) = reg.getComponent(ilk_, "urn");
        assertEq(updatedVariant, variant_, "Component variant mismatch");
    }

    function testRemoveDealComponent() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x3549);

        bytes32[] memory originalNames = new bytes32[](1);
        address[] memory originalAddrs = new address[](1);
        uint8[] memory originalVariants = new uint8[](1);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);

        reg.removeComponent(ilk_, "urn");

        vm.expectRevert(abi.encodePacked("RwaRegistry/invalid-component-", bytes32("urn")));
        reg.getComponent(ilk_, "urn");

        assertEq(reg.listComponentNames(ilk_).length, 0);
    }

    function testReverGetComponentForUnexistingDeal() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x3549);
        bytes32[] memory originalNames = new bytes32[](1);
        address[] memory originalAddrs = new address[](1);
        uint8[] memory originalVariants = new uint8[](1);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);

        bytes32 wrongIlk = "RWA2448-A";
        vm.expectRevert("RwaRegistry/invalid-deal");
        reg.getComponent(wrongIlk, "urn");
    }

    function testRevertGetUnexistentComponentForExistingDeal() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x3549);
        bytes32[] memory originalNames = new bytes32[](1);
        address[] memory originalAddrs = new address[](1);
        uint8[] memory originalVariants = new uint8[](1);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);

        vm.expectRevert(abi.encodePacked("RwaRegistry/invalid-component-", bytes32("liquidationOracle")));
        reg.getComponent(ilk_, "liquidationOracle");
    }

    function testRevertUnautorizedUpdateDeal() public {
        address sender_ = address(0x1337);
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x3549);
        bytes32[] memory originalNames = new bytes32[](1);
        address[] memory originalAddrs = new address[](1);
        uint8[] memory originalVariants = new uint8[](1);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);

        vm.expectRevert("RwaRegistry/not-authorized");
        vm.prank(sender_);

        reg.setComponent(ilk_, "urn", address(0x1337), 133);
    }

    function testFinalizeComponent() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x3549);
        bytes32[] memory originalNames = new bytes32[](1);
        address[] memory originalAddrs = new address[](1);
        uint8[] memory originalVariants = new uint8[](1);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);

        vm.expectEmit(true, false, false, false);
        emit FinalizeDeal(ilk_);

        reg.finalize(ilk_);

        (RwaRegistry.DealStatus status, ) = reg.ilkToDeal(ilk_);

        assertEq(uint256(status), uint256(RwaRegistry.DealStatus.FINALIZED));
    }

    function testRevertFinalizeUnexistingComponent() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x3549);
        bytes32[] memory originalNames = new bytes32[](1);
        address[] memory originalAddrs = new address[](1);
        uint8[] memory originalVariants = new uint8[](1);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);

        bytes32 wrongIlk = "RWA2448-A";
        vm.expectRevert("RwaRegistry/deal-not-active");
        reg.finalize(wrongIlk);
    }

    function testRevertUpdateFinalizedComponent() public {
        bytes32 ilk_ = "RWA1337-A";
        address urn_ = address(0x3549);
        bytes32[] memory originalNames = new bytes32[](1);
        address[] memory originalAddrs = new address[](1);
        uint8[] memory originalVariants = new uint8[](1);
        originalNames[0] = "urn";
        originalAddrs[0] = urn_;
        originalVariants[0] = 1;
        reg.add(ilk_, originalNames, originalAddrs, originalVariants);
        reg.finalize(ilk_);

        vm.expectRevert("RwaRegistry/deal-not-active");
        reg.setComponent(ilk_, "urn", address(0x2448), 2);
    }

    event Rely(address indexed usr);
    event Deny(address indexed usr);
    event SetComponent(bytes32 indexed ilk, bytes32 indexed name, address addr, uint8 variant);
    event AddDeal(bytes32 indexed ilk);
    event FinalizeDeal(bytes32 indexed ilk);
    event AddSupportedComponent(bytes32 indexed component);
}
