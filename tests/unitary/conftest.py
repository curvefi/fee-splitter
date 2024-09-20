import boa
from pytest import fixture


@fixture(scope="module")
def crvusd():
    return boa.load("tests/mocks/MockERC20.vy")
