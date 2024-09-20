import boa
from pytest import fixture


@fixture(scope="module")
def erc20_deployer():
    return boa.load_partial("tests/mocks/MockERC20.vy")
