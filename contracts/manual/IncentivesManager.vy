# pragma version ~=0.4.0
"""
@title IncentivesManager
@license Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
@author curve.fi
@notice Non-custodial contract to let trusted third parties
    handle Curve-aligned voting incentives.
@dev The contract relies on snekmate for access control.
@dev The contract uses the expressions: "bribes",
    "voting incentives" and "bounties" interchangably to refer
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

version: public(constant(String[8])) = "0.1.0" # (no guarantees on ABI stability)

event SetGaugeCap:
    gauge: address
    cap: uint256

event SetBribeLogic:
    bribe_logic: address

event UpdateIncentivesState:
    locked: bool

struct IncentivePayload:
    gauge: address
    amount: uint256
    data: Bytes[MAX_DATA_SIZE]

MAX_INCENTIVES_PER_GAUGE: public(constant(uint256)) = 10**23 # 100.000 tokens (crvUSD)
MAX_BRIBES: constant(uint256) = 1000
MAX_DATA_SIZE: constant(uint256) = 1024

BRIBE_PROPOSER: public(constant(bytes32)) = keccak256("BRIBE_PROPOSER")
BRIBE_MANAGER: public(constant(bytes32)) = keccak256("BRIBE_MANAGER")
TOKEN_RESCUER: public(constant(bytes32)) = keccak256("TOKEN_RESCUER")
EMERGENCY_ADMIN: public(constant(bytes32)) = keccak256("EMERGENCY_ADMIN")

managed_asset: immutable(IERC20)

# ADMIN PARAMS
bribe_logic: public(IBribeLogic)
gauge_caps: public(HashMap[address, uint256])

# BOUNTY PARAMS
pending_gauges: public(DynArray[address, MAX_BRIBES])
amount_for_gauge: public(HashMap[address, uint256])
data_for_gauge: public(HashMap[address, Bytes[MAX_DATA_SIZE]])
total_incentives: public(uint256)
incentives_locked: public(bool)


@deploy
def __init__(_managed_asset: IERC20, bribe_manager: address, bribe_proposer: address, token_rescuer: address, emergency_admin: address):
    """
    @dev After this function is called ownership of the contract is
        renounced making it impossible.
    @param bribe_proposer The entity in charge of posting bribes.
    @param bribe_manager The entity in charge of whitelisting gauges and
        updating the bribe logic (in case the voting market has to be changed).
    @param token_rescuer The entity in charge of rescuing unmanaged funds
        if necessary.
    @param emergency_admin The entity in charge of moving the funds elsewhere in
        case of emergency.
    """
    assert _managed_asset != empty(IERC20), "zeroaddr: managed_asset"
    assert bribe_manager != empty(address), "zeroaddr: bribe_manager"
    assert bribe_proposer != empty(address), "zeroaddr: bribe_proposer"
    assert token_rescuer != empty(address), "zeroaddr: token_rescuer"
    assert emergency_admin != empty(address), "zeroaddr: emergency_admin"
    # msg.sender is admin
    access_control.__init__()
    managed_asset = _managed_asset

    # grant roles to the different managers
    access_control._grant_role(BRIBE_PROPOSER, bribe_proposer)
    access_control._grant_role(BRIBE_MANAGER, bribe_manager)
    access_control._grant_role(TOKEN_RESCUER, token_rescuer)
    access_control._grant_role(EMERGENCY_ADMIN, emergency_admin)

    # revoke admin role from deployer
    access_control._revoke_role(access_control.DEFAULT_ADMIN_ROLE, msg.sender)

@external
def set_gauge_cap(gauge: address, cap: uint256):
    """
    @notice Setter to change the maximum amount of voting incentives
        that can be allocated in a single bounty. Setting the cap to
        zero effectively prevents the gauge from receiving incentives.
    @dev This function is a safeguard to prevent fatfingering large
        amounts or bribing the wrong gauge. This **does not**
        prevent spending more than `MAX_INCENTIVES_PER_GAUGE`
        since one can create multiple bouties for the same gauge.
    @param gauge Targeted gauge for the udpate of the caps.
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

    self.bribe_logic = IBribeLogic(bribe_logic)

    log SetBribeLogic(bribe_logic)

@external
def update_incentives_batch(payloads: DynArray[IncentivePayload, MAX_BRIBES]):
    """
    @notice Update the incentives for the next round. After the
        incentives are set, the `confirm_batch` function must be
        called to lock the incentives and prepare the contract
        for the distribution.
    @dev Each call to this function will overwrite the previous
        incentives.
    @param payloads The list of payload to be posted, each
        containing amounts, gauges and additional data (if any).
    """
    access_control._check_role(BRIBE_PROPOSER, msg.sender)
    assert len(payloads) > 0, "manager: no incentives given"

    # empty the previous payloads
    self.pending_gauges = []
    self.total_incentives = 0

    for i: IncentivePayload in payloads:
        self._update_incentive(i.gauge, i.amount, i.data)


def _update_incentive(gauge: address, amount: uint256, data: Bytes[MAX_DATA_SIZE]):
    assert amount > 0 and amount <= self.gauge_caps[gauge], "manager: invalid bribe amount"

    self.pending_gauges.append(gauge)
    self.total_incentives += amount
    self.amount_for_gauge[gauge] = amount
    self.data_for_gauge[gauge] = data
        

@external
def confirm_batch():
    """
    @notice Lock the incentives to prevent further updates and prepare
        the contract for the distribution of the incentives.
    """
    access_control._check_role(BRIBE_PROPOSER, msg.sender)
    assert len(self.pending_gauges) > 0, "manager: no incentives batched"

    self.incentives_locked = True
    
    log UpdateIncentivesState(True)

@external
def cancel_batch():
    """
    @notice Unlock the incentives to allow for further updates.
        This function is useful in case of errors or if the incentives
        are no longer needed.
    """
    access_control._check_role(BRIBE_PROPOSER, msg.sender)

    self.incentives_locked = False

    log UpdateIncentivesState(False)

@external
def post_incentives():
    """
    @notice Permissionless function to post the incentives for the
        designated gauges. This function can be called by anyone
        as long as the `BRIBE_PROPOSER` has designated the incentives
        and confirmed the batch.
    """
    assert not access_control.hasRole[BRIBE_PROPOSER][msg.sender], "manager: proposer can't post"
    assert self.incentives_locked, "manager: batch yet to be confirmed"

    extcall managed_asset.transfer(self.bribe_logic.address, self.total_incentives)

    for gauge: address in self.pending_gauges:
        amount: uint256 = self.amount_for_gauge[gauge]
        data: Bytes[MAX_DATA_SIZE] = self.data_for_gauge[gauge]
        extcall self.bribe_logic.bribe(gauge, amount, data)

    assert staticcall managed_asset.balanceOf(self.bribe_logic.address) == 0, "manager: bribe not fully spent"

    self.incentives_locked = False
    self.total_incentives = 0
    self.pending_gauges = []


@external
def recover_erc20(token: address, receiver: address):
    """
    @notice Recover any ERC20 token (except the managed one) erroneously
        sent to this contract.
    @param token The token to be recovered
    @param receiver The address to which the tokens will be sent
    """
    access_control._check_role(TOKEN_RESCUER, msg.sender)

    assert token != managed_asset.address, "manager: cannot recover managed asset"

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

    balance: uint256 = staticcall managed_asset.balanceOf(self)
    extcall managed_asset.transfer(receiver, balance)
