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
def bribe(amount: uint256, gauge: address, data: Bytes[1024]):
    self.received_amount = amount
    self.received_gauge = gauge
    self.received_data = data

    balance: uint256 = staticcall self.token.balanceOf(self)
    extcall self.token.transfer(self.manager, balance)
    print("BALANCE LEFT")
    print(staticcall self.token.balanceOf(self))
