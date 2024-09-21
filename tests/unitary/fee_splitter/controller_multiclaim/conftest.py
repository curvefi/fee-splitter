import boa
import pytest


@pytest.fixture(scope="module")
def multiclaim_deployer():
    return boa.load_partial("contracts/ControllerMulticlaim.vy")


@pytest.fixture(scope="module")
def multiclaim(multiclaim_deployer, mock_factory):
    return multiclaim_deployer(mock_factory)


@pytest.fixture(scope="module")
def multiclaim_with_controllers(
    multiclaim, mock_factory, mock_controller_deployer, erc20_deployer
):
    mock_controllers = [
        mock_controller_deployer(erc20_deployer()) for _ in range(10)
    ]
    for c in mock_controllers:
        mock_factory.add_controller(c)

    multiclaim.update_controllers()
    return multiclaim, mock_controllers
