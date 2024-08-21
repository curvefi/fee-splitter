// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../IntegrationTest.sol";
import {IQuest} from "./IQuest.sol";

interface IQuestLogic is IBribeLogic {
    function withdrawUnusedRewards(uint256 questID, address recipient) external;
    function questWithdrawableAmount(uint256 questID) external returns (uint256);
    function customPlatformFeeRatio(address creator) external view returns (uint256);
}

contract QuestTest is IntegrationTest {
    IQuestLogic public questLogic;
    IQuest public quest;

    function setUp() public override {
        IntegrationTest.setUp();
        quest = IQuest(0xAa1698f0A51e6d00F5533cc3E5D36010ee4558C6);
        bytes memory incentivesManagerArgs =
            abi.encode(address(crvUSD), bribeManager, bribeProposer, tokenRescuer, emergencyAdmin);
        im = IIncentivesManager(deployCode("IncentivesManager", incentivesManagerArgs));
        bytes memory questLogicArgs = abi.encode(address(crvUSD), address(quest), address(im));
        questLogic = IQuestLogic(deployCode("PaladinQuestLogic", questLogicArgs));
        vm.prank(bribeManager);
        im.set_bribe_logic(address(questLogic));
    }
}
