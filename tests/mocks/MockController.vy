# pragma version ~=0.4.0

from ethereum.ercs import IERC20

collect_counter: uint256
mock_receiver: address

crvusd: IERC20

@deploy
def __init__(crvusd: IERC20):
    self.mock_receiver = convert(1, address)
    self.crvusd = crvusd

@external
def collect_fees() -> uint256:
    self.collect_counter += 1
    balance_of_self: uint256 = staticcall self.crvusd.balanceOf(self)
    extcall self.crvusd.transfer(self.mock_receiver, balance_of_self)
    return self.collect_counter

@external
def admin_fees() -> uint256:
    return 5678
