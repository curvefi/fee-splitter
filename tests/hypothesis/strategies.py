import boa
from boa.test import strategy as boa_st
from hypothesis.strategies import (
    booleans,
    builds,
    composite,
    integers,
    just,
    lists,
)

from tests.hypothesis.utils import (
    controller_deployer,
    dynamic_weight_deployer,
    factory_deployer,
    fee_splitter_deployer,
)

MAX_BPS = 10_000
ZERO = boa.eval("empty(address)")

addresses = boa_st("address").filter(lambda addr: addr != ZERO)


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
            mock_dynamic_weight = dynamic_weight_deployer()
            receivers_list.append(
                (mock_dynamic_weight.address, _weights[i], True)
            )
        else:
            receivers_list.append(
                (boa.env.generate_address(), _weights[i], False)
            )

    return receivers_list


crvusd = just(boa.load("tests/mocks/MockERC20.vy"))


@composite
def fee_splitters(draw):
    _crvusd = draw(crvusd)

    _factory = factory_deployer()
    # remove the bool flag as it's not required by the constructor
    _receivers = [(r[0], r[1]) for r in draw(receivers())]
    _owner = draw(addresses)

    return fee_splitter_deployer(_crvusd, _factory, _receivers, _owner)


controllers = builds(controller_deployer, crvusd)


if __name__ == "__main__":
    print(fee_splitters().example())
