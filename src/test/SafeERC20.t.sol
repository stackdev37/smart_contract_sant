// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.9;

import {DSTestPlus} from "./utils/DSTestPlus.sol";

import {SafeERC20, ERC20 as SolmateERC20} from "../erc20/SafeERC20.sol";

import {ERC20} from "weird-erc20/ERC20.sol";
import {ReturnsFalseToken} from "weird-erc20/ReturnsFalse.sol";
import {MissingReturnToken} from "weird-erc20/MissingReturns.sol";
import {TransferFromSelfToken} from "weird-erc20/TransferFromSelf.sol";

contract SafeERC20Test is DSTestPlus {
    ReturnsFalseToken returnsFalse;
    MissingReturnToken missingReturn;
    TransferFromSelfToken transferFromSelf;

    ERC20 erc20;

    function setUp() public {
        returnsFalse = new ReturnsFalseToken(type(uint256).max);
        missingReturn = new MissingReturnToken(type(uint256).max);
        transferFromSelf = new TransferFromSelfToken(type(uint256).max);

        erc20 = new ERC20(type(uint256).max);
    }

    function testTransferWithMissingReturn() public {
        verifySafeTransfer(address(missingReturn), address(0xBEEF), 1e18);
    }

    function testTransferFromWithMissingReturn() public {
        verifySafeTransferFrom(address(missingReturn), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferWithTransferFromSelf() public {
        verifySafeTransfer(address(transferFromSelf), address(0xBEEF), 1e18);
    }

    function testTransferFromWithTransferFromSelf() public {
        verifySafeTransferFrom(address(transferFromSelf), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testTransferWithStandardERC20() public {
        verifySafeTransfer(address(erc20), address(0xBEEF), 1e18);
    }

    function testTransferFromWithStandardERC20() public {
        verifySafeTransferFrom(address(erc20), address(0xFEED), address(0xBEEF), 1e18);
    }

    function testFailTransferWithReturnsFalse() public {
        verifySafeTransfer(address(returnsFalse), address(0xBEEF), 1e18);
    }

    function testFailTransferFromWithReturnsFalse() public {
        verifySafeTransferFrom(address(returnsFalse), address(0xFEED), address(0xBEEF), 1e18);
    }

    function proveTransferWithMissingReturn(address to, uint256 amount) public {
        verifySafeTransfer(address(missingReturn), to, amount);
    }

    function proveTransferFromWithMissingReturn(
        address from,
        address to,
        uint256 amount
    ) public {
        verifySafeTransferFrom(address(missingReturn), from, to, amount);
    }

    function proveTransferWithTransferFromSelf(address to, uint256 amount) public {
        verifySafeTransfer(address(transferFromSelf), to, amount);
    }

    function proveTransferFromWithTransferFromSelf(
        address from,
        address to,
        uint256 amount
    ) public {
        verifySafeTransferFrom(address(transferFromSelf), from, to, amount);
    }

    function proveTransferWithStandardERC20(address to, uint256 amount) public {
        verifySafeTransfer(address(erc20), to, amount);
    }

    function proveTransferFromWithStandardERC20(
        address from,
        address to,
        uint256 amount
    ) public {
        verifySafeTransferFrom(address(erc20), from, to, amount);
    }

    function proveFailTransferWithReturnsFalse(address to, uint256 amount) public {
        verifySafeTransfer(address(returnsFalse), to, amount);
    }

    function proveFailTransferFromWithReturnsFalse(
        address from,
        address to,
        uint256 amount
    ) public {
        verifySafeTransferFrom(address(returnsFalse), from, to, amount);
    }

    function verifySafeTransfer(
        address token,
        address to,
        uint256 amount
    ) internal {
        uint256 preBal = ERC20(token).balanceOf(to);
        SafeERC20.safeTransfer(SolmateERC20(address(token)), to, amount);
        uint256 postBal = ERC20(token).balanceOf(to);

        if (to == address(this)) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function verifySafeTransferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        forceApprove(token, from, address(this), amount);
        SafeERC20.safeTransfer(SolmateERC20(token), from, amount);

        uint256 preBal = ERC20(token).balanceOf(to);
        SafeERC20.safeTransferFrom(SolmateERC20(token), from, to, amount);
        uint256 postBal = ERC20(token).balanceOf(to);

        if (from == to) {
            assertEq(preBal, postBal);
        } else {
            assertEq(postBal - preBal, amount);
        }
    }

    function forceApprove(
        address token,
        address from,
        address to,
        uint256 amount
    ) internal {
        uint256 slot = token == address(erc20) ? 3 : 2;
        hevm.store(
            token,
            keccak256(abi.encode(to, keccak256(abi.encode(from, uint256(slot))))),
            bytes32(uint256(amount))
        );
        assertEq(ERC20(token).allowance(from, to), amount, "wrong allowance");
    }
}
