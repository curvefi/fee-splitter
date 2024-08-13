import os

import address_book as ab
import boa
from boa.environment import Env
from pytest import fixture


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
    from tests.mocks import MockControllerFactory

    return MockControllerFactory.at(ab.controller_factory)


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
    from contracts.fee_splitter import FeeSplitter

    return FeeSplitter(
        ab.crvusd,
        ab.controller_factory,
        [(boa.env.generate_address(), 10_000, False)],
        dao,
    )


@fixture(scope="module")
def fee_splitter_with_controllers(fee_splitter):
    fee_splitter.update_controllers()
    return fee_splitter


@fixture(scope="module")
def crvusd():
    from tests.mocks import MockERC20

    return MockERC20.at(ab.crvusd)
