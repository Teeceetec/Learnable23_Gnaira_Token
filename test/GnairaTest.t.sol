// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Gnaira} from "../src/Gnaira.sol";
import {DeployGnaira} from "../script/DeployGnaira.s.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

contract GnairaTest is StdCheats, Test {
    DeployGnaira deployer;
    Gnaira public gnaira;

    string constant TOKEN_NAME = "GNAIRA";
    string constant TOKEN_SYMBOL = "GN";
    address public USER = makeAddr("user");
    uint256 public constant AMOUNT = 10 ether;
    address public USER2 = makeAddr("user2");
    address public USER3 = makeAddr("user3");
    address public USER4 = makeAddr("user4");
    address public USER5 = makeAddr("user5");
    address public USER6 = makeAddr("user6");
    uint256 public constant amountMint = 1000000 * 10 * 18;
    uint256 public constant required = 3;
    address[] public members;

    function setUp() public {
        members = [USER2, USER3, USER4];

        gnaira = new Gnaira(members, required);
        vm.deal(USER, AMOUNT);
    }

    function testNameIsCorrect() public view {
        assert(keccak256(abi.encodePacked(TOKEN_NAME)) == keccak256(abi.encodePacked(gnaira.name())));

        console.log(TOKEN_NAME);
        console.log(gnaira.name());
    }

    function testSymbolIsCorrect() public view {
        assert(keccak256(abi.encodePacked(gnaira.symbol())) == keccak256(abi.encodePacked(TOKEN_SYMBOL)));
        assertEq(gnaira.totalSupply(), 1000000);

        console.log(TOKEN_SYMBOL);
        console.log(gnaira.symbol());
    }

    function testTotalSupply() public view {
        uint256 amount = 1000000;
        uint256 supply = gnaira.totalSupply();
        assertEq(supply, amount);
    }

    function testBlackList() public {
        vm.startPrank(gnaira.getGovernor());
        gnaira.blacklist(USER2);
        vm.stopPrank();

        assert(gnaira.isBlacklisted(USER2) == true);
    }

    function testRemoveBlacklisted() public {
        vm.startPrank(gnaira.getGovernor());
        gnaira.blacklist(USER3);
        gnaira.removeFromBlackList(USER3);
        vm.stopPrank();

        assert(gnaira.isBlacklisted(USER3) == false);
    }

    function testMintingFailed() public {
        vm.expectRevert();
        gnaira.multiSigMint(USER5, 200);
    }

    function testConstructorMinting() public {
        members = [USER, USER2, USER3];
        vm.startBroadcast();
        gnaira = new Gnaira(members, required);
        vm.stopBroadcast();
    }

    function testAddOwner() public {
        vm.startPrank(USER2);
        gnaira.addOwner(USER5);
        vm.stopPrank();
        assertEq(gnaira.isOwnersT(USER5), true);
        assert(gnaira.getRequiredNumberOfApproval() > 1);
    }

    function testRemoveOwner() public {
        vm.startPrank(USER2);
        gnaira.addOwner(USER5);
        gnaira.removeOwner(USER5);
        vm.stopPrank();
        assertEq(gnaira.isOwnersT(USER5), false);
        assert(gnaira.getRequiredNumberOfApproval() <= 3);
    }

    function testChangeRequirementFail() public {
        vm.expectRevert();
        gnaira.changeRequirement(6);
    }

    modifier minted() {
        vm.startPrank(gnaira.getGovernor());
        gnaira.mint(USER5, 1000);
        vm.stopPrank();
        _;
    }

    function testTransferToken() public minted {
        vm.startPrank(USER5);
        gnaira.transfer(USER6, 500);
        gnaira.isBlacklisted(USER5);
        gnaira.isBlacklisted(USER6);
        vm.stopPrank();
        assert(gnaira.balanceOf(USER6) == 500);
        uint256 supply = gnaira.getTotalSupply();
        console.log(supply);
    }

    function testConfirmation() public {
        vm.startPrank(USER2);
        gnaira.confirmTransaction();
        vm.stopPrank();
        assertEq(gnaira.confirmations(members[0]), true);
    }

    function testrevokeConfirmation() public {
        vm.startPrank(USER2);
        gnaira.confirmTransaction();
        gnaira.revokeConfirmation();
        vm.stopPrank();
        assertEq(gnaira.confirmations(members[0]), false);
    }

    function testMintingLogic() public {
        vm.startPrank(gnaira.getGovernor());
        gnaira.mint(USER5, 500);
        vm.stopPrank();
        assert(gnaira.balanceOf(USER5) == 500);
    }

    function testBurnLogic() public {
        vm.startPrank(gnaira.getGovernor());
        gnaira.mint(USER5, 600);
        gnaira.burn(USER5, 300);
        uint256 balance = gnaira.balanceOf(USER5);
        vm.stopPrank();
        assert(balance == 300);
    }

    modifier ownersConfirmation1() {
        vm.startPrank(USER2);
        gnaira.confirmTransaction();
        vm.stopPrank();

        _;
    }

    modifier ownersConfirmation2() {
        vm.startPrank(USER3);
        gnaira.confirmTransaction();
        vm.stopPrank();

        _;
    }

    modifier ownersConfirmation3() {
        vm.startPrank(USER4);
        gnaira.confirmTransaction();
        vm.stopPrank();

        _;
    }

    function testMultiSigMint() public ownersConfirmation1 ownersConfirmation2 ownersConfirmation3 {
        vm.startPrank(USER2);
        gnaira.multiSigMint(USER5, 500);
        vm.stopPrank();
        assertEq(gnaira.balanceOf(USER5), 500);
    }

    function testMultiSigBurn() public ownersConfirmation1 ownersConfirmation2 ownersConfirmation3 {
        vm.startPrank(USER2);
        gnaira.multiSigMint(USER5, 500);
        gnaira.multiSigBurn(USER5, 400);
        uint256 amount = gnaira.balanceOf(USER5);
        vm.stopPrank();

        assertEq(amount, 100);
    }

    function testRevertBlacklist() public {
        vm.expectRevert(Gnaira.ADDRESS_NOT_IN_BLACKLIST.selector);
        gnaira.removeFromBlackList(USER5);
    }

    function testRevertBurn() public {
        vm.expectRevert();
        gnaira.multiSigBurn(USER5, 300);
    }

    function testRevertMint() public {
        vm.expectRevert();
        gnaira.multiSigMint(USER6, 400);
    }

    function testChangeRequirement() public {
        vm.startPrank(USER2);
        gnaira.changeRequirement(2);
        vm.stopPrank();
        assert(gnaira.s_required() == 2);
    }

    function testNewGovernor() public {
        vm.startPrank(USER);
        gnaira.changeGovernor(USER5);
        vm.stopPrank();

        assert(USER5 == gnaira.getGovernor());
    }
}
