import boa
from pytest import fixture
@fixture(scope="module")
def bribe_proposer():
    return boa.env.generate_address()


@fixture(scope="module")
def bribe_manager():
    return boa.env.generate_address()


@fixture(scope="module")
def token_rescuer():
    return boa.env.generate_address()


@fixture(scope="module")
def emergency_admin():
    return boa.env.generate_address()

@fixture(scope="module")
def erc20_deployer():
    from tests.mocks import MockERC20
    return MockERC20
