import boa
from pytest import fixture

@fixture
def crvusd():
    return "0xf939E0A03FB07F59A73314E73794Be0E57ac1b4E"

@fixture
def client():
    from contracts import autobribe
    return autobribe("0x9c6f7A3117c9E83b8083563f026E08E907c95e3C", "0x9c6f7A3117c9E83b8083563f026E08E907c95e3C")

@fixture
def manager(crvusd):
    from contracts.manual import IncentivesManager
    return IncentivesManager(crvusd)