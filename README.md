# Logisym-SiliconSprint_NPU_Microcore.
Our submission for the Silicon Sprint competition round 2 and finals, by IEEE NIT Surathkal and RV College of Engg. , sponsored by Tenstorrent.

- PPT Viewing Link: https://www.canva.com/design/DAG4GbnyW-4/KLqI6IlAsPWu63swpBeNJQ/view?utm_content=DAG4GbnyW-4&utm_campaign=designshare&utm_medium=link2&utm_source=uniquelinks&utlId=h5c85803f44

- Try the simulation in EDAPlayground: https://edaplayground.com/x/Pe47

<img width="1629" height="480" alt="image" src="https://github.com/user-attachments/assets/cb1efddd-a8e6-4b03-a2f1-1e3d0434d45f" />

---

### Synthesis

<img width="9044" height="13523" alt="svgviewer-png-output" src="https://github.com/user-attachments/assets/d969e741-4a3f-46c5-a092-9984da9db680" />

---

## Area reports

| Metric                | ABC (Tech-Agnostic) | PDK Synthesis (Pre-Crash) | Difference               |
| --------------------- | ------------------- | ------------------------- | ------------------------ |
| Total Cells           | 668                 | 729                       | +61 cells (+9.1%)        |
| Wires                 | 623                 | 684                       | +61 wires (+9.8%)        |
| Wire Bits             | 689                 | 750                       | +61 bits (+8.9%)         |
| Public Wires          | 12                  | 12                        | No change                |
| Ports                 | 12                  | 12                        | No change                |
| Estimated Transistors | 4254+               | N/A                       | PDK crashed before count |

| Cell Type    | ABC Synthesis | PDK Synthesis | Delta | % Change |
| ------------ | ------------- | ------------- | ----- | -------- |
| $_ANDNOT_    | 30            | 26            | -4    | -13.3%   |
| $_AND_       | 28            | 23            | -5    | -17.9%   |
| $_DFFE_PP0P_ | 20            | 20            | 0     | 0%       |
| $_DFF_PP0_   | 18            | 18            | 0     | 0%       |
| $_MUX_       | 1             | 0             | -1    | -100%    |
| $_NAND_      | 40            | 53            | +13   | +32.5%   |
| $_NOR_       | 257           | 304           | +47   | +18.3%   |
| $_NOT_       | 27            | 15            | -12   | -44.4%   |
| $_ORNOT_     | 42            | 26            | -16   | -38.1%   |
| $_OR_        | 10            | 8             | -2    | -20.0%   |
| $_XNOR_      | 171           | 222           | +51   | +29.8%   |
| $_XOR_       | 24            | 14            | -10   | -41.7%   |

Gate Distribution Changes:
- NOR gates: Increased by 18.3% (257 → 304) - largest absolute increase
- XNOR gates: Increased by 29.8% (171 → 222) - largest percentage increase
- Sequential elements (DFF/DFFE): Remained constant at 38 cells total
- MUX: Eliminated in PDK mapping (1 → 0)

PDK Attempt:
- Tools tested: Skywater 130nm PDK, ASAP7 7nm PDK
- Status: Both crashed with Liberty file parsing errors
- Root cause: Windows-specific line ending issues in Yosys Liberty parser
- Decision: Proceeded with ABC tech-agnostic synthesis

Area Estimation
Using cell-based area calculation with generic 130nm values:
- ABC Synthesis: ~57,065 µm² (668 cells)
- PDK Synthesis (projected): ~60,000-65,000 µm² (729 cells, extrapolated)

PDKs Attempted:
- Skywater 130nm (Google + SkyWater)
- ASAP7 7nm (ASU Predictive PDK)
Synthesis Tool: Yosys 0.58

