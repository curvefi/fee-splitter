import random

import boa

# even if compilation is cached by boa, `load`/`load_partial` should
# never be used inside the strategies as it hurts test speed.
factory_deployer = boa.load_partial("tests/mocks/MockControllerFactory.vy")
fee_splitter_deployer = boa.load_partial("contracts/FeeSplitter.vy")
controller_deployer = boa.load_partial("tests/mocks/MockController.vy")
dynamic_weight_deployer = boa.load_partial("tests/mocks/MockDynamicWeight.vy")


def generate_random_weight(center, min_val=1, max_val=10000):
    # Ensure center is within the valid range
    center = max(min_val, min(center, max_val))

    while True:
        # Generate a random value using a normal distribution
        value = random.gauss(center, (max_val - min_val) / 6)

        # Round to the nearest integer
        value = round(value)

        # Check if the value is within the desired range
        if min_val < value <= max_val:
            return value
