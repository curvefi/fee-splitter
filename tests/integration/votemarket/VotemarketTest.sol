// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../IntegrationTest.sol";

interface IStakeDaoLogic is IBribeLogic {
    function close_bounty(uint256 id, address receiver) external;
}

contract VotemarketTest is IntegrationTest {
    IStakeDaoLogic public stakeDaoLogic;
    IVotemarket public _vm;

    function setUp() public override {
        IntegrationTest.setUp();
        _vm = IVotemarket(0x000000073D065Fc33a3050C2d0E19C393a5699ba);
        bytes memory incentivesManagerArgs =
            abi.encode(address(crvUSD), bribeManager, bribeProposer, tokenRescuer, emergencyAdmin);
        im = IIncentivesManager(deployCode("IncentivesManager", incentivesManagerArgs));
        bytes memory stakeDaoLogicArgs = abi.encode(address(crvUSD), address(_vm), address(im));
        stakeDaoLogic = IStakeDaoLogic(deployCode("StakeDaoLogic", stakeDaoLogicArgs));
        vm.prank(bribeManager);
        im.set_bribe_logic(address(stakeDaoLogic));
    }
}
