import numpy as np
from bitstring import *
from equalizer import Equalizer

eq = Equalizer(44100)

def rand_dbgain():
    pass

def rand_f0():
    pass

def rand_q():
    return np.rand

def rand_type():
    pass



for index, i in enumerate(b):
    print(f"localparam b{index} = 32'b{i.bin}; // {i.float}")

for index, i in enumerate(a):
    if index == 0: continue
    print(f"localparam a{index} = 32'b{i.bin}; // {i.float}")

for index, i in enumerate(x):
    print(f"localparam x{index} = 32'b{i.bin}; // {i.float}")


for i in range(5):
    print("/////// for test_filter.sv //////")

    print("i_set_filt = 1;")
    print(f"i_set_coef = {i+1}")
    print("///////////////////////////////")