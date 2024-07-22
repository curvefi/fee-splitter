import boa
from pytest import fixture


@fixture
def mock_erc20():
    from tests.mocks import MockERC20
    return MockERC20()


@fixture
def bribe_poster():
    return boa.env.generate_address()


@fixture
def bribe_manager():
    return boa.env.generate_address()


@fixture
def token_rescuer():
    return boa.env.generate_address()


@fixture
def emergency_admin():
    return boa.env.generate_address()


@fixture
def manager(mock_erc20, bribe_poster, bribe_manager, token_rescuer, emergency_admin):
    from contracts.manual import IncentivesManager
    return IncentivesManager(mock_erc20, bribe_manager, bribe_poster, token_rescuer, emergency_admin)


@fixture
def mock_voting_market(mock_erc20, manager):
    from tests.mocks import MockVotingMarket
    return MockVotingMarket(mock_erc20, manager)


@fixture()
def manager_mock_voting_market(manager, mock_voting_market,
                               bribe_manager):
    m = manager
    with boa.env.prank(bribe_manager):
        m.set_bribe_logic(mock_voting_market)
    return m
