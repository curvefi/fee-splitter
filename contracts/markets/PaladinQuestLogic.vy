# pragma version ~=0.4.0

"""
@title PaladinQuestLogic
@license Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
@author curve.fi
@notice This contract lets trusted third parties post
    Curve-sponored bribes on Paladin's Quest through
    the IncentivesManager contract.
@dev The contract relies on snekmate for access control.
@dev The contract uses the expressions: bribes,
    voting incentives and quests interchangably to refer
    to the action of granting rewards when a veCRV holder
    votes for a designated gauge.
@custom:security security@curve.fi valentin@paladin.vote
"""

from snekmate.auth import ownable
from contracts.manual import IBribeLogic
import PaladinQuest as Quest
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

quest_board: public(Quest)
crvusd: public(IERC20)
quest_id: public(HashMap[address, uint256])

min_reward_per_vote: public(uint256)
max_reward_per_vote: public(uint256)

voter_blacklist: public(address[10])
voter_blacklist_length: public(uint256)

BRIBE_DURATION: constant(uint8) = 2 # bi-weekly
QUEST_DEFAULT_FEE_RATIO: constant(uint256) = 400
MAX_BPS: constant(uint256) = 10000
TOKEN_RESCUER: constant(bytes32) = keccak256("TOKEN_RESCUER")
BRIBE_PROPOSER: constant(bytes32) = keccak256("BRIBE_PROPOSER")

@deploy
def __init__(crvusd: address, quest_board: address, incentives_manager: address, min_amount_per_vote: uint256, max_amount_per_vote: uint256):
    """
    @param crvusd The address of the CRVUSD token
    @param quest_board The address of the Paladin Quest instance
    @param incentives_manager The address of the IncentivesManager contract
    @dev The IncentivesManager contract will be the owner of this contract
        and its sole user.
    """
    assert crvusd != empty(address), "zeroaddr: crvusd"
    assert quest_board != empty(address), "zeroaddr: quest_board"
    assert incentives_manager != empty(address), "zeroaddr: incentives_manager"
    assert min_amount_per_vote > 0, "zero: min_amount_per_vote"
    assert max_amount_per_vote > 0, "zero: max_amount_per_vote"
    assert min_amount_per_vote < max_amount_per_vote, "invalid: min_amount_per_vote > max_amount_per_vote"

    ownable.__init__()
    ownable._transfer_ownership(incentives_manager)
    self.quest_board = Quest(quest_board)
    self.crvusd = IERC20(crvusd)
    self.min_reward_per_vote = min_amount_per_vote
    self.max_reward_per_vote = max_amount_per_vote


@external
def bribe(gauge: address, amount: uint256, data: Bytes[1024]):
    """
    @notice Posts a bribe on Paladin's Quest
    @dev The data payload is expected to contian the minimum
    and maximum amount of crvUSD that can be distributed per vote.
    @dev Each bribe will create a new quest, and claim back all
    unspent funds from the previous quest to rollover to the new one.
    """
    ownable._check_owner()

    quest_id: uint256 = 0
    total_budget: uint256 = amount

    withdrawn: uint256 = self.withdraw_expired_quest(self.quest_id[gauge])
    if withdrawn > 0:
        total_budget += withdrawn

    quest_id = self.create_quest(gauge, total_budget, self.min_reward_per_vote, self.max_reward_per_vote)
    self.quest_id[gauge] = quest_id

    leftovers: uint256 = staticcall self.crvusd.balanceOf(self)
    if leftovers > 0:
        extcall self.crvusd.transfer(msg.sender, leftovers)

@external
def withdraw_from_quest(quest_id: uint256, receiver: address):
    """
    @notice Recovers unspent funds from a quest after it is over, in case this
    contract didn't do it already.
    @dev Withdrawn funds are sent to the manager of the quest, which is
    the IncentivesManager contract in this instance. From there the funds
    can be recovered using the migration function.
    @param quest_id The id of the quest from which the funds will be
        withdrawn.
    """
    manager: IncentivesManager = IncentivesManager(ownable.owner)
    assert staticcall manager.hasRole(TOKEN_RESCUER, msg.sender), "access_control: account is missing role"
    extcall self.quest_board.withdrawUnusedRewards(quest_id, self)
    unclaimed_funds: uint256 = staticcall self.crvusd.balanceOf(self)
    assert unclaimed_funds > 0, "manager: no unclaimed funds to recover"
    extcall self.crvusd.transfer(receiver, unclaimed_funds)


def create_quest(
    gauge: address,
    amount: uint256,
    min_amount_per_vote: uint256,
    max_amount_per_vote: uint256) -> uint256:
    extcall self.crvusd.approve(self.quest_board.address, amount)

    # calculate fees and budget
    fee_ratio: uint256 = staticcall self.quest_board.customPlatformFeeRatio(self)
    if fee_ratio == 0:
        fee_ratio = QUEST_DEFAULT_FEE_RATIO
    total_budget: uint256 = (amount * MAX_BPS) // (MAX_BPS + fee_ratio)
    fee_amount: uint256 = (total_budget * fee_ratio) // MAX_BPS

    # prepare the blacklist array
    vote_type: uint8 = 0
    blacklist: DynArray[address, 10] = []
    if(self.voter_blacklist_length > 0):
        vote_type = 1
        for i: uint256 in range(10):
            if(self.voter_blacklist[i] == empty(address)):
                break
            blacklist.append(self.voter_blacklist[i])

    return extcall self.quest_board.createRangedQuest(
        gauge,
        self.crvusd.address, # we only bribe in crvusd
        False, # start the Quest now
        convert(BRIBE_DURATION, uint48), # we bribe at a bi-weekly frequency
        min_amount_per_vote,
        max_amount_per_vote,
        total_budget,
        fee_amount,
        vote_type, # blacklist, or normal
        1, # rollover
        blacklist
    )


def withdraw_expired_quest(quest_id: uint256) -> uint256:
    withdrawable: uint256 = staticcall self.quest_board.questWithdrawableAmount(quest_id)
    if(withdrawable == 0):
        return 0
    extcall self.quest_board.withdrawUnusedRewards(quest_id, self)
    return withdrawable


@external
def update_rewards_per_vote_range(new_min: uint256, new_max: uint256):
    """
    @notice Updates the range of rewards per vote for all future bribes
    @dev The new range will be applied to all future bribes
    @param new_min The new minimum amount of crvUSD that can be distributed per vote
    @param new_max The new maximum amount of crvUSD that can be distributed per vote
    """
    manager: IncentivesManager = IncentivesManager(ownable.owner)
    assert staticcall manager.hasRole(BRIBE_PROPOSER, msg.sender), "access_control: account is missing role"
    assert new_min > 0, "zero: new_min"
    assert new_max > 0, "zero: new_max"
    assert new_min < new_max, "invalid: new_min > new_max"
    self.min_reward_per_vote = new_min
    self.max_reward_per_vote = new_max

@external
def set_voter_blacklist(new_list: DynArray[address, 10]):
    """
    @notice Sets the voter blacklist
    @dev The blacklist is used to prevent certain addresses from receiving bribes
    @param new_list The list of addresses to be blacklisted
    """
    manager: IncentivesManager = IncentivesManager(ownable.owner)
    assert staticcall manager.hasRole(BRIBE_PROPOSER, msg.sender), "access_control: account is missing role"
    new_list_len: uint256 = 0
    # clear the blacklist
    for i: uint256 in range(10):
        self.voter_blacklist[i] = empty(address)
    # set the new blacklist
    for j: uint256 in range(10):
        if(new_list[j] == empty(address)):
            break
        new_list_len += 1
        self.voter_blacklist[j] = new_list[j]
        if(j == len(new_list) - 1):
            break
    self.voter_blacklist_length = new_list_len
