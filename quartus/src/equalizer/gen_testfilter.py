#### generate test value for filter.sv, test_filter.sv

import numpy as np
from bitstring import *

b = []
a = []
x = []

b_real = []
a_real = []
x_real = []
y_real = [0.0, 0.0, 0.0]

for i in range(3):
    r = np.random.uniform(-2, +2)
    b_real.append(r)
    b.append(BitArray(float=r, length=32))

for i in range(3):
    r = np.random.uniform(-2, +2)
    a_real.append(r)
    a.append(BitArray(float=r, length=32))

for i in range(3):
    r = float(np.random.randint(-32767, +32767))
    x_real.append(r)
    x.append(BitArray(float=float(r), length=32))

print("/////// for test_filter.sv //////")
for index, i in enumerate(b):
    print(f"localparam b{index} = 32'b{i.bin}; // {i.float}")

for index, i in enumerate(a):
    if index == 0: continue
    print(f"localparam a{index} = 32'b{i.bin}; // {i.float}")

for index, i in enumerate(x):
    print(f"localparam x{index} = 32'b{i.bin}; // {i.float}")
print("///////////////////////////////")

def do_filter(index):
    print(f"/////// {index} time //////")
    b0x0 = b_real[0]*x_real[0]
    b1x1 = b_real[1]*x_real[1]
    b2x2 = b_real[2]*x_real[2]
    a1y1 = a_real[1]*y_real[1]
    a2y2 = a_real[2]*y_real[2]

    b0x0_b1x1 = b0x0+b1x1
    b0x0_b1x1_b2x2 = b0x0_b1x1 + b2x2
    a1y1_a2y2 = a1y1+a2y2
    sub_b0x0_b1x1_b2x2__a1y1_a2y2 = b0x0_b1x1_b2x2 - a1y1_a2y2
    print(f"b0x0 = {b0x0}")
    print(f"b1x1 = {b1x1}")
    print(f"b2x2 = {b2x2}")
    print(f"a1y1 = {a1y1}")
    print(f"a2y2 = {a2y2}")
    print(f"b0x0_b1x1 = {b0x0_b1x1}")
    print(f"b0x0_b1x1_b2x2 = {b0x0_b1x1_b2x2}")
    print(f"a1y1_a2y2 = {a1y1_a2y2}")
    print(f"sub_b0x0_b1x1_b2x2__a1y1_a2y2 = {sub_b0x0_b1x1_b2x2__a1y1_a2y2}")
    
    return sub_b0x0_b1x1_b2x2__a1y1_a2y2


for i in range(10):
    new_y0 = do_filter(i)
    y_real[2] = y_real[1]
    y_real[1] = y_real[0]
    y_real[0] = new_y0