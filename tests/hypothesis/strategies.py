from boa.contracts.vyper.vyper_contract import VyperContract
from hypothesis import assume
from hypothesis.strategies import composite, just, integers, lists, booleans
import boa
from boa.test import strategy as boa_st
from tests.mocks import MockDynamicWeight, MockControllerFactory, MockERC20, MockController
from contracts.fee_splitter import FeeSplitter


address = boa_st("address")

max_bps = 10_000
zero = boa.eval("empty(address)")


@composite
def weights(draw, n):
    @composite
    def sorted_unique_integers(draw):
        # Generate n-1 unique integers between 1 and max_bps-1
        points = draw(lists(integers(1, max_bps - 1),
                               min_size=n - 1,
                               max_size=n - 1,
                               unique=True))
        return sorted(points)

    # Draw the sorted unique integers
    points = draw(sorted_unique_integers())

    # Add start and end points
    points = [0] + points + [max_bps]

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
            receivers_list.append((MockDynamicWeight().address, _weights[i], True))
        else:
            receiver_address = draw(address)
            assume(receiver_address != zero)
            receivers_list.append((draw(address), _weights[i], False))

    return receivers_list

crvusd = just(MockERC20())

@composite
def fee_splitters(draw):
    _crvusd = draw(crvusd)

    _factory = MockControllerFactory()
    _receivers = draw(receivers())
    _owner = draw(address)
    assume(_owner != zero)

    return FeeSplitter(_crvusd, _factory, _receivers, _owner)

@composite
def controllers(draw):
    _crvusd = draw(crvusd)
    return MockController(_crvusd)

if __name__ == "__main__":
    print(controllers().example())
