# pragma version ~=0.4.0

from ethereum.ercs import IERC165

implements: IERC165

weight: public(uint256)

@external
def set_weight(amount: uint256):
    self.weight = amount

@view
@external
def supportsInterface(interfaceId: bytes4) -> bool:
    return True
