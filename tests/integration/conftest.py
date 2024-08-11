import os

from pytest import fixture
import boa
from boa.environment import Env
import address_book as ab

@fixture(scope="module")
def rpc_url():
    return os.environ.get("MAINNET_ENDPOINT") or "https://rpc.ankr.com/eth"

@fixture(scope="module", autouse=True)
def forked_env(rpc_url):
    with boa.swap_env(Env()):
        block_id = 18801970  # some block we know the state of
        boa.env.fork(rpc_url, block_identifier=block_id)
        yield

@fixture(scope="module")
def factory():
    # mock is good enough as the interface matches the real one
    controller_factory = boa.load_partial("contracts/testing/ControllerFactoryMock.vy")
    return controller_factory.at(ab.controller_factory)

@fixture(scope="module")
def incentives_manager():
    # this contract is not live yet so
    # we can mock it
    return boa.env.generate_address()

@fixture(scope="module")
def dao():
    return boa.env.generate_address()

@fixture(scope="module")
def fee_splitter(incentives_manager, dao):
    return boa.load("contracts/FeeSplitter.vy",
                    ab.crvusd,
                    ab.controller_factory,
                    3_456,
                    ab.fee_collector,
                    incentives_manager,
                    dao)

@fixture(scope="module")
def fee_splitter_with_controllers(fee_splitter):
    fee_splitter.update_controllers()
    return fee_splitter