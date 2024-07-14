import boa
from pytest import fixture


@fixture
def crvusd():
    return "0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E"


@fixture
def client(crvusd):
    from contracts.automation import autobribe
    # TODO not both crvusd
    return autobribe(crvusd, crvusd)


@fixture
def manager(crvusd):
    from contracts.manual import IncentivesManager
    return IncentivesManager(crvusd)


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
def manager_initialized(manager, bribe_poster, bribe_manager, token_rescuer,
                        emergency_admin):
    manager.initialize(bribe_poster, bribe_manager, token_rescuer,
                       emergency_admin)
    return manager


@fixture
def mock_voting_market():
    return boa.load("test/mocks/MockVotingMarket.vy")


@fixture()
def manager_mock_voting_market(manager_initialized, mock_voting_market,
                               bribe_manager):
    m = manager_initialized
    with boa.env.prank(bribe_manager):
        m.set_bribe_logic(mock_voting_market)
    return m
