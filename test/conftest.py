import boa
from pytest import fixture

@fixture
def client():
    from contracts import autobribe
    return autobribe("0x9c6f7A3117c9E83b8083563f026E08E907c95e3C", "0x9c6f7A3117c9E83b8083563f026E08E907c95e3C")