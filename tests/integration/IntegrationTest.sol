// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import {Test, console} from "forge-std/Test.sol";

import {IERC20} from "forge-std/interfaces/IERC20.sol";

struct IncentivesPayload {
    address gauge;
    uint256 amount;
    bytes data;
}

contract IntegrationTest is Test {
    IERC20 crvUSD;
    address[] gauges;

    function setUp() public virtual {
        string memory rpc = vm.rpcUrl("mainnet");
        vm.createSelectFork(rpc, 20175100);

        crvUSD = IERC20(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E);
    }
}
