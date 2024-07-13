# pragma version ~=0.4.0
"""
@title IncentivesManager
@license TODO
@author curve.fi
@notice Non-custodial contract to let trusted third parties
    handle Curve-aligned voting incentives.
@dev The contract relies on snekmate for ...
    Most of the usecases consdier the DAO as the
@dev The contract uses the expressions: bribes,
    voting incentives and bounties interchangably to refer
    to the action of granting rewards when a veCRV holder
    votes for a designated gauge.
@custom:security TODO add security contract
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

BRIBE_POSTER: public(constant(bytes32)) = keccak256("BRIBE_POSTER")
BRIBE_MANAGER: public(constant(bytes32)) = keccak256("BRIBE_MANAGER")
TOKEN_RESCUER: public(constant(bytes32)) = keccak256("TOKEN_RESCUER")
EMERGENCY_ADMIN: public(constant(bytes32)) = keccak256("EMERGENCY_ADMIN")

MAX_INCENTIVES_PER_GAUGE: public(constant(uint256)) = 100**18

managed_asset: IERC20
bribe_logic: address
gauge_caps: HashMap[address, uint256]

@deploy
def __init__(managed_asset: address):
    # msg.sender is admin
    access_control.__init__()
    self.managed_asset = IERC20(managed_asset)

@external
def initialize(bribe_poster: address, bribe_manager: address, token_rescuer: address, emergency_admin: address):
    """
    @notice Setup function to be called right after deployment.
    @dev once this function is called the deployer loses the
        to call it again making it renounce ownership of the contract.
    @param bribe_poster The entity in charge of posting bribes
    @param bribe_manager The entity in charge of whitelisting gauges and
        updating the bribe logic (in case the voting market has to be changed)
    @param token_rescuer The entity in charge of rescuing unmanaged funds
        if necessary
    @param emergency_admin The entity in charge of moving the funds elsewhere in
    case of emergency.
    """
    # only deployer can initialize the contract
    access_control._check_role(access_control.DEFAULT_ADMIN_ROLE, msg.sender)

    # grant roles to the different managers
    access_control._grant_role(BRIBE_POSTER, bribe_poster)
    access_control._grant_role(BRIBE_MANAGER, bribe_manager)
    access_control._grant_role(TOKEN_RESCUER, token_rescuer)
    access_control._grant_role(EMERGENCY_ADMIN, emergency_admin)

    # revoke admin role from deployer
    access_control._revoke_role(access_control.DEFAULT_ADMIN_ROLE, msg.sender)

@external
def update_gauge_cap(gauge: address, cap: uint256):
    """
    @notice Setter to change the maximum amount of voting incentives
        that can be allocated in a single bounty.
    @dev this function is a safeguard to prevent fatfingering large
        amounts. This **does not** prevent spending more than
        `MAX_INCENTIVES_PER_GAUGE` since one can create multiple
        bouties for the same gauge
    @param gauge Targeted gauge for the udpate of the caps
    @param cap Maximum amount of incentives that can be allocated
        at once. Set to zero to prevent incentives from being
        posted.
    """
    access_control._check_role(BRIBE_MANAGER, msg.sender)

    if cap > MAX_INCENTIVES_PER_GAUGE:
        raise "New bribe cap too big"

    self.gauge_caps[gauge] = cap

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

    self.bribe_logic = bribe_logic

# TODO use constant from interface for size
@external
def post_bribe(amount: uint256, gauge: address, data: Bytes[1024]):
    """
    @notice post a bribe using the `bribe_logic` contract.
    @dev This function temporarily approves the specified
    amount of token to be spent by the bribe logic contract.
    @param amount The amount of incentives to be allocated for this bribe
    @param gauge The gauge for which the bounty is being posted.
    @param data Additional data that are relevant for the bounty.
    """
    access_control._check_role(BRIBE_POSTER, msg.sender)

    assert  amount <= self.gauges_cap[gauge]

    extcall self.managed_asset.transfer(self.bribe_logic, amount)
    extcall IBribeLogic(self.bribe_logic).bribe(amount, gauge, data)

    assert staticcall self.managed_asset.balanceOf(self.bribe_logic) == 0, "Transfered assets must be fully spent or leftovers should be returned"


@external
def recover_erc20(token: address):
    """
    Recover any ERC20 token (except the managed one) erroneously
    sent to this contract.
    """
    access_control._check_role(TOKEN_RESCUER, msg.sender)

    if token == self.managed_asset.address:
        raise "Cannot recover managed asset"

    balance: uint256 = staticcall IERC20(token).balanceOf(self)
    # TODO `default_return_value`?
    extcall IERC20(token).transfer(msg.sender, balance)

@external
def emergency_migration(safe_receiver: address):
    """
    @notice Migration function in case the funds need to be moved to
    another address.
    """
    access_control._check_role(EMERGENCY_ADMIN, msg.sender)

    balance: uint256 = staticcall self.managed_asset.balanceOf(self)
    extcall self.managed_asset.transfer(safe_receiver, balance)
