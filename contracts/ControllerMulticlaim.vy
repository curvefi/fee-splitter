# pragma version ~=0.4.0

"""
@title ControllerMulticlaim
@notice Helper module to claim fees from multiple
controllers at the same time.
@license Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
@author curve.fi
@custom:security security@curve.fi
"""

from contracts.interfaces import IControllerFactory
from contracts.interfaces import IController

factory: immutable(IControllerFactory)

allowed_controllers: public(HashMap[IController, bool])
controllers: public(DynArray[IController, MAX_CONTROLLERS])

# maximum number of claims in a single transaction
MAX_CONTROLLERS: constant(uint256) = 50


@deploy
def __init__(_factory: IControllerFactory):
    assert _factory.address != empty(address), "zeroaddr: factory"

    factory = _factory


def claim_controller_fees(controllers: DynArray[IController, MAX_CONTROLLERS]):
    """
    @notice Claims admin fees from a list of controllers.
    @param controllers The list of controllers to claim fees from.
    @dev For the claim to succeed, the controller must be in the list of
        allowed controllers. If the list of controllers is empty, all
        controllers in the factory are claimed from.
    """
    if len(controllers) == 0:
        for c: IController in self.controllers:
            extcall c.collect_fees()
    else:
        for c: IController in controllers:
            if not self.allowed_controllers[c]:
                raise "controller: not in factory"
            extcall c.collect_fees()


@nonreentrant
@external
def update_controllers():
    """
    @notice Update the list of controllers so that it corresponds to the
        list of controllers in the factory.
    @dev The list of controllers can only add new controllers from the
        factory when updated.
    """
    old_len: uint256 = len(self.controllers)
    new_len: uint256 = staticcall factory.n_collaterals()
    for i: uint256 in range(old_len, new_len, bound=MAX_CONTROLLERS):
        c: IController = IController(staticcall factory.controllers(i))
        self.allowed_controllers[c] = True
        self.controllers.append(c)


@view
@external
def n_controllers() -> uint256:
    return len(self.controllers)
