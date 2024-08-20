# Testing with hypothesis
The test suits in this folder use hypothesis. They are intentionally isolated from the pytest fixtures since the interaction within the two frameworks can sometimes be unreliable.

Do not mix fixtures with hypothesis strategies when testing.
