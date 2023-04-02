# JESD204B Receiver
This repository contains implementation of JESD204B standard (https://www.jedec.org/sites/default/files/docs/JESD204B.pdf) receiver in VHDL-2008.
It contains implementation of data link layer and transport layer.
It expects data from a transceivers at its input and outputs samples.
As application layer is application specific, it's not included here.
Care has been taken to allow resetting the link from application layer
as well as passing some errors to the application layer so that it can decide
whether to request resynchronization.

There are entities that may be used for multipoint links as well as entities for single link.

The receiver supports subclass 0 and 1. It generates LMFC from SYSREF using a counter,
if subclass 1 is used.

TODO: add small documentation here. In the meantime, you can check out the testbenches
for some example usage.
