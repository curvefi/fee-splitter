// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

interface ICrvUSD {
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event SetMinter(address indexed minter);
    event Transfer(address indexed sender, address indexed receiver, uint256 value);

    function DOMAIN_SEPARATOR() external view returns (bytes32);
    function allowance(address arg0, address arg1) external view returns (uint256);
    function approve(address _spender, uint256 _value) external returns (bool);
    function balanceOf(address arg0) external view returns (uint256);
    function burn(uint256 _value) external returns (bool);
    function burnFrom(address _from, uint256 _value) external returns (bool);
    function decimals() external view returns (uint8);
    function decreaseAllowance(address _spender, uint256 _sub_value) external returns (bool);
    function increaseAllowance(address _spender, uint256 _add_value) external returns (bool);
    function mint(address _to, uint256 _value) external returns (bool);
    function minter() external view returns (address);
    function name() external view returns (string memory);
    function nonces(address arg0) external view returns (uint256);
    function permit(address _owner, address _spender, uint256 _value, uint256 _deadline, uint8 _v, bytes32 _r, bytes32 _s) external returns (bool);
    function salt() external view returns (bytes32);
    function set_minter(address _minter) external;
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
    function transfer(address _to, uint256 _value) external returns (bool);
    function transferFrom(address _from, address _to, uint256 _value) external returns (bool);
    function version() external view returns (string memory);
}