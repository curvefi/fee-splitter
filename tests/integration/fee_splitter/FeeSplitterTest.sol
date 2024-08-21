// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../IntegrationTest.sol";

struct Receiver {
    address addr;
    uint256 percentage;
}

interface IFeeSplitter {
    function update_controllers() external;
    function controllers(uint256 index) external view returns (address);
    function n_controllers() external view returns (uint256);
    function n_receivers() external view returns (uint256);
    function receivers(uint256 index) external view returns (Receiver memory);
    function dispatch_fees() external;
}

interface IController {
    function admin_fees() external view returns (uint256);
}

contract FeeSplitterTest is IntegrationTest {
    IFeeSplitter fs;
    address dao;
    address controllerFactory;
    address[] currentControllers;

    function setUp() public override {
        IntegrationTest.setUp();
        // TODO is this admin actually the dao?
        dao = 0x40907540d8a6C65c637785e8f8B742ae6b0b9968;
        controllerFactory = 0xC9332fdCB1C491Dcc683bAe86Fe3cb70360738BC;

        currentControllers.push(0x8472A9A7632b173c8Cf3a86D3afec50c35548e76);
        currentControllers.push(0x100dAa78fC509Db39Ef7D04DE0c1ABD299f4C6CE);
        currentControllers.push(0x4e59541306910aD6dC1daC0AC9dFB29bD9F15c67);
        currentControllers.push(0xA920De414eA4Ab66b97dA1bFE9e6EcA7d4219635);
        currentControllers.push(0xEC0820EfafC41D8943EE8dE495fC9Ba8495B15cf);
        currentControllers.push(0x1C91da0223c763d2e0173243eAdaA0A2ea47E704);

        Receiver[] memory receivers = new Receiver[](2);
        receivers[0] = Receiver({addr: makeAddr("receiver0"), percentage: 7_000});
        receivers[1] = Receiver({addr: makeAddr("receiver1"), percentage: 3_000});
        bytes memory feeSplitterArgs = abi.encode(address(crvUSD), address(controllerFactory), receivers, dao);
        fs = IFeeSplitter(deployCode("FeeSplitter", feeSplitterArgs));
    }
}
