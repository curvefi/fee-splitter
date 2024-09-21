# Fee Splitter

Reinvesting crvUSD revenue to support its growth.

# Background

Previously, Curve redistributed 100% of its revenues to veCRV holders. This project explores a new design where a percentage of crvUSD-generated revenues are reinvested to support the protocol's growth. veCRV holders still decide who's is allowed to receive the fees through governance.

# Fee Splitter

A smart contract system for collecting and distributing fees from Curve's crvUSD controllers.

## Overview

The Fee Splitter project introduces a new mechanism for distributing crvUSD-generated revenues. Instead of redistributing 100% of revenues to veCRV holders, this system allows for a portion of the fees to be shared with protocol-aligned voters and other strategic initiatives.

## Key Components

### FeeSplitter Contract

The main contract responsible for collecting fees from multiple crvUSD controllers and distributing them according to predefined weights.

Key features:
- Supports both fixed and dynamic weight receivers. Fixed weight receivers have a predetermined share of the fees, while dynamic weight receivers can adjust their share based on certain conditions.
- Allows for updating the list of receivers
- Owned by a designated address (likely DAO-controlled)

### ControllerMulticlaim Module

A helper module integrated into the FeeSplitter to efficiently claim fees from multiple controllers simultaneously.

Key features:
- Maintains a list of allowed controllers
- Can claim fees from all controllers or a specified subset

### Testing Suite

The project includes a comprehensive testing suite:

- Unit tests for individual contract functions
- Integration tests for full contract interactions
- Hypothesis-based stateful tests for more robust scenario coverage

## Development Setup

1. Install dependencies:
   ```
   poetry install
   ```

2. Run tests:
   ```
   pytest tests/unitary
   pytest tests/integration
   pytest tests/hypothesis
   ```

3. For deployment scripts and interactions, see the `scripts/` directory.

# Audit

The contract is currently under audit by Chainsecurity.

## Contract Deployment

The `scripts/deploy_fee_splitter.ipynb` Jupyter notebook provides a step-by-step process for deploying the FeeSplitter contract and setting up the initial configuration.

## Autobribe

This codebase used to be home to autobribe, a protocol that never saw the light of day. Its **unfinished** code can still be found [here](https://github.com/curvefi/fee-splitter/tree/autobribe).

## Security

This project is developed by Curve.fi. For any security-related issues, please contact security@curve.fi.

## License

Copyright (c) Curve.Fi, 2020-2024 - all rights reserved
