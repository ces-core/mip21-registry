// SPDX-FileCopyrightText: © 2022 Dai Foundation <www.daifoundation.org>
// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.8.14;

import "forge-std/Script.sol";

import {ChainlogAbstract} from "dss-interfaces/dss/ChainlogAbstract.sol";
import {VatAbstract} from "dss-interfaces/dss/VatAbstract.sol";
import {IlkRegistryAbstract} from "dss-interfaces/dss/IlkRegistryAbstract.sol";
import {JugAbstract} from "dss-interfaces/dss/JugAbstract.sol";
import {SpotAbstract} from "dss-interfaces/dss/SpotAbstract.sol";
import {DaiAbstract} from "dss-interfaces/dss/DaiAbstract.sol";
import {RwaLiquidationOracleAbstract} from "dss-interfaces/dss/mip21/RwaLiquidationOracleAbstract.sol";
import {RwaTokenFactoryAbstract} from "dss-interfaces/dss/mip21/RwaTokenFactoryAbstract.sol";

import {RwaRegistry} from "../src/RwaRegistry.sol";

contract DeployRwaRegistry is Script {
    ChainlogAbstract internal chainlog;
    address internal mcdPauseProxy;
    address internal rwaLiquidationOracle;

    RwaRegistry internal reg;

    constructor() {
        chainlog = ChainlogAbstract(vm.envAddress("CHANGELOG"));
        mcdPauseProxy = chainlog.getAddress("MCD_PAUSE_PROXY");
        rwaLiquidationOracle = chainlog.getAddress("MIP21_LIQUIDATION_ORACLE");
    }

    function run() external returns (address) {
        vm.startBroadcast();

        reg = new RwaRegistry();

        _addRWA008A();
        _addRWA009A();

        reg.rely(mcdPauseProxy);
        reg.deny(msg.sender);

        vm.stopBroadcast();

        return address(reg);
    }

    function _addRWA001() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA001_A_URN");
        addrs[1] = chainlog.getAddress("RWA001_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA001_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = 1; // RwaOutputConduit
        variants[2] = 1; // RwaInputConduit
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA001", names, addrs, variants);
    }

    function _addRWA002() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA002_A_URN");
        addrs[1] = chainlog.getAddress("RWA002_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA002_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = type(uint8).max - 1; // TinlakeManager
        variants[2] = type(uint8).max - 1; // TinlakeManager
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA002", names, addrs, variants);
    }

    function _addRWA003() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA003_A_URN");
        addrs[1] = chainlog.getAddress("RWA003_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA003_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = type(uint8).max - 1; // TinlakeManager
        variants[2] = type(uint8).max - 1; // TinlakeManager
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA003", names, addrs, variants);
    }

    function _addRWA004() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA004_A_URN");
        addrs[1] = chainlog.getAddress("RWA004_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA004_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = type(uint8).max - 1; // TinlakeManager
        variants[2] = type(uint8).max - 1; // TinlakeManager
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA004", names, addrs, variants);
    }

    function _addRWA005() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA005_A_URN");
        addrs[1] = chainlog.getAddress("RWA005_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA005_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = type(uint8).max - 1; // TinlakeManager
        variants[2] = type(uint8).max - 1; // TinlakeManager
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA005", names, addrs, variants);
    }

    function _addRWA006() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA006_A_URN");
        addrs[1] = chainlog.getAddress("RWA006_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA006_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = type(uint8).max - 1; // TinlakeManager
        variants[2] = type(uint8).max - 1; // TinlakeManager
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA006", names, addrs, variants);
    }

    function _addRWA007() internal {
        bytes32[] memory names = new bytes32[](6);
        names[0] = URN;
        names[1] = JAR;
        names[2] = JAR_INPUT_CONDUIT;
        names[3] = OUTPUT_CONDUIT;
        names[4] = INPUT_CONDUIT;
        names[5] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](6);
        addrs[0] = chainlog.getAddress("RWA007_A_URN");
        addrs[1] = chainlog.getAddress("RWA007_A_JAR");
        addrs[2] = chainlog.getAddress("RWA007_A_JAR_INPUT_CONDUIT");
        addrs[3] = chainlog.getAddress("RWA007_A_OUTPUT_CONDUIT");
        addrs[4] = chainlog.getAddress("RWA007_A_INPUT_CONDUIT");
        addrs[5] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](6);
        variants[0] = 2; // RwaUrn2
        variants[1] = 1; // RwaJar
        variants[2] = 3; // RwaSwapInputConduit aka RwaInputConduit3
        variants[3] = 3; // RwaSwapOutputConduit aka RwaOutputConduit3
        variants[4] = 3; // RwaSwapInputConduit aka RwaInputConduit3
        variants[5] = 1; // RwaLiquidationOracle

        reg.add("RWA007", names, addrs, variants);
    }

    function _addRWA008() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA008_A_URN");
        addrs[1] = chainlog.getAddress("RWA008_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA008_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 2; // RwaUrn2
        variants[1] = 2; // RwaOutputConduit2
        variants[2] = 2; // RwaInputConduit2
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA008", names, addrs, variants);
    }

    function _addRWA009() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = JAR;
        names[2] = OUTPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA009_A_URN");
        addrs[1] = chainlog.getAddress("RWA009_A_JAR");
        addrs[2] = chainlog.getAddress("RWA009_A_OUTPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 2; // RwaUrn2
        variants[1] = 1; // RwaJar
        variants[2] = type(uint8).max; // Regular address
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA009", names, addrs, variants);
    }

    function _addRWA010() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA010_A_URN");
        addrs[1] = chainlog.getAddress("RWA010_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA010_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = type(uint8).max - 1; // TinlakeManager
        variants[2] = type(uint8).max - 1; // TinlakeManager
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA010", names, addrs, variants);
    }

    function _addRWA011() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA011_A_URN");
        addrs[1] = chainlog.getAddress("RWA011_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA011_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = type(uint8).max - 1; // TinlakeManager
        variants[2] = type(uint8).max - 1; // TinlakeManager
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA011", names, addrs, variants);
    }

    function _addRWA012() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA012_A_URN");
        addrs[1] = chainlog.getAddress("RWA012_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA012_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = type(uint8).max - 1; // TinlakeManager
        variants[2] = type(uint8).max - 1; // TinlakeManager
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA012", names, addrs, variants);
    }

    function _addRWA013() internal {
        bytes32[] memory names = new bytes32[](4);
        names[0] = URN;
        names[1] = OUTPUT_CONDUIT;
        names[2] = INPUT_CONDUIT;
        names[3] = LIQUIDATION_ORACLE;

        address[] memory addrs = new address[](4);
        addrs[0] = chainlog.getAddress("RWA013_A_URN");
        addrs[1] = chainlog.getAddress("RWA013_A_OUTPUT_CONDUIT");
        addrs[2] = chainlog.getAddress("RWA013_A_INPUT_CONDUIT");
        addrs[3] = rwaLiquidationOracle;

        uint256[] memory variants = new uint256[](4);
        variants[0] = 1; // RwaUrn
        variants[1] = type(uint8).max - 1; // TinlakeManager
        variants[2] = type(uint8).max - 1; // TinlakeManager
        variants[3] = 1; // RwaLiquidationOracle

        reg.add("RWA013", names, addrs, variants);
    }

    function _addGUSD() internal {
        bytes32[] memory names = new bytes32[](2);
        names[0] = JAR;
        names[1] = INPUT_CONDUIT;

        address[] memory addrs = new address[](2);
        addrs[0] = address(0xf2E7a5B83525c3017383dEEd19Bb05Fe34a62C27); // GUSD_A_JAR
        addrs[1] = address(0x6934218d8B3E9ffCABEE8cd80F4c1C4167Afa638); // GUSD_A_JAR_INPUT_CONDUIT

        uint256[] memory variants = new uint256[](2);
        variants[0] = 1; // RwaJar
        variants[1] = 4; // RwaSwapInputConduit2

        reg.add("GUSD", names, addrs, variants);
    }

    bytes32 internal constant URN = "urn";
    bytes32 internal constant JAR = "jar";
    bytes32 internal constant JAR_INPUT_CONDUIT = "jarInputConduit";
    bytes32 internal constant OUTPUT_CONDUIT = "outputConduit";
    bytes32 internal constant INPUT_CONDUIT = "inputConduit";
    bytes32 internal constant LIQUIDATION_ORACLE = "liquidationOracle";
}
