# Submission Notes

This repository is simulation-only and contains:
- SystemVerilog RTL in `src/`
- Self-checking SystemVerilog testbenches in `verif/`
- Python fixed-point golden model in `scripts/`
- Documentation and SVG design/timing diagrams in `doc/`
- Root-level `README.md` with ModelSim/QuestaSim Linux commands

The default design uses DATA_W=8 and ACC_W=20 as specified.
Overflow logic is exercised with a reduced-width ACC_W=12 regression because the required 20-bit Q12.8 range cannot overflow for legal 8-bit Q4.4 inputs.
