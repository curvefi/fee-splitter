// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;
import {Test, console} from "forge-std/Test.sol";

import {IVotemarket} from "./votemarket/IVotemarket.sol";
import {ICrvUSD} from "./ICrvUSD.sol";

struct IncentivesPayload {
    address gauge;
    uint256 amount;
    bytes data;
}

interface IIncentivesManager {
    function set_bribe_logic(address logic) external;
    function set_gauge_cap(address gauge, uint256 cap) external;
    function update_incentives_batch(IncentivesPayload[] calldata payload) external;
    function confirm_batch() external;
    function post_incentives() external;
}

interface IBribeLogic {
    function bribe(address gauge, uint256 amount, bytes calldata data) external;
}



contract IntegrationTest is Test {
    address public bribeManager;
    address public bribeProposer;
    address public tokenRescuer;
    address public emergencyAdmin;

    IIncentivesManager public im;
    ICrvUSD crvUSD;
    address[] gauges; 

    function setUp() virtual public {
        vm.createSelectFork("https://ethereum-rpc.publicnode.com", 20382333);

        bribeManager = makeAddr("BRIBE_MANAGER");
        bribeProposer = makeAddr("BRIBE_PROPOSER");
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
//        gauges.push(0x49887dF6fE905663CDB46c616BfBfBB50e85a265);
//        gauges.push(0x3Ba9d8792Fa703eA21B6120E675aA34Bda836AEB);
//        gauges.push(0x294280254e1c8BcF56F8618623Ec9235e8415633);
//        gauges.push(0x30e06CADFbC54d61B7821dC1e58026bf3435d2Fe);
//        gauges.push(0xDFF0ed66fdDCC440FB3aDFB2f12029925799979c);
//        gauges.push(0xAE1680Ef5EFc2486E73D8d5D0f8a8dB77DA5774E);
//        gauges.push(0x82195f78C313540E0363736b8320A256A019F7DD);
//        gauges.push(0x41eBf0bEC45642A675e8b7536A2cE9c078A814B4);
//        gauges.push(0x2605D72e460fEfF15BF4Fd728a5ea31928895c2a);
//        gauges.push(0xEAED59025d6Cf575238A9B4905aCa11E000BaAD0);
//        gauges.push(0xad7B288315b0d71D62827338251A8D89A98132A0);
//        gauges.push(0x7dCB252f7Ea2B8dA6fA59C79EdF63f793C8b63b6);
//        gauges.push(0xF3F6D6d412a77b680ec3a5E35EbB11BbEC319739);
//        gauges.push(0x1Cfabd1937e75E40Fa06B650CB0C8CD233D65C20);
//        gauges.push(0x0621982CdA4fD4041964e91AF4080583C5F099e1);
//        gauges.push(0x222D910ef37C06774E1eDB9DC9459664f73776f0);

        crvUSD = ICrvUSD(0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E);
    }
}


