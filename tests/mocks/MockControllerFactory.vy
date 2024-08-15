# pragma version ~=0.4.0

n_collaterals: public(uint256)
controllers: public(DynArray[address, 10000])

@external
def add_controller(controller: address):
    self.controllers.append(controller)
    self.n_collaterals = len(self.controllers)

@external
def set_fee_receiver(fee_receiver: address):
    pass
