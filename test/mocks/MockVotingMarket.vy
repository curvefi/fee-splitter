# pragma version ~=0.4.0

from contracts.manual import IBribeLogic

implements: IBribeLogic
received_amount: public(uint256)
received_gauge: public(address)
received_data: public(Bytes[1024])

@external
def bribe(amount: uint256, gauge: address, data: Bytes[1024]):
    self.received_amount = amount
    self.received_gauge = gauge
    self.received_data = data
