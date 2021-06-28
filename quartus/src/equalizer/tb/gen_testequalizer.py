import numpy as np
from bitstring import *
from equalizer import Equalizer
import random


def rand_dbgain(): # -15 ~ +15
    return np.random.rand() * 30 - 15;

def rand_f0(): # 0 ~ 20000
    return np.random.randint(0, 20000)

def rand_q(): # 0 ~ 10
    return np.random.rand() * 10 

def rand_type():
    return random.choice(["lowShelf", "highShelf", "peakingEQ"])

def float_to_bin(f):
    return BitArray(float=f, length=32).bin


dbgain_all = []
f_all = []
q_all = []
t_all = []

## setup randomly
for i in range(0, 5):
    dbgain_all.append(rand_dbgain())
    f_all.append(rand_f0())
    q_all.append(rand_q())
    t_all.append(rand_type())

## setup manually
# dbgain_all = [9.259617096762476, -9.707490235386153, 9.091008113864714, -5.38039564568572, 3.0391709705296996]
# f_all = [2042, 9415, 12972, 18492, 8720]
# q_all = [0.22743118061333445, 1.583999150828822, 5.544227173607382, 3.9861143298692014, 0.48949360668444686]
# t_all = ['highShelf', 'peakingEQ', 'highShelf', 'peakingEQ', 'highShelf']


print(f"dbgain_all = {dbgain_all}")
print(f"f_all = {f_all}")
print(f"q_all = {q_all}")
print(f"t_all = {t_all}")

b_all = []
a_all = []
eq = Equalizer(44100)

for i in range(0, 5):
    b, a = eq.set_coef(i + 1, t_all[i], f_all[i], dbgain_all[i], q_all[i])
    b_all.append(b)
    a_all.append(a)


for i in range(0, 5):
    print(f"filter{i + 1}, type={t_all[i]}, f0={f_all[i]}, dbgain={dbgain_all[i]}, Q={q_all[i]}")
    print(f"b = {b_all[i]}")
    print(f"a = {a_all[i]}")

    
for i in range(0, 5):
    b = b_all[i]
    a = a_all[i]
    print(f"/////// set filter{i + 1} //////")
    print("#(CLK);")
    print("i_set_coef = 1;")
    print(f"i_set_filt = 8'd{i + 1};")
    print(f"i_b0 = 32'b{float_to_bin(b[0])};")
    print(f"i_b1 = 32'b{float_to_bin(b[1])};")
    print(f"i_b2 = 32'b{float_to_bin(b[2])};")
    print(f"i_a1 = 32'b{float_to_bin(a[1])};")
    print(f"i_a2 = 32'b{float_to_bin(a[2])};")
    print("#(CLK);")
    print("i_set_coef = 0;")

print("///////////////////////")

test_size = 10
data = []

### set randomly
for i in range(test_size):
    data.append(np.random.randint(-32767, 32767))

### set manually
# data = [-27887, 17742, -13177, 6569, 20957, 9408, -367, -32415, -24751, 14037]

### print for test sv
print("/////////// set data ////////////")
for i in range(test_size):
    print("i_start = 1;")
    print(f"i_data = 32'b{float_to_bin(data[i])};")
    print("#(CLK);")
    print("i_start = 0;")
    print("#(CLK*6);")
print("///////////////////////")


for i in range(test_size):
    out = eq.run_float(data[i])
    # eq.print_filt()
    print(f"in = {data[i]}, out = {out}")
