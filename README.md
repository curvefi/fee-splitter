# Autobribe

Procotol aligned CRV emissions.

# Background

Previously, Curve redistributed 100% of its revenues to veCRV holders. This project explores a new design where a percentage of crvUSD-generated revenues are shared with protocol-aligned voters.

# Overview

Curve Pools and Llamalend Vaults containing crvUSD automatically receive bribes paid in crvUSD, generated by the minting markets.

This makes crvUSD a desirable token for pairing on Curve, as it provides free emissions to pools containing it, proportional to the average amount in the pool. Additionally, incentivizing crvUSD-based pools significantly increases the efficiency multiplier of the bribe.

# Defintions
The contracts use the terms "bribes," "voting incentives," and "bounties" interchangeably to refer to the action of granting rewards when a veCRV holder votes for a designated gauge.

# Trust assumptions

The initial version of Autobribes (in manual) relies on a trusted third party to post bribe amounts and make decisions (under strict control of the DAO, which can enforce caps and oversee operations).

Currently, bribe posting and rewards distribution are outsourced to a third-party votes marketplace.

Research and development is in progress to make the incentives posting process more transparent and automated. The goal is to allow anyone to obtain incentives without interacting with protocol contributors, requiring only a vote to create the gauge and whitelist it for auto-bribing.
