from pytest import fixture

@fixture
def multiclaim_deployer():
    from contracts.fee_splitter import ControllerMulticlaim
    return ControllerMulticlaim


@fixture
def multiclaim(multiclaim_deployer, mock_factory):
    return multiclaim_deployer(mock_factory)

@fixture
def multiclaim_with_controllers(multiclaim, mock_factory, mock_controller_deployer):
    mock_controllers = [mock_controller_deployer() for _ in range(10)]
    for c in mock_controllers:
        mock_factory.add_controller(c)

    multiclaim.update_controllers()
    return multiclaim, mock_controllers