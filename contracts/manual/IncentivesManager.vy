# pragma version ~=0.4.0
"""
@title IncentivesManager
@license Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
@author curve.fi
@notice Non-custodial contract to let trusted third parties
    handle Curve-aligned voting incentives.
@dev The contract relies on snekmate for access control.
@dev The contract uses the expressions: bribes,
    voting incentives and bounties interchangably to refer
    to the action of granting rewards when a veCRV holder
    votes for a designated gauge.
@custom:security security@curve.fi
"""

from ethereum.ercs import IERC20
from ethereum.ercs import IERC165
implements: IERC165

from snekmate.auth.interfaces import IAccessControl
implements: IAccessControl

import IBribeLogic

from snekmate.auth import access_control
initializes: access_control

exports: access_control.__interface__

event SetGaugeCap:
    gauge: address
    cap: uint256

event SetBribeLogic:
    bribe_logic: address

version: public(constant(String[8])) = "0.1.0" # (no guarantees on ABI stability)

MAX_INCENTIVES_PER_GAUGE: public(constant(uint256)) = 10**23 # 100.000 tokens (crvUSD)

BRIBE_POSTER: public(constant(bytes32)) = keccak256("BRIBE_POSTER")
BRIBE_MANAGER: public(constant(bytes32)) = keccak256("BRIBE_MANAGER")
TOKEN_RESCUER: public(constant(bytes32)) = keccak256("TOKEN_RESCUER")
EMERGENCY_ADMIN: public(constant(bytes32)) = keccak256("EMERGENCY_ADMIN")

managed_asset: IERC20
bribe_logic: public(IBribeLogic)
gauge_caps: public(HashMap[address, uint256])


@deploy
def __init__(managed_asset: address, bribe_manager: address, bribe_poster: address, token_rescuer: address, emergency_admin: address):
    """
    @dev After this function is called ownership of the contract is
        renounced making it impossible.
    @param bribe_poster The entity in charge of posting bribes
    @param bribe_manager The entity in charge of whitelisting gauges and
        updating the bribe logic (in case the voting market has to be changed)
    @param token_rescuer The entity in charge of rescuing unmanaged funds
        if necessary
    @param emergency_admin The entity in charge of moving the funds elsewhere in
    case of emergency.
    """
    assert managed_asset != empty(address), "zeroaddr: managed_asset"
    assert bribe_manager != empty(address), "zeroaddr: bribe_manager"
    assert bribe_poster != empty(address), "zeroaddr: bribe_poster"
    assert token_rescuer != empty(address), "zeroaddr: token_rescuer"
    assert emergency_admin != empty(address), "zeroaddr: emergency_admin"
    # msg.sender is admin
    access_control.__init__()
    self.managed_asset = IERC20(managed_asset)

    # grant roles to the different managers
    access_control._grant_role(BRIBE_POSTER, bribe_poster)
    access_control._grant_role(BRIBE_MANAGER, bribe_manager)
    access_control._grant_role(TOKEN_RESCUER, token_rescuer)
    access_control._grant_role(EMERGENCY_ADMIN, emergency_admin)

    # revoke admin role from deployer
    access_control._revoke_role(access_control.DEFAULT_ADMIN_ROLE, msg.sender)

@external
def set_gauge_cap(gauge: address, cap: uint256):
    """
    @notice Setter to change the maximum amount of voting incentives
        that can be allocated in a single bounty.
    @dev This function is a safeguard to prevent fatfingering large
        amounts or bribing the wrong gauge. This **does not**
        prevent spending more than `MAX_INCENTIVES_PER_GAUGE`
        since one can create multiple bouties for the same gauge
    @param gauge Targeted gauge for the udpate of the caps
    @param cap Maximum amount of incentives that can be allocated
        at once. Set to zero to prevent incentives from being
        posted.
    """
    access_control._check_role(BRIBE_MANAGER, msg.sender)

    assert cap <= MAX_INCENTIVES_PER_GAUGE, "manager: new bribe cap too big"

    self.gauge_caps[gauge] = cap

    log SetGaugeCap(gauge, cap)

@external
def set_bribe_logic(bribe_logic: address):
    """
    @notice Change the pointer to the contract with the logic to post
        bribes. Since multiple protocols offer bribe services this
        function avoids vendor lock-in.
    @dev The new contract should carefully be vetted before calling this
        function to make sure it can't steal funds/do something it's not
        supposed to with them.
    @param bribe_logic The new contract that contains the actaul logic
        to post bribes in the preferred protocol.
    """
    access_control._check_role(BRIBE_MANAGER, msg.sender)

    # TODO add interface support

    self.bribe_logic = IBribeLogic(bribe_logic)

    log SetBribeLogic(bribe_logic)

# TODO use constant from interface for size
@external
def post_bribe(gauge: address, amount: uint256, data: Bytes[1024]):
    """
    @notice post a bribe using the `bribe_logic` contract.
    @dev This function temporarily approves the specified
    amount of token to be spent by the bribe logic contract.
    @param amount The amount of incentives to be allocated for this bribe
    @param gauge The gauge for which the bounty is being posted.
    @param data Additional data that are relevant for the bounty.
    """
    access_control._check_role(BRIBE_POSTER, msg.sender)

    assert amount <= self.gauge_caps[gauge], "manager: bribe exceeds cap"

    extcall self.managed_asset.transfer(self.bribe_logic.address, amount)
    extcall self.bribe_logic.bribe(gauge, amount, data)

    assert staticcall self.managed_asset.balanceOf(self.bribe_logic.address) == 0, "manager: bribe not fully spent"


@external
def recover_erc20(token: address, receiver: address):
    """
    @notice Recover any ERC20 token (except the managed one) erroneously
    sent to this contract.
    @param token The token to be recovered
    @param receiver The address to which the tokens will be sent
    """
    access_control._check_role(TOKEN_RESCUER, msg.sender)

    if token == self.managed_asset.address:
        raise "manager: cannot recover managed asset"

    balance: uint256 = staticcall IERC20(token).balanceOf(self)
    assert extcall IERC20(token).transfer(receiver, balance, default_return_value=True)

@external
def emergency_migration(receiver: address):
    """
    @notice Migration function in case the funds need to be moved to
    another address.
    @param receiver The address to which the funds will be sent
    """
    access_control._check_role(EMERGENCY_ADMIN, msg.sender)

    balance: uint256 = staticcall self.managed_asset.balanceOf(self)
    extcall self.managed_asset.transfer(receiver, balance)
