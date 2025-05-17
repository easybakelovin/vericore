# vericore
Verilog modules for development and fun!


### Open Source Toolchain

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
     - Connect FPGA Dev Board to PC and select from drop down
     - Select interface 0
     - Replace libusbk
   - Once finished, close admin prompt
   - Check list of all supported boards
     - `$apio boards --list`
     - Notable boards:
       - Alchitry Cu
       - iCESugar-nano
   - Use `$apio init --board <boardname>` to create a new apio project for that board

### iverilog, gtkwave
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
        - Once this file is created run `$iverilog -o <filename> -c <txtfilename>
        - Ex. `$iverilog -o hello -c file_list.txt`
        - A file named `hello` will be created in working directory.

2. **Execute compiled program with vpp**
   - `$vvp <filename>`
   -  Ex. `$vvp hello`
   -  Terminal will display output (if defined in testbench). Best practice is to wrap project in a test bench.
3. **GtkWave**
   - If you want to see simulation data from a test bench, a **.vcd** file must be dumped when running a compiled file from Step 1 that includes a (*_tb.v file).
   - In the testbench in the compile file list (from Step 1) be sure to include:
     ```verilog
     initial
        begin
        $dumpfile("test.vcd");
        $dumpvars(0, test);
        end
        ```
        Then repeat the same command: `$vpp <filename>` from Step 2. A **.vcd** file will be generated in the working directory.

    - To open simulation file in gtkwave, run `$gtkwave <filename>.vcd`
    - Ex. If the code above was included in the testbench prior to running vpp command, then the command to open simulation results would be `$gtkwave test.vcd`
    - TODO: Insert example images below