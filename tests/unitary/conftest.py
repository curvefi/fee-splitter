import boa
from pytest import fixture


@fixture(scope="module")
def crvusd():
    from tests.mocks import MockERC20
    return MockERC20()



@fixture(scope="module")
def generic_voting_market(crvusd, manager):
    from tests.mocks import MockBribeLogic
    return MockBribeLogic(crvusd, manager)


@fixture(scope="module")
def manager_with_voting_market(manager, generic_voting_market,
                               bribe_manager):
    m = manager
    with boa.env.prank(bribe_manager):
        m.set_bribe_logic(generic_voting_market)
    return m

@fixture(scope="module")
def stakedao_market():
    from tests.mocks import MockStakeDaoMarket
    return MockStakeDaoMarket()

@fixture(scope="module")
def stakedao_logic(crvusd, stakedao_market, manager):
    from contracts.markets import StakeDaoLogic
    return StakeDaoLogic(crvusd, stakedao_market, manager)


@fixture(scope="module")
def manager(crvusd, bribe_poster, bribe_manager, token_rescuer, emergency_admin):
    from contracts.manual import IncentivesManager
    return IncentivesManager(crvusd, bribe_manager, bribe_poster, token_rescuer, emergency_admin)
