import boa

from contracts.markets import PaladinQuestLogic


def test_constructor(quest_logic, crvusd, quest_market, manager):
    assert quest_logic.crvusd() == crvusd.address
    assert quest_logic.quest_board() == quest_market.address
    assert quest_logic.owner() == manager.address
    assert quest_logic.min_reward_per_vote() == 10_000
    assert quest_logic.max_reward_per_vote() == 50_000


def test_constructor_zeroaddr(crvusd, quest_market, manager):
    zero = boa.eval("empty(address)")

    with boa.reverts("zeroaddr: crvusd"):
        PaladinQuestLogic(zero, quest_market, manager, 10_000, 50_000)
    with boa.reverts("zeroaddr: quest_board"):
        PaladinQuestLogic(crvusd, zero, manager, 10_000, 50_000)
    with boa.reverts("zeroaddr: incentives_manager"):
        PaladinQuestLogic(crvusd, quest_market, zero, 10_000, 50_000)


def test_constructor_zero(crvusd, quest_market, manager):
    with boa.reverts("zero: min_amount_per_vote"):
        PaladinQuestLogic(crvusd, quest_market, manager, 0, 10_000)
    with boa.reverts("zero: max_amount_per_vote"):
        PaladinQuestLogic(crvusd, quest_market, manager, 10_000, 0)


def test_constructor_invalid(crvusd, quest_market, manager):
    with boa.reverts("invalid: min_amount_per_vote > max_amount_per_vote"):
        PaladinQuestLogic(crvusd, quest_market, manager, 50_000, 10_000)


def test_create_quest(quest_logic, quest_market, crvusd):
    quest_logic.internal.create_quest(
        gauge := boa.env.generate_address(), 10400000, 10_000, 50_000
    )

    assert quest_market.creation_creator() == quest_logic.address
    assert quest_market.creation_gauge() == gauge
    assert quest_market.creation_rewardToken() == crvusd.address
    assert not quest_market.creation_start_period()
    assert quest_market.creation_duration() == 2
    assert quest_market.creation_minRewardPerVote() == 10_000
    assert quest_market.creation_maxRewardPerVote() == 50_000
    assert quest_market.creation_totalRewardAmount() == 10000000
    assert quest_market.creation_feeAmount() == 400000
    assert quest_market.creation_voteType() == 0
    assert quest_market.creation_closeType() == 1
    assert quest_market.eval("len(self.creation_blacklist)") == 0


def test_bribe(quest_logic, quest_market, crvusd, manager):
    random_gauge = boa.env.generate_address()
    random_id = 43958

    leftover_crvusd = 10**18

    crvusd.mint_for_testing(quest_logic, leftover_crvusd)

    assert quest_logic.quest_id(random_gauge) == 0

    with boa.env.prank(manager.address):
        quest_logic.bribe(random_gauge, 10400000, bytes())

    assert quest_logic.quest_id(random_gauge) == 99  # from mock

    quest_logic.eval(f"self.quest_id[{random_gauge}] = {random_id}")

    assert quest_market.creation_creator() == quest_logic.address
    assert quest_market.creation_gauge() == random_gauge
    assert quest_market.creation_rewardToken() == crvusd.address
    assert not quest_market.creation_start_period()
    assert quest_market.creation_duration() == 2
    assert quest_market.creation_minRewardPerVote() == 10_000
    assert quest_market.creation_maxRewardPerVote() == 50_000
    assert quest_market.creation_totalRewardAmount() == 10000000
    assert quest_market.creation_feeAmount() == 400000
    assert quest_market.creation_voteType() == 0
    assert quest_market.creation_closeType() == 1
    assert quest_market.eval("len(self.creation_blacklist)") == 0

    # this part should be uninitialized after the first call
    assert quest_market.withdraw_id() == 0

    # cleaning dust
    assert crvusd.balanceOf(quest_logic.address) == 0
    assert crvusd.balanceOf(manager.address) == leftover_crvusd


def test_bribe_subsequent(quest_logic, quest_market, crvusd, manager):
    random_gauge = boa.env.generate_address()
    random_id = 43958

    leftover_crvusd = 10**18

    crvusd.mint_for_testing(quest_logic, leftover_crvusd)

    assert quest_logic.quest_id(random_gauge) == 0

    with boa.env.prank(manager.address):
        quest_logic.bribe(random_gauge, 10400000, bytes())

    assert quest_logic.quest_id(random_gauge) == 99  # from mock

    quest_logic.eval(f"self.quest_id[{random_gauge}] = {random_id}")

    assert quest_market.creation_creator() == quest_logic.address
    assert quest_market.creation_gauge() == random_gauge
    assert quest_market.creation_rewardToken() == crvusd.address
    assert not quest_market.creation_start_period()
    assert quest_market.creation_duration() == 2
    assert quest_market.creation_minRewardPerVote() == 10_000
    assert quest_market.creation_maxRewardPerVote() == 50_000
    assert quest_market.creation_totalRewardAmount() == 10000000
    assert quest_market.creation_feeAmount() == 400000
    assert quest_market.creation_voteType() == 0
    assert quest_market.creation_closeType() == 1
    assert quest_market.eval("len(self.creation_blacklist)") == 0

    # this part should be uninitialized after the first call
    assert quest_market.withdraw_id() == 0

    # cleaning dust
    assert crvusd.balanceOf(quest_logic.address) == 0
    assert crvusd.balanceOf(manager.address) == leftover_crvusd

    # we test for a second call to withdraw from
    # the previous quest and rollover the budget
    quest_market.setQuestWithdrawableAmount(random_id, 3120000)
    crvusd.mint_for_testing(quest_logic, leftover_crvusd)

    with boa.env.prank(manager.address):
        quest_logic.bribe(random_gauge, 10400000, bytes(0))

    assert quest_logic.quest_id(random_gauge) == 99  # from mock

    assert quest_market.withdraw_id() == random_id
    assert quest_market.quest_withdrawable_amount(random_id) == 0

    assert quest_market.creation_creator() == quest_logic.address
    assert quest_market.creation_gauge() == random_gauge
    assert quest_market.creation_rewardToken() == crvusd.address
    assert not quest_market.creation_start_period()
    assert quest_market.creation_duration() == 2
    assert quest_market.creation_minRewardPerVote() == 10_000
    assert quest_market.creation_maxRewardPerVote() == 50_000
    assert quest_market.creation_totalRewardAmount() == 13000000
    assert quest_market.creation_feeAmount() == 520000
    assert quest_market.creation_voteType() == 0
    assert quest_market.creation_closeType() == 1
    assert quest_market.eval("len(self.creation_blacklist)") == 0

    # cleaning dust
    assert crvusd.balanceOf(quest_logic.address) == 0
    assert crvusd.balanceOf(manager.address) == leftover_crvusd * 2


def test_bribe_unauthorized(quest_logic):
    with boa.reverts("ownable: caller is not the owner"):
        quest_logic.bribe(boa.env.generate_address(), 400000, bytes())


def test_withdraw_from_quest(quest_logic, quest_market, token_rescuer, crvusd):
    crvusd.mint_for_testing(quest_logic, 1000)
    with boa.env.prank(token_rescuer):
        quest_logic.withdraw_from_quest(
            7890, recovery_addr := boa.env.generate_address()
        )
    assert crvusd.balanceOf(recovery_addr) == 1000
    assert quest_market.withdraw_id() == 7890


def test_withdraw_from_quest_no_funds(
    quest_logic, quest_market, token_rescuer
):
    with boa.env.prank(token_rescuer):
        with boa.reverts("manager: no unclaimed funds to recover"):
            quest_logic.withdraw_from_quest(7890, boa.env.generate_address())


def test_withdraw_from_quest_unauthorized(quest_logic):
    with boa.reverts("access_control: account is missing role"):
        quest_logic.withdraw_from_quest(7890, boa.env.generate_address())


def test_update_rewards_per_vote_range(quest_logic, bribe_proposer):
    assert quest_logic.min_reward_per_vote() == 10_000
    assert quest_logic.max_reward_per_vote() == 50_000
    with boa.env.prank(bribe_proposer):
        quest_logic.update_rewards_per_vote_range(8_000, 45_000)
    assert quest_logic.min_reward_per_vote() == 8_000
    assert quest_logic.max_reward_per_vote() == 45_000


def test_update_rewards_unauthorized(quest_logic):
    with boa.reverts("access_control: account is missing role"):
        quest_logic.update_rewards_per_vote_range(8_000, 45_000)


def test_update_rewards_per_vote_range_zero(quest_logic, bribe_proposer):
    with boa.reverts("zero: new_min"):
        with boa.env.prank(bribe_proposer):
            quest_logic.update_rewards_per_vote_range(0, 45_000)
    with boa.reverts("zero: new_max"):
        with boa.env.prank(bribe_proposer):
            quest_logic.update_rewards_per_vote_range(8_000, 0)


def test_update_rewards_per_vote_range_invalid(quest_logic, bribe_proposer):
    with boa.reverts("invalid: new_min > new_max"):
        with boa.env.prank(bribe_proposer):
            quest_logic.update_rewards_per_vote_range(45_000, 8_000)


def test_set_voter_blacklist(quest_logic, bribe_proposer):
    address_zero = boa.eval("empty(address)")
    new_list = [
        boa.env.generate_address(),
        boa.env.generate_address(),
        boa.env.generate_address(),
    ]

    assert quest_logic.voter_blacklist_length() == 0

    with boa.env.prank(bribe_proposer):
        quest_logic.set_voter_blacklist(new_list)

    assert quest_logic.voter_blacklist_length() == 3

    assert quest_logic.voter_blacklist(0) == new_list[0]
    assert quest_logic.voter_blacklist(1) == new_list[1]
    assert quest_logic.voter_blacklist(2) == new_list[2]
    assert quest_logic.voter_blacklist(3) == address_zero
    assert quest_logic.voter_blacklist(4) == address_zero


def test_set_voter_blacklist_access_control(quest_logic):
    new_list = [
        boa.env.generate_address(),
        boa.env.generate_address(),
        boa.env.generate_address(),
    ]
    with boa.reverts("access_control: account is missing role"):
        quest_logic.set_voter_blacklist(new_list)


def test_set_voter_blacklist_address_zero(quest_logic, bribe_proposer):
    address_zero = boa.eval("empty(address)")
    new_list = [
        boa.env.generate_address(),
        boa.env.generate_address(),
        address_zero,
        boa.env.generate_address(),
    ]

    assert quest_logic.voter_blacklist_length() == 0

    with boa.env.prank(bribe_proposer):
        quest_logic.set_voter_blacklist(new_list)

    assert quest_logic.voter_blacklist_length() == 2

    assert quest_logic.voter_blacklist(0) == new_list[0]
    assert quest_logic.voter_blacklist(1) == new_list[1]
    assert quest_logic.voter_blacklist(2) == address_zero
    assert quest_logic.voter_blacklist(3) == address_zero
    assert quest_logic.voter_blacklist(4) == address_zero


def test_bribe_with_blacklist(
    quest_logic, quest_market, crvusd, manager, bribe_proposer
):
    random_gauge = boa.env.generate_address()
    random_id = 43958
    new_list = [boa.env.generate_address(), boa.env.generate_address()]

    with boa.env.prank(bribe_proposer):
        quest_logic.set_voter_blacklist(new_list)

    leftover_crvusd = 10**18

    crvusd.mint_for_testing(quest_logic, leftover_crvusd)

    assert quest_logic.quest_id(random_gauge) == 0

    with boa.env.prank(manager.address):
        quest_logic.bribe(random_gauge, 10400000, bytes())

    assert quest_logic.quest_id(random_gauge) == 99  # from mock

    quest_logic.eval(f"self.quest_id[{random_gauge}] = {random_id}")

    assert quest_market.creation_creator() == quest_logic.address
    assert quest_market.creation_gauge() == random_gauge
    assert quest_market.creation_rewardToken() == crvusd.address
    assert not quest_market.creation_start_period()
    assert quest_market.creation_duration() == 2
    assert quest_market.creation_minRewardPerVote() == 10_000
    assert quest_market.creation_maxRewardPerVote() == 50_000
    assert quest_market.creation_totalRewardAmount() == 10000000
    assert quest_market.creation_feeAmount() == 400000
    assert quest_market.creation_voteType() == 1
    assert quest_market.creation_closeType() == 1
    assert quest_market.eval("len(self.creation_blacklist)") == 2
    assert quest_market.creation_blacklist(0) == new_list[0]
    assert quest_market.creation_blacklist(1) == new_list[1]

    # cleaning dust
    assert crvusd.balanceOf(quest_logic.address) == 0
    assert crvusd.balanceOf(manager.address) == leftover_crvusd
