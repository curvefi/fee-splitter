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
def bribe(gauge: address, amount: uint256, data: Bytes[1024]):
    self.received_amount = amount
    self.received_gauge = gauge
    self.received_data = data

    balance: uint256 = staticcall self.token.balanceOf(self)

    # this is just to mock a failure case by passing
    # a non-empty data payload
    if data == empty(Bytes[1024]):
        extcall self.token.transfer(self.manager, balance)

@external
@view
def supportsInterface(interface_id: bytes4) -> bool:
    """
    @dev Returns `True` if this contract implements the
         interface defined by `interface_id`.
    @param interface_id The 4-byte interface identifier.
    @return bool The verification whether the contract
            implements the interface or not.
    """
    # TODO implement this
    return True