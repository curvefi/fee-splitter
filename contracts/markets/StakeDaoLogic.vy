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

implements: IBribeLogic
initializes: ownable
exports: ownable.__interface__

votemarket: public(Votemarket)
crvusd: public(IERC20)
bounty_id: public(HashMap[address, uint256])
BRIBE_DURATION: constant(uint256) = 2 # bi-weekly

# TODO add recovery mechanism

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
def bribe(gauge: address, amount: uint256, data: Bytes[1024]):
    """
    @notice Posts a bribe on StakeDAO's Votemarket
    @dev The data payload is expected to contain the maximum amount
        of CRVUSD that can be distributed per vote.
    @dev The first bribe will create a new bounty, subsequent bribes
        will increase the duration of the existing bounties allowing
        rewards to be rolled over (if not claimed).
    """
    ownable._check_owner()

    max_amount_per_vote: uint256 = abi_decode(data, (uint256))
    # TODO is it safe to assume that bounty_id will never be 0?
    if self.bounty_id[gauge] == 0:
        self.bounty_id[gauge] = self.create_bounty(gauge, amount, max_amount_per_vote)
    else:
        self.increase_bounty_duration(gauge, amount, max_amount_per_vote)

    leftovers: uint256 = staticcall self.crvusd.balanceOf(self)
    if leftovers > 0:
        extcall self.crvusd.transfer(msg.sender, leftovers)


def create_bounty(gauge: address, amount: uint256, max_reward_per_vote: uint256) -> uint256:
    return extcall self.votemarket.createBounty(
        gauge,
        self, # this is the manager contract
        self.crvusd.address, # we only bribe in crvusd
        convert(BRIBE_DURATION, uint8), # we bribe at a bi-weekly frequency
        max_reward_per_vote,
        amount,
        empty(DynArray[address, 1]),
        False
    )

def increase_bounty_duration(gauge: address, amount: uint256, max_price_per_vote: uint256):
    bounty_id: uint256 = self.bounty_id[gauge]
    extcall self.votemarket.increaseBountyDuration(
        bounty_id,
        BRIBE_DURATION,
        amount,
        max_price_per_vote
    )
