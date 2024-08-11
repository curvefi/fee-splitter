# pragma version ~=0.4.0

collect_counter: uint256

# TODO integration testing for this
@external
def collect_fees() -> uint256:
    self.collect_counter += 1
    return self.collect_counter


@external
def admin_fees() -> uint256:
    return 5678

