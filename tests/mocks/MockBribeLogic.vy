# pragma version ~=0.4.0

from ethereum.ercs import IERC20

from contracts.manual import IBribeLogic

implements: IBribeLogic
token: IERC20
manager: address
received_amount: public(uint256)
received_gauge: public(address)
received_data: public(Bytes[1024])

@deploy
def __init__(token: address, manager: address):
    self.token = IERC20(token)
    self.manager = manager

@external
def bribe(gauge: address, amount: uint256, data: Bytes[1024]) -> uint256:
    self.received_amount = amount
    self.received_gauge = gauge
    self.received_data = data

    balance: uint256 = staticcall self.token.balanceOf(self)

    # this is just to mock a failure case by passing
    # a non-empty data payload
    if data == empty(Bytes[1024]):
        extcall self.token.transfer(self.manager, balance)

    return 564839