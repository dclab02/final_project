#!/bin/bash
ncverilog +access+r ./final_project_core_tb.sv ../src/final_project_core.sv ../src/Demodulator.sv \
../src/I2CInitializer.sv ../src/I2C.sv ../src/player.sv ../src/pipeline/* ../src/utils/AsyncFIFO/*.sv \
../src/equalizer/*.sv ../src/utils/convert/*.sv ../src/udp_loop_back.sv