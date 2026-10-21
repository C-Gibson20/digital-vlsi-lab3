##### Imperial College London, Department of Electrical & Electronic Engineering


#### ELEC70142 Digital VLSI Design

### Lab 3 - Memory and Standard Cells together

##### *Peter Cheung, v3.0 - 22 October 2026*

---
### Objectives
---
By the end of this laboratory session, you should be able to do the following.
* Use TSMC's memory compiler tool to generate efficient memory.
* Build a reference library so that Fusion Compiler can use that memory as a hard macro.
* Integrate a block of logic implemented using standard cells with generated memory.
* Verify that the entire system works properly using simulation.
* Develop a built-in self-test circuit to detect possible error in the circuit.  
* Inject errors into the circuit to check that the automatic fault detection circuit works.

---
### Task 1 - Generate 32 x 32 SRAM
---

This task is about using TSMC's 65nm memory compiler tool to generate a SRAM block. The compiler is TSMC's own program, called **MC2**. It is delivered inside the PDK rather than by Synopsys or Cadence, so it is the same tool whichever vendor's flow you go on to use. You can find the documentation for it at:

```text
/eda/cadence_tools/kits/tsmc/beLibs/65nm/TSMCHOME/sram/Documentation/documents/
```

List the available documents with:

```bash
ls /eda/cadence_tools/kits/tsmc/beLibs/65nm/TSMCHOME/sram/Documentation/documents/
```

**Working directory and logs:** Run the lab commands from the directory containing this repository's `Makefile`, `scripts/` and `constraints/`. Paths such as `logs/`, `reports/`, `outputs/` and `work/` are relative to that directory. For example, if your lab is in `~/lab3`, the log directory is `~/lab3/logs/`. The build and simulation log paths below assume the V2 Makefile. Lab scripts are read from the local `scripts/` directory; the installed tools and PDK are supplied by the Synopsys environment.

**_Step 1: Launch the memory compiler_**

* Create a new directory for this lab, say `Lab_3`, and change to that directory.
* Load the tools and the PDK, exactly as in Labs 1 and 2:

```bash
synopsys tsmc65LP
cd Lab_3
```

* Launch TSMC's **Memory Compiler** with:

```bash
memcomp spsram
```

>The argument **_spsram_** generates a single port RAM with a write port with its own write address and data input, and one read port with its own read address and data out.
>The argument **_dpsram_** generates a dual port RAM with a single write port (own address and data), and two separate read ports.


* Click **_OK_** and **_Run MC2_** in the pop-up windows.

<p align="center"> <img src="diagrams/init.jpg" width="1000" height="250"> </p><BR>

**_Step 2: Specify configuration for the memory_**

1. In the dialogue box select "netlist" and click "Enter User Defined Configuration variable".
2. A form will popup with default memory parameters. Click **_Edit_**.
3. Change the variables to the following:
   * Number of Words = 32
   * Number of Bits = 32
   * Column Mux Ratio = 4
   * Name of Ground pin = VSS
   * BIST_Enable = no
   * Check that the memory parameters you selected match that in the diagram below.

<p align="center"> <img src="diagrams/parameters.jpg" width="1000" height="350"> </p><BR>

4. Set the operating point by clicking **_Other Options_** at the top to reveal the operating point selections. Click **_Next_**, and select **_tt1p2v25c_** to set the operating point to 1.2V and 25 degrees C.
5. Click **_OK_** then **_PREVIEW_**. You will see a bounding box showing the size of the memory produced by the memory compiler. Record the dimensions in your logbook.
6. In the Configuration window, click **_AutoName Memory_** button.
7. Select the **_Models_** option at the top and click **_Select ALL_** to generate the full set of models.
8. Finally, click **_Run_** to run the compiler. Then click **_Quit_** to exit the Memory Compiler programme.

Examine the directory for this lab and the files the memory compiler generated.

> In particular, examine the Verilog netlist for the memory block in `VERILOG/`. Record in your logbook the names of the input and output ports and their purposes.

**_Step 3: Build the reference library_**

Genus and Innovus read a memory's Liberty and LEF files directly. Fusion Compiler does not: it reads **NDM**, the same format as the standard cell library you checked in Lab 1. So before you can synthesise with the memory, it has to be built into one:

```bash
make sram
```

The V2 Makefile creates `logs/` automatically and saves the Library Compiler and Library Manager output, including warning and error details, in **`logs/sram.log`**. The terminal shows the Makefile header followed by the build result, warning/error counts and log path. The counts describe diagnostic lines recorded in the log; a tool may suppress repeated messages. Each run replaces this log.

To read the detailed log from the Linux shell, run:

```bash
less logs/sram.log
```

Press **q** to leave the log viewer. If the build reports `FAILED`, inspect this log before continuing.

>The `make sram` target runs two local scripts. `scripts/sram_lib.tcl` compiles the Liberty to a Synopsys database with Library Compiler, and `scripts/sram_ndm.tcl` builds the NDM from that and the LEF with Library Manager. They are separate because the two tools are separate executables.

For the memory configuration above, a successful build produces:

| File | Purpose |
|---|---|
| `ts1n65lpll32x32m4_220a/DB/ts1n65lpll32x32m4_220a.db` | Compiled timing and power library |
| `ts1n65lpll32x32m4_220a/NDM/ts1n65lpll32x32m4_220a.ndm` | SRAM reference library for Fusion Compiler |

Check the reference library in Fusion Compiler:

```bash
mkdir -p logs
fc_shell -output_log_file logs/sram_check.log
```

This saves the session output in `logs/sram_check.log`. At the `fc_shell>` prompt, run:

```tcl
open_lib ts1n65lpll32x32m4_220a/NDM/ts1n65lpll32x32m4_220a.ndm
get_attribute [get_lib_cells */TS1N65LPLL32X32M4] width
get_attribute [get_lib_cells */TS1N65LPLL32X32M4] height
```

Compare the reported width and height with the memory compiler's preview. The cell name is `TS1N65LPLL32X32M4`; the `_220a` suffix belongs to the generated directory and filenames.

Exit Fusion Compiler before entering the next Linux shell command:

```tcl
exit
```

**_Step 4 - Examine the layout of the memory block_**

>The following procedure imports the GDSII layout into the Custom Compiler layout editor. With it you can examine the layout the memory compiler produced.

* Launch Custom Compiler:

```bash
custom &
```
* Create a new library attached to tsmcn65, call it mem_lib.
* From the Custom Compiler window, use **_File -> Import -> Stream ..._**. An **_Import Stream_** dialogue box will open.

<p align="center"> <img src="diagrams/import_stream.png" width="630" height="695"> </p><BR>

* Fill in the **_Main_** tab and leave every other tab at its defaults:

| Section | Field | Value |
|---|---|---|
| Input | **_Run Directory_** | `.` |
| Input | **_Stream File_** | the `.gds` in your memory's `GDSII` folder |
| Input | **_Top Cell_** | `TS1N65LPLL32X32M4` |
| Output | **_Library_** | `mem_lib` |
| Output | **_Directory_** | `.` |
| Output | **_View_** | `layout` |
| Technology | | **_Attach_**, and pick `tsmcN65` from the dropdown |

* Click **_OK_**. 

* Open **_Tools -> Library Manager_**, select **_mem_lib_**, then the cell with your memory's name, and open its **_layout_** view.
* Press **_f_** to fit the layout in the window, then **_SHIFT-f_** to expand the hierarchy and show the mask layers inside each cell.
* Hide the `VIA1`, `VIA2` and `VIA3` layers to reveal the circuit underneath.

---
### Task 2 - Combine memory block with standard cell design
---

The purpose of this task is to synthesise a block of logic with **Fusion Compiler**, then place and route it **together** with the memory block from Task 1.

**_Step 1: Specify logic circuit in SystemVerilog_**

<p align="center"> <img src="diagrams/cct_1.jpg" width="1000" height="220"> </p><BR>

The block diagram shows the 32 x 32-bit SRAM created in Task 1 (name the instance `mem32x32`) surrounded by three modules:
1. A 5-bit address counter.
2. A 16-bit PRBS generator (from Lab 1). The random output from the PRBS generator is used as data to upper and lower 16-bit words of the memory.
3. A FSM that produces the necessary control signals. The FSM should write 32 words generated by the PRBS to fill the SRAM. It should then read the 32 words stored. Then it should write the next 32 words before reading them out etc..

>Note that CEB (Chip Enable) and WEB (Write Enable) signals are active low (hence the letter 'B').

Design these three modules in SystemVerilog and create a top-level design to combine these four blocks to implement the circuit shown.

Make a directory for them:

```bash
mkdir src
```

The scripts read four files by name, so use these:

| File | Module |
|---|---|
| `src/memtest.sv` | top level |
| `src/counter.sv` | 5-bit address counter |
| `src/control.sv` | FSM |
| `src/PRBS.sv` | 16-bit PRBS generator |

Your testbench goes in the same place, as `src/memtest_tb.sv`.


**_Step 2: Synthesize the design with Fusion Compiler_**

Run the local logical-synthesis script from the Linux shell:

```bash
mkdir -p logs
fc_shell -f scripts/syn_logical.tcl -output_log_file logs/syn_logical.log
```

This maps your RTL to standard cells while retaining the SRAM as a hard macro. Session output is displayed in the terminal and saved in **`logs/syn_logical.log`**. The `-output_log_file` option records the session; reports redirected by the script are written separately under **`reports/logical/`**. See the [Synopsys Fusion Compiler User Guide](https://www.scribd.com/document/856392865/fcug) for the session-log option.

On successful completion, the script writes:

| File or directory | Contents |
|---|---|
| `outputs/logical/memtest_synth.v` | Synthesised gate-level Verilog netlist, used by the next step and synthesis-level simulation |
| `outputs/logical/memtest_synth.sdc` | Exported synthesis constraints |
| `work/memtest_syn.dlib` | Saved logical-synthesis design library |

The synthesis reports are:

| Report | What to inspect |
|---|---|
| `reports/logical/synth_check.rpt` and `reports/logical/synth_check_netlist.log` | Design checks performed before technology mapping; unmapped RTL cells at this stage do not establish that the final netlist is unmapped |
| `reports/logical/synth_timing_max.rpt` | Maximum-delay paths and setup slack |
| `reports/logical/synth_timing_min.rpt` | Minimum-delay paths and hold slack |
| `reports/logical/synth_area.rpt` | Cell area |
| `reports/logical/synth_qor.rpt` | Quality-of-results summary, including timing and area |
| `reports/logical/synth_power.rpt` | Estimated power and any warnings emitted while generating the power report |

Check these two points before proceeding:

1. **The SRAM reference is available and the design links correctly.** In `logs/syn_logical.log`, check that the reference-library listing includes `ts1n65lpll32x32m4_220a.ndm` and investigate any unresolved references to `TS1N65LPLL32X32M4`.
2. **The clock constraints and timing results are meaningful.** The supplied SDC defines `clk` with a 2 ns period (500 MHz). Inspect `synth_timing_max.rpt` and `synth_qor.rpt` for timing violations. If the log reports no valid clocks or uses a default frequency, check the clock before accepting the timing or power results. A completed synthesis run alone does not establish that timing passes.

The script leaves you at the `fc_shell>` prompt. To check the clock and timing in the current design, run:

```tcl
current_scenario func_tc
report_clocks
check_timing
report_timing -delay_type max -max_paths 5
```

This diagnostic output is also recorded in `logs/syn_logical.log`. When you have finished inspecting the results, return to the Linux shell before starting Step 3:

```tcl
exit
```

**_Step 3: Place and route the synthesised netlist_**

Step 2 performed logical synthesis. This step reads `outputs/logical/memtest_synth.v` into a new physical design library, then performs floorplanning, placement, clock-tree synthesis and routing. The directory name `logical` identifies this two-step flow, including its physical layout. Timing constraints and derates are loaded again through `scripts/mcmm.tcl`.

From the Linux shell, run:

```bash
mkdir -p logs
fc_shell -f scripts/pnr.tcl -output_log_file logs/pnr.log
```

Session output is displayed in the terminal and saved in **`logs/pnr.log`**. Macro placement and power-grid setup are in `scripts/floorplan.tcl`; clock-tree synthesis, routing, final checks and export are in `scripts/backend.tcl`.

On successful completion, the flow produces:

| File or directory | Contents |
|---|---|
| `outputs/logical/memtest.gds` | GDSII layout with the standard-cell and SRAM geometry merged in; import this into Custom Compiler |
| `outputs/logical/memtest_layout.v` | Routed gate-level netlist for simulation |
| `outputs/logical/memtest_tc.sdf` | Delay data for layout-level simulation at the `tc` corner |
| `outputs/logical/memtest.def` | Placement and routing data |
| `outputs/logical/memtest.lef` | Physical abstract of the completed design |
| `outputs/logical/memtest_final.sdc` | Exported final timing constraints |
| `outputs/logical/` files with the `memtest` prefix | Extracted parasitic data written by `write_parasitics`; check the export messages in `logs/pnr.log` for the generated filenames |
| `work/memtest_logical.dlib` | Physical design library with saved floorplan, placement, clock-tree, routing and finish checkpoints |

Reports are saved in **`reports/logical/`**, alongside the synthesis reports. The stage prefixes are `place`, `cts`, `route` and `finish`. Each stage writes `_timing_max.rpt`, `_timing_min.rpt`, `_area.rpt`, `_qor.rpt` and `_power.rpt`; utilisation and congestion reports are also attempted where supported.

For the final result, begin with `finish_timing_max.rpt`, `finish_timing_min.rpt`, `finish_qor.rpt`, `finish_area.rpt` and `finish_power.rpt`. Also inspect these checks in the same directory:

| Report | Check |
|---|---|
| `finish_legality.rpt` | Placement legality |
| `finish_routes.rpt` | Routing violations |
| `finish_pg_drc.rpt` | Power-grid design-rule violations |
| `finish_pg_connectivity.rpt` | Power and ground connectivity |
| `finish_lvs.rpt` | In-tool layout-versus-netlist connectivity check |

Earlier checks are saved as `floorplan_pg_*.rpt`, `place_pre_check.rpt`, `place_check.log`, `place_legality.rpt`, `place_pg_*.rpt` and `route_check.rpt`. Clock-tree reports `cts_clock_qor.rpt` and `cts_clock_skew.rpt` are attempted where supported. Some checks report violations without stopping the script, so inspect their results even if the flow reaches the export step.

When the script finishes, it leaves the design open. At the `fc_shell>` prompt, display it with:

```tcl
start_gui
```

**Optional: run the physical-synthesis flow.** As in Lab 1 Task 5, you can instead process the RTL through physical synthesis and layout in one session. It uses the same floorplan. Start this from the Linux shell after exiting any previous Fusion Compiler session:

```bash
mkdir -p logs
fc_shell -f scripts/fusion.tcl -output_log_file logs/fusion.log
```

This records the session in `logs/fusion.log`, writes reports to `reports/fusion/`, and saves the final layout outputs in `outputs/fusion/`, including `memtest.gds`, `memtest_layout.v` and `memtest_tc.sdf`. Its design library is `work/memtest_fusion.dlib`.

**_Step 4: Examine the layout_**

Import `outputs/logical/memtest.gds` into Custom Compiler using the Stream Import procedure from Task 1, with **Top Cell** set to `memtest` and a new destination library attached to `tsmcN65`. If you ran the optional physical-synthesis flow, use `outputs/fusion/memtest.gds`. Open the `layout` view and use **f** and **SHIFT-f** to fit the layout and expand its hierarchy.

When you have finished with Fusion Compiler, enter `exit` at its prompt to return to the Linux shell before running the simulation commands below.

**_Step 5: Design a testbench_**

Write a testbench. Put it in `src/memtest_tb.sv`.

Then simulate at all three levels, as in Lab 1 Task 4. Run each command from the Linux shell and inspect its logs before moving to the next level. The Makefile creates `logs/` and `sim/` automatically.

```bash
make sim-rtl
```

This simulates the original RTL with the SRAM model. Compilation output is saved in **`logs/vcs_rtl.log`** and simulation output in **`logs/sim_rtl.log`**. If the testbench generates `waveform.vcd`, it is moved to **`sim/rtl.vcd`**.

```bash
make sim-synth
```

This simulates `outputs/logical/memtest_synth.v` with the standard-cell and SRAM models. Compilation output is saved in **`logs/vcs_synth.log`** and simulation output in **`logs/sim_synth.log`**. The waveform, if generated, is saved as **`sim/synth.vcd`**.

```bash
make sim-layout FLOW=logical
```

This simulates `outputs/logical/memtest_layout.v` with delay back-annotation from `outputs/logical/memtest_tc.sdf`. Compilation output is saved in **`logs/vcs_layout_logical.log`** and simulation output in **`logs/sim_layout_logical.log`**. The waveform, if generated, is saved as **`sim/layout_logical.vcd`**.

For the optional physical-synthesis flow, use:

```bash
make sim-layout FLOW=fusion
```

This reads the layout netlist and SDF from `outputs/fusion/`. Its logs are **`logs/vcs_layout_fusion.log`** and **`logs/sim_layout_fusion.log`**, and its waveform, if generated, is **`sim/layout_fusion.vcd`**.

Check the testbench's pass/fail messages and any SDF annotation or timing-check warnings in the simulation logs. A simulator finishing does not by itself establish that the test passed. Re-running a stage reuses its log and output filenames; copy any results you want to retain before repeating it.

---
### Task 3 - Memory Self-test
---

<p align="center"> <img src="diagrams/cct_2.jpg" width="1200" height="200"> </p><BR>

The system above is an extension of the circuit in Task 2 with a built-in self-test circuit. Instead of inspect the output from the simulator, this circuit  compresses the SRAM output sequence to produce an expected 16-bit signature. Deviation from the expectation indicates an error in the circuit.

In Lab 1, you designed a serial signature analyzer that compress sequence of '1's and '0's to a 16-bit signature.  This circuit can be modified into a parallel signature analyzer that produces a unique signature for a 32-bit, instead of 1-bit, input using the circuit shown below.

<p align="center"> <img src="diagrams/signature_16.jpg" width="600" height="250"> </p><BR>

This parallel signature analyzer circuit "merges" the 32-bit output values from the SRAM with the LFSR Q outputs, and produces a signature for stored contents in the SRAM.

You will also need to modify the FSM to ensure that a test cycle is performed whenever the test input command goes from low to high, and produces the 32-bit signature. This can then be compared with the expected value and produces a GO/NO_GO output.

> [Here](https://www.partow.net/programming/polynomials/index.html#deg32) is a useful reference on  primitive polynomials for degrees 3 to 32.

Check that your self-test circuit works by connecting one of the data output of the SRAM to ground, thus injecting a stuck-at-0 fault into the circuit.


---
#### Challenge (if you have time)
---

You can synthesis a 32x32 SRAM using registers in standard cell.  Write a 32x32 SRAM block in SystemVerilog and use Fusion Compiler to create the layout.  Compare the size and timing for this synthesized SRAM with the layout generated by TSMC's memory compiler.
