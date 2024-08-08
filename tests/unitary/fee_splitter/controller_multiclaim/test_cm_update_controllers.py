import boa


def test_expected_behavior(multiclaim, mock_factory):
    factory = mock_factory
    controllers = []
    N_CONTROLLERS = 3

    def controllers_len():
        """helper to get length of controllers in multiclaim"""
        return multiclaim.eval('len(self.controllers)')

    def assert_controllers_match():
        """helper to assert controllers in multiclaim and factory match"""
        for i in range(controllers_len()):
            assert multiclaim.controllers(i) == controllers[
                i] == factory.controllers(i)
            assert multiclaim.allowed_controllers(controllers[i])

    def assert_controllers_length(expected):
        """helper to assert controllers length in multiclaim"""
        assert controllers_len() == expected == len(controllers)

    # at the start, there should be no controllers
    assert_controllers_length(0)
    assert_controllers_match()

    # we add N_CONTROLLERS controllers to the factory
    for i in range(N_CONTROLLERS):
        controllers.append(c := boa.env.generate_address())
        factory.add_controller(c)

    # we update the controllers in the multiclaim
    multiclaim.update_controllers()

    # we make sure that multiclaim and factory controllers match
    assert_controllers_length(N_CONTROLLERS)
    assert_controllers_match()

    # we add some more controllers to the factory
    for i in range(N_CONTROLLERS):
        controllers.append(c := boa.env.generate_address())
        factory.add_controller(c)

    # we update the controllers in the multiclaim
    multiclaim.update_controllers()

    # we make sure that multiclaim and factory controllers match
    assert_controllers_length(2 * N_CONTROLLERS)
    assert_controllers_match()
