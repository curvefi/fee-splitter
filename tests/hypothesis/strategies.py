import boa
from boa.test import strategy as boa_st
from hypothesis import assume
from hypothesis.strategies import (
    booleans,
    builds,
    composite,
    integers,
    just,
    lists,
)

address = boa_st("address")

MAX_BPS = 10_000
ZERO = boa.eval("empty(address)")


@composite
def weights(draw, n):
    # Generate n-1 unique integers between 1 and max_bps-1
    points = sorted(
        draw(
            lists(
                integers(1, MAX_BPS - 1),
                min_size=n - 1,
                max_size=n - 1,
                unique=True,
            )
        )
    )

    # Add start and end points
    points = [0] + points + [MAX_BPS]

    # Calculate differences between adjacent points to get weights
    weights = [points[i + 1] - points[i] for i in range(n)]

    return weights


@composite
def receivers(draw, n=0):
    if n == 0:
        n = draw(integers(min_value=1, max_value=100))

    is_dynamic = draw(lists(booleans(), min_size=n, max_size=n))
    _weights = draw(weights(n))

    receivers_list = []
    for i in range(n):
        if is_dynamic[i]:
            mock_dynamic_weight = boa.load("tests/mocks/MockDynamicWeight.vy")
            receivers_list.append((mock_dynamic_weight.address, _weights[i]))
        else:
            receiver_address = draw(address)
            assume(receiver_address != ZERO)
            receivers_list.append((draw(address), _weights[i]))

    return receivers_list


crvusd = just(boa.load("tests/mocks/MockERC20.vy"))


@composite
def fee_splitters(draw):
    _crvusd = draw(crvusd)

    _factory = boa.load("tests/mocks/MockControllerFactory.vy")
    _receivers = draw(receivers())
    _owner = draw(address)
    assume(_owner != ZERO)

    return boa.load(
        "contracts/FeeSplitter.vy", _crvusd, _factory, _receivers, _owner
    )


controllers = builds(boa.load_partial("tests/mocks/MockController.vy"), crvusd)


if __name__ == "__main__":
    print(weights(123).example())
