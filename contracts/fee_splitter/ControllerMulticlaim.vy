# pragma version ~=0.4.0

import ControllerFactory
import Controller

factory: immutable(ControllerFactory)

allowed_controllers: public(HashMap[Controller, bool])
controllers: public(DynArray[Controller, MAX_CONTROLLERS])

# maximum number of claims in a single transaction
MAX_CONTROLLERS: constant(uint256) = 100

@deploy
def __init__(_factory: ControllerFactory):
    assert _factory.address != empty(address), "zeroaddr: factory"

    factory = _factory

def claim_controller_fees(controllers: DynArray[Controller, MAX_CONTROLLERS]):
    if len(controllers) == 0:
        for c: Controller in self.controllers:
            extcall c.collect_fees()
    else:
        for c: Controller in controllers:
            if not self.allowed_controllers[c]:
                raise "controller: not in factory"
            extcall c.collect_fees()

@nonreentrant
@external
def update_controllers():
    """
    @notice Update the list of controllers so that it corresponds to the
        list of controllers in the factory
    """
    old_len: uint256 = len(self.controllers)
    new_len: uint256 = staticcall factory.n_collaterals()
    for i: uint256 in range(new_len - old_len, bound=MAX_CONTROLLERS):
        i_shifted: uint256 = i + old_len
        c: Controller = Controller(staticcall factory.controllers(i_shifted))
        self.allowed_controllers[c] = True
        self.controllers.append(c)
