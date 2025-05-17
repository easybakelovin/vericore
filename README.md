# vericore
Verilog modules for development and fun!


### Open Source Toolchain - apio
1. Install python
   - Check for python installation with `$python --version`
   - If error appears please install python distribution
2. Get apio
   - In terminal run `$pip install -U apio`
3. Install all software (yosys, GTKwave, nxtpnr) [hackster blog](https://www.hackster.io/dshardan007/getting-started-with-opensource-fpga-tool-chain-apio-yosys-5ce38a)
   - `$apio install --all`
   - [apio docs](https://apiodoc.readthedocs.io/en/stable/source/quick_start.html)
   - Confirm apio installation with `$apio --version`
   - Enable serial and ftdi drivers in system. Note this command may need to be run in a shell with admin privileges `$apio drivers --ftdi-enable`
   - Zadig window will pop up
     - Connect FPGA Dev Board to PC and select from drop down. You may need to select ***Options->List All Devices*** to see FPGA Dev Board
     - Select interface 0
     - Replace libusbk
      ![Replace libusbk](\images\zadig-reinstall_driver.png)
      ###
   - To verify success, check `$apio system --lsftdi` (see below)
      ![CMD PROMPT](\images\apio_admin-ftdi-enable.png)
   - Once finished, you may close admin prompt
------------------------------------------------------------------------------
### New Apio Project
   1. Check list of all supported boards to ensure your Dev Board is there
     - `$apio boards --list`
     - Notable boards:
       - Alchitry-Cu
       - iCESugar-nano
   2. Use `$apio init --board <boardname>` to create a new apio project for that board. 
     - Please create a suitable directory as the apio toolchain is to verify, simulate, build, and upload bitstreams to FPGA device.
     - This will create a `apio.ini` file in the working directory
     - In this file you will be able to define the **top module** in your project.
     - Load all of your project files including **physical constraints file (.pcf)** into working directory.
   3. Once the project is set, run `$apio verify`
   4. Run `$apio sim` for simulation results (typically requres a testbench file)
   5. If everything looks okay you can build using `$apio build`
   6. To flash the FPGA with the build artifact run `$apio upload`
#### Resources:
   - [apio environment setup for fpgas](https://medium.com/robotics-devs/environment-setup-apio-for-fpgas-dd7702d83830)
   - [getting started with open source fpga tool chain](https://www.hackster.io/dshardan007/getting-started-with-opensource-fpga-tool-chain-apio-yosys-5ce38a)

-----------------------------------------------------------------------------
### Compiling and simulation with iverilog and gtkwave
This option is a good choice during the development phase where a board perhaps has not been chosen yet, but you want to test out your HDL.

1. **Compile verilog (.v) file** [Getting started with iverilog](https://steveicarus.github.io/iverilog/usage/getting_started.html)
   - `$iverilog -o <filename> <filename>.v`
   - Ex. `$iverilog -o hello hello.v`
   - File named `hello` will be found in same working directory
   - For compiling a list of files (as in the case of testbenches and modules), there are two options:
     - **Option 1**: `$iverilog -o <filename> <filename>.v <filename>.v`
       - Example where there is a `counter_tb.v` and `counter.v` files: `$iverilog -o my_design  counter_tb.v counter.v`
     - **Option 2**: Create a text file with any name e.g. `file_list.txt` in working directory
       - In **.txt** file, include all the file names (one per line)
       - Example in *file_list.txt*
            ```
            counter.v // module
            counter_tb.v // Testbench 
            # End of file
            ```
            Note that the comments after each file name are needed to prevent compilation issues. `# End of file` comment also included at end for the same reason.
        - Once this file is created run `$iverilog -o <filename> -c <txtfilename>`
        - Ex. `$iverilog -o hello -c file_list.txt`
        - A file named `hello` will be created in working directory.

2. **Execute compiled program with vvp**
   - To execute compiled program from Step 1, run `$vvp <filename>`
   -  Ex. `$vvp hello`
   -  Terminal will display output (if defined in testbench). Best practice is to wrap project in a test bench.
3. **GtkWave**
   - If you want to see simulation data from a test bench, a **.vcd** file must be dumped when running a compiled file from Step 1 that includes a (*_tb.v file).
   - To dump a **.vcd** file, be sure to include the following somewhere in the testbench to be compiled (from Step 1):
     ```verilog
     initial
        begin
        $dumpfile("test.vcd");
        $dumpvars(0, test);
        end
        ```
        Then repeat the same command: `$vvp <filename>` from Step 2. A **.vcd** file will be generated in the working directory.

    - To open simulation file in gtkwave, run `$gtkwave <filename>.vcd`
    - Ex. If the code above was included in the testbench compiled prior to running vpp command, then the command to open simulation results would be `$gtkwave test.vcd`
    - GtkWave application window will open
    - TODO: Insert example images below