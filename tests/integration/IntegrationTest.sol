// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";

import {IVotemarket} from "./IVotemarket.sol";
import {ICrvUSD} from "./ICrvUSD.sol";

interface IIncentivesManager {
    function set_bribe_logic(address logic) external;
    function set_gauge_cap(address gauge, uint256 cap) external;
    function post_bribe(address gauge, uint256 amount, bytes calldata data) external;
}

interface IStakeDaoLogic {
    function bribe(address gauge, uint256 amount, bytes memory data) external;
}

contract IntegrationTest is Test {
    // TODO 0.8.23 might fix this
    event BountyCreated(
        uint256 indexed id,
        address indexed gauge,
        address manager,
        address rewardToken,
        uint8 numberOfPeriods,
        uint256 maxRewardPerVote,
        uint256 rewardPerPeriod,
        uint256 totalRewardAmount,
        bool isUpgradeable
    );
    event BountyDurationIncrease(
        uint256 id, uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote
    );
    event BountyDurationIncreaseQueued(
        uint256 id, uint8 numberOfPeriods, uint256 totalRewardAmount, uint256 maxRewardPerVote
    );

    address public bribeManager;
    address public bribePoster;
    address public tokenRescuer;
    address public emergencyAdmin;

    IIncentivesManager public im;
    IStakeDaoLogic public stakeDaoLogic;
    IVotemarket public _vm;
    ICrvUSD crvUSD;
    address[] gauges; 

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/eth");

        bribeManager = makeAddr("BRIBE_MANAGER");
        bribePoster = makeAddr("BRIBE_POSTER");
        tokenRescuer = makeAddr("TOKEN_RESCUER");
        emergencyAdmin = makeAddr("EMERGENCY_ADMIN");

        gauges.push(0x76f236A0Cc1C90425D8Ab5F042970454311482AB);
        gauges.push(0x4e6bB6B7447B7B2Aa268C16AB87F4Bb48BF57939);
        gauges.push(0x95f00391cB5EebCd190EB58728B4CE23DbFa6ac1);
        gauges.push(0xaA8B8643a29cECB5de7B4ea115D04384C041423F);
        gauges.push(0x4717C25df44e280ec5b31aCBd8C194e1eD24efe2);
        gauges.push(0x8D867BEf70C6733ff25Cc0D1caa8aA6c38B24817);
        gauges.push(0xf69Fb60B79E463384b40dbFDFB633AB5a863C9A2);
        gauges.push(0x96424E6b5eaafe0c3B36CA82068d574D44BE4e3c);
        gauges.push(0x0e5bdb5afe132D1c6A6C67f6D8eB6133dD607e36);
        gauges.push(0x60d3d7eBBC44Dc810A743703184f062d00e6dB7e);
        gauges.push(0x94E4fd3747dCD100D333E896D7352C5FbCCF4cE7);
        gauges.push(0xB1A829a05E618F7C4f50Cb86f8F64Fb86e42dE5a);
        gauges.push(0x296Cb319665031Ac9E40b373d0C84e7D5fdAB80d);
        gauges.push(0xb901a92F2c385AfA0A019e8A307a59A570239ca4);
        gauges.push(0x2DD2b7E07dD433B758B98A3889a63cbF48ef0D99);
        gauges.push(0xEcAD6745058377744c09747b2715c0170B5699e5);
        gauges.push(0xa5Dc66685bD13A0924505807c29F8C65dDa0d207);
        gauges.push(0x5c07440a172805d566Faf7eBAf16EF068aC05f43);
        gauges.push(0xDe14d2B848a7a1373E155Cc4db9B649f4BE24296);
        gauges.push(0x512a68DD5433563Bad526C8C2838c39deBc9a756);
        gauges.push(0x66F65323bdE835B109A92045Aa7c655559dbf863);
        gauges.push(0x5C5db6CC20Cd2Ee600647FC48C1684c7049cdb7C);
        gauges.push(0x390C6eB1E824A7CCa2E646e47D8fCba4263E9E38);
        gauges.push(0x25707E5FE03dEEdc9Bc7cDD118f9d952C496FeBe);
        gauges.push(0xfcAf4EC80a94a5409141Af16a1DcA950a6973a39);
        gauges.push(0x4426027fEeb7d958498766A792AFE595b64bbFa1);
        gauges.push(0xF98cBBe9Eb3fcB9A793Fb4d0A82854023970D4A4);


        crvUSD = ICrvUSD(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E);
        _vm = IVotemarket(0x000000073D065Fc33a3050C2d0E19C393a5699ba);
        bytes memory incentivesManagerArgs = abi.encode(address(crvUSD), bribeManager, bribePoster, tokenRescuer, emergencyAdmin);
        im = IIncentivesManager(deployCode("IncentivesManager", incentivesManagerArgs));
        bytes memory stakeDaoLogicArgs = abi.encode(address(crvUSD), address(_vm), address(im));
        stakeDaoLogic = IStakeDaoLogic(deployCode("StakeDaoLogic", stakeDaoLogicArgs));
        vm.prank(bribeManager);
        im.set_bribe_logic(address(stakeDaoLogic));
    }
}


