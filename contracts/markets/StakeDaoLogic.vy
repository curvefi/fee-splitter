# pragma version ~=0.4.0

"""
@title StakeDaoLogic
@license Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
@author curve.fi
@notice This contract lets trusted third parties post
    Curve-sponored bribes on StakeDAO's Votemarket through
    the IncentivesManager contract.
@dev The contract relies on snekmate for access control.
@dev The contract uses the expressions: bribes,
    voting incentives and bounties interchangably to refer
    to the action of granting rewards when a veCRV holder
    votes for a designated gauge.
@custom:security security@curve.fi contact@stakedao.org
"""

from snekmate.auth import ownable
from contracts.manual import IBribeLogic
import StakeDaoMarket as Votemarket
from ethereum.ercs import IERC20

# Interfaces can't be imported from contracts
# (should be fixed soon by the Vyper team)
interface IncentivesManager:
    def hasRole(role: bytes32, account: address) -> bool: view
    def TOKEN_RESCUER() -> bytes32: view


implements: IBribeLogic
initializes: ownable
exports: ownable.__interface__

version: public(constant(String[8])) = "0.1.0" # (no guarantees on ABI stability)

votemarket: public(Votemarket)
crvusd: public(IERC20)
bounty_id: public(HashMap[address, uint256])

BRIBE_DURATION: constant(uint8) = 2 # bi-weekly
TOKEN_RESCUER: constant(bytes32) = keccak256("TOKEN_RESCUER")

@deploy
def __init__(crvusd: address, votemarket: address, incentives_manager: address):
    """
    @param crvusd The address of the CRVUSD token
    @param votemarket The address of the StakeDAO Votemarket instance
    @param incentives_manager The address of the IncentivesManager contract
    @dev The IncentivesManager contract will be the owner of this contract
        and its sole user.
    """
    assert crvusd != empty(address), "zeroaddr: crvusd"
    assert votemarket != empty(address), "zeroaddr: votemarket"
    assert incentives_manager != empty(address), "zeroaddr: incentives_manager"

    ownable.__init__()
    ownable._transfer_ownership(incentives_manager)
    self.votemarket = Votemarket(votemarket)
    self.crvusd = IERC20(crvusd)


@external
def bribe(gauge: address, amount: uint256, data: Bytes[1024]) -> uint256:
    """
    @notice Posts a bribe on StakeDAO's Votemarket
    @dev The data payload is expected to contain the maximum amount
        of crvUSD that can be distributed per vote.
    @dev The first bribe will create a new bounty, subsequent bribes
        will increase the duration of the existing bounties allowing
        rewards to be rolled over (if not claimed).
    @dev If the `bounty_id` returned by `create_bounty` is 0 the
        successive bounty for that id will be recreated instead of
        being increased. This contract assumes that the `bounty_id`
        will never be 0.
    @return The id of the bounty created or increased
    """
    ownable._check_owner()

    bounty_id: uint256 = 0

    max_amount_per_vote: uint256 = abi_decode(data, (uint256))
    if self.bounty_id[gauge] == 0:
        bounty_id = self.create_bounty(gauge, amount, max_amount_per_vote)
        self.bounty_id[gauge] = bounty_id
    else:
        bounty_id = self.bounty_id[gauge]
        self.increase_bounty_duration(bounty_id, amount, max_amount_per_vote)

    leftovers: uint256 = staticcall self.crvusd.balanceOf(self)
    if leftovers > 0:
        extcall self.crvusd.transfer(msg.sender, leftovers)

    return bounty_id

@external
def close_bounty(bounty_id: uint256, receiver: address):
    """
    @notice Recovers unspent funds from a bounty in case of a migration
    to a different market.
    @dev Recovered funds are sent to the manager of the bounty, which is
    the IncentivesManager contract in this instance. From there the funds
    can be recovered using the migraion function.
    @param bounty_id The id of the bounty from which the funds will be
        recovered.
    """
    manager: IncentivesManager = IncentivesManager(ownable.owner)
    assert staticcall manager.hasRole(TOKEN_RESCUER, msg.sender), "access_control: account is missing role"
    extcall self.votemarket.closeBounty(bounty_id)
    unclaimed_funds: uint256 = staticcall self.crvusd.balanceOf(self)
    assert unclaimed_funds > 0, "manager: no unclaimed funds to recover"
    extcall self.crvusd.transfer(receiver, unclaimed_funds)


def create_bounty(gauge: address, amount: uint256, max_reward_per_vote: uint256) -> uint256:
    extcall self.crvusd.approve(self.votemarket.address, amount)
    return extcall self.votemarket.createBounty(
        gauge,
        self, # this is the manager contract
        self.crvusd.address, # we only bribe in crvusd
        BRIBE_DURATION, # we bribe at a bi-weekly frequency
        max_reward_per_vote,
        amount,
        empty(DynArray[address, 1]),
        True
    )

def increase_bounty_duration(bounty_id: uint256, amount: uint256, max_price_per_vote: uint256):
    extcall self.crvusd.approve(self.votemarket.address, amount)
    extcall self.votemarket.increaseBountyDuration(
        bounty_id,
        BRIBE_DURATION,
        amount,
        max_price_per_vote
    )
