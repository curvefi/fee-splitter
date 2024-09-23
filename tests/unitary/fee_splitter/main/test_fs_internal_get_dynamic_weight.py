import textwrap

import boa
import pytest


@pytest.fixture(scope="module")
def mock_dynamic_weight(mock_dynamic_weight_deployer):
    return mock_dynamic_weight_deployer()

@pytest.fixture(scope="module")
def mock_reverting_weight():
    source = textwrap.dedent("""
    # pragma version ~=0.4.0

    @view
    @external
    def weight() -> uint256:
        raise "Always reverts"
    """)

    return boa.loads(source)



def test_default_behavior(fee_splitter, mock_dynamic_weight):
    mock_dynamic_weight.set_weight(5000)
    weight = fee_splitter.internal._get_dynamic_weight(mock_dynamic_weight)
    assert weight == 5000


def test_get_dynamic_weight_revert(fee_splitter, mock_reverting_weight):
    weight = fee_splitter.internal._get_dynamic_weight(mock_reverting_weight)
    assert weight == 0