import boa
from contracts.markets import StakeDaoLogic


def test_constructor(stakedao_logic, mock_crvusd, mock_stakedao_market,
                     manager):
    assert stakedao_logic.crvusd() == mock_crvusd.address
    assert stakedao_logic.votemarket() == mock_stakedao_market.address
    assert stakedao_logic.owner() == manager.address


def test_constructor_zeroaddr(mock_crvusd, mock_stakedao_market, manager):
    zero = boa.eval("empty(address)")

    with boa.reverts("zeroaddr: crvusd"):
        StakeDaoLogic(zero, mock_stakedao_market, manager)
    with boa.reverts("zeroaddr: votemarket"):
        StakeDaoLogic(mock_crvusd, zero, manager)
    with boa.reverts("zeroaddr: incentives_manager"):
        StakeDaoLogic(mock_crvusd, mock_stakedao_market, zero)


def test_create_bounty(stakedao_logic, mock_stakedao_market, mock_crvusd):
    stakedao_logic.internal.create_bounty(
        gauge := boa.env.generate_address(),
        400,
        1234
    )

    assert mock_stakedao_market.creation_gauge() == gauge
    assert mock_stakedao_market.creation_manager() == stakedao_logic.address
    assert mock_stakedao_market.creation_rewardToken() == mock_crvusd.address
    assert mock_stakedao_market.creation_numberOfPeriods() == 2
    assert mock_stakedao_market.creation_maxRewardPerVote() == 1234
    assert mock_stakedao_market.creation_totalRewardAmount() == 400
    assert mock_stakedao_market.eval("len(self.creation_blacklist)") == 0
    assert mock_stakedao_market.creation_upgradeable() == False


def test_increase_bounty_duration(stakedao_logic, mock_stakedao_market):
    gauge = boa.env.generate_address()
    random_id = 43958
    stakedao_logic.eval(f"self.bounty_id[{gauge}] = {random_id}")
    stakedao_logic.internal.increase_bounty_duration(
        gauge,
        400,
        1234
    )

    assert mock_stakedao_market.increase_bountyId() == random_id
    assert mock_stakedao_market.increase_additionalPeriods() == 2
    assert mock_stakedao_market.increase_increasedAmount() == 400
    assert mock_stakedao_market.increase_newMaxPricePerVote() == 1234


def test_bribe(stakedao_logic, mock_stakedao_market, mock_crvusd, manager):
    encoder_source = """
    @external
    def encode(max_amount_per_vote: uint256) -> Bytes[32]:
        return abi_encode(max_amount_per_vote)
    """

    random_gauge = boa.env.generate_address()
    random_id = 43958
    encoder = boa.loads(encoder_source)
    max_amount_per_vote = 12345
    encoded_max_amount_per_vote = encoder.encode(max_amount_per_vote)

    leftover_crvusd = 10 ** 18

    mock_crvusd.mint_for_testing(stakedao_logic, leftover_crvusd)

    with boa.env.prank(manager.address):
        stakedao_logic.bribe(
            400,
            random_gauge,
            bytes(encoded_max_amount_per_vote)
        )

    stakedao_logic.eval(f"self.bounty_id[{random_gauge}] = {random_id}")

    assert mock_stakedao_market.creation_gauge() == random_gauge
    assert mock_stakedao_market.creation_manager() == stakedao_logic.address
    assert mock_stakedao_market.creation_rewardToken() == mock_crvusd.address
    assert mock_stakedao_market.creation_numberOfPeriods() == 2
    assert (mock_stakedao_market.creation_maxRewardPerVote() ==
            max_amount_per_vote)
    assert mock_stakedao_market.creation_totalRewardAmount() == 400
    assert mock_stakedao_market.eval("len(self.creation_blacklist)") == 0
    assert mock_stakedao_market.creation_upgradeable() == False

    # this part should be uninitialized after the first call
    assert mock_stakedao_market.increase_bountyId() == 0
    assert mock_stakedao_market.increase_additionalPeriods() == 0
    assert mock_stakedao_market.increase_increasedAmount() == 0
    assert mock_stakedao_market.increase_newMaxPricePerVote() == 0

    # cleaning dust
    assert mock_crvusd.balanceOf(stakedao_logic.address) == 0
    assert mock_crvusd.balanceOf(manager.address) == leftover_crvusd

    # we test for a second call because this time the bounty already exists
    increase_max_amount_per_vote = 54321
    increase_amount = 401
    encoded_increase_max_amount_per_vote = encoder.encode(
        increase_max_amount_per_vote)
    mock_crvusd.mint_for_testing(stakedao_logic, leftover_crvusd)

    with boa.env.prank(manager.address):
        stakedao_logic.bribe(
            increase_amount,
            random_gauge,
            bytes(encoded_increase_max_amount_per_vote)
        )

    assert mock_stakedao_market.increase_bountyId() == random_id
    assert mock_stakedao_market.increase_additionalPeriods() == 2
    assert mock_stakedao_market.increase_increasedAmount() == increase_amount
    assert (mock_stakedao_market.increase_newMaxPricePerVote() ==
            increase_max_amount_per_vote)

    # cleaning dust
    assert mock_crvusd.balanceOf(stakedao_logic.address) == 0
    assert mock_crvusd.balanceOf(manager.address) == leftover_crvusd * 2


def test_bribe_unauthorized(stakedao_logic):
    with boa.reverts("ownable: caller is not the owner"):
        stakedao_logic.bribe(400, boa.env.generate_address(), bytes())
