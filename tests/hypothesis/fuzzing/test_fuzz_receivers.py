import boa
from hypothesis import given, settings

from tests.hypothesis.strategies import fee_splitters, receivers

settings.load_profile("debug")


@given(fs=fee_splitters(), rs=receivers())
def test_receivers(fs, rs):
    zero = boa.eval("empty(address)")

    with boa.env.prank(fs.owner()):
        fs.set_receivers(rs)

    total_weight = 0
    for i in range(fs.n_receivers()):
        addr, weight = fs.receivers(i)
        assert addr != zero
        assert 0 < weight <= 10_000
        total_weight += weight

    assert total_weight == 10_000

    expected_excess_receiver = rs[-1][0]

    assert fs.n_receivers() > 0
    assert len(rs) == fs.n_receivers()

    # we do some additional receiver check since
    # DynArray have been a weak spot for vyper historically
    assert fs.excess_receiver() == expected_excess_receiver
    assert fs.receivers(len(rs) - 1)[0] == expected_excess_receiver
