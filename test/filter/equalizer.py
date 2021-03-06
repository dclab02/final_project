# Ref: https: // www.musicdsp.org/en/latest/_downloads/3e1dc886e7849251d6747b194d482272/Audio-EQ-Cookbook.txt
import numpy as np
import pyaudio
import wave
import argparse
import matplotlib.pyplot as plt
from scipy import signal
from scipy.signal import freqs, freqz
from scipy.fft import fft, fftfreq, rfft, rfftfreq, ifft, irfft


class Filter():
    def __init__(self, Fs):
        self.Fs = Fs  # sample frequency
        self.b = [1, 0, 0]  # b0, b1, b2
        self.a = [1, 0, 0]  # a0, a1, a2

        self.A = 0
        self.w0 = 0
        self.cw0 = 0
        self.sw0 = 0
        self.alpha = 0

        self.x = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]] # float
        self.y = [[0.0, 0.0], [0.0, 0.0], [0.0, 0.0]] # float

        self.filter_map = {            
            "peakingEQ": self.peakingEQ,
            "lowShelf": self.low_shelf,
            "highShelf": self.high_shelf
        }

    def _cal_common(self, f0, dbgain, Q):
        self.A = 10 ** (dbgain / 40)
        self.w0 = 2 * np.pi * f0 / self.Fs
        self.cw0 = np.cos(self.w0)
        self.sw0 = np.sin(self.w0)
        self.alpha = self.sw0 / (2 * Q)
    
    def peakingEQ(self):
        self.b = [1+self.alpha*self.A, -2*self.cw0, 1-self.alpha*self.A]
        self.a = [1+self.alpha/self.A, -2*self.cw0, 1-self.alpha/self.A]
        return self.b, self.a

    def low_shelf(self):
        A = self.A
        self.b = [A*((A+1) - (A-1)*self.cw0 + 2*np.sqrt(A)*self.alpha),
                  2*A*((A-1) - (A+1)*self.cw0),
                  A*((A+1) - (A-1)*self.cw0 - 2*np.sqrt(A)*self.alpha)]
        self.a = [(A+1) + (A-1)*self.cw0 + 2*np.sqrt(A)*self.alpha,
                  -2*((A-1) + (A+1)*self.cw0),
                  (A+1) + (A-1)*self.cw0 - 2*np.sqrt(A)*self.alpha]
        return self.b, self.a

    def high_shelf(self):
        A = self.A
        self.b = [A*((A+1) + (A-1)*self.cw0 + 2*np.sqrt(A)*self.alpha),
                  -2*A*((A-1) + (A+1)*self.cw0),
                  A*((A+1) + (A-1)*self.cw0 - 2*np.sqrt(A)*self.alpha)]
        self.a = [(A+1) - (A-1)*self.cw0 + 2*np.sqrt(A)*self.alpha,
                  2*((A-1) - (A+1)*self.cw0),
                  (A+1) - (A-1)*self.cw0 - 2*np.sqrt(A)*self.alpha]
        return self.b, self.a

    def filt(self, type, f0, dbgain, Q):
        self._cal_common(f0, dbgain, Q)
        return self.filter_map[type]()

    def apply_filt(self, x, y):
        b = self.b
        a = self.a
        y[2] = y[1]
        y[1] = y[0]

        y[0] = (b[0]/a[0])*x[0] + (b[1]/a[0])*x[1] + (b[2]/a[0]) * \
            x[2] - (a[1]/a[0])*y[1] - (a[2]/a[0]) * y[2]

def clip16(x):
    # Clipping for 16 bits
    if x > 32767: return 32767
    elif x < -32767: return -32767
    return int(x)

def byte_to_int(b):
    # 1 channel
    return int.from_bytes(b, byteorder='little', signed=True)

def int_to_byte(c):
    # 1 channel
    c = clip16(c)
    return c.to_bytes(2, byteorder='little', signed=True)

class Equalizer ():
    def __init__(self, Fs):
        self.filters = {
            1: Filter(Fs),
            2: Filter(Fs),
            3: Filter(Fs),
            4: Filter(Fs),
            5:Filter(Fs)
        }

        self.x = [0.0, 0.0, 0.0] # float
        self.x12 = [0.0, 0.0, 0.0] # float
        self.x23 = [0.0, 0.0, 0.0] # float
        self.x34 = [0.0, 0.0, 0.0] # float
        self.x45 = [0.0, 0.0, 0.0] # float

        self.y = [0.0, 0.0, 0.0] # float

    def set_coef(self, index, type, f0, dbgain, Q):
        b, a = self.filters[index].filt(type, f0, dbgain, Q)
        print(f"filter{index}, type={type}, f0={f0}, dbgain={dbgain}, Q={Q}")
        print(b, a)
    
    def run(self, data): # byte
        self.x[2] = self.x[1]
        self.x[1] = self.x[0]
        self.x[0] = byte_to_int(data)
        ## apply_filt
        self.filters[1].apply_filt(self.x, self.x12)
        self.filters[2].apply_filt(self.x12, self.x23)
        self.filters[3].apply_filt(self.x23, self.x34)
        self.filters[4].apply_filt(self.x34, self.x45)
        self.filters[5].apply_filt(self.x45, self.y)

        return int_to_byte(self.y[0])
    
def fix_size_list(l, size, data=None):
    # bytestring
    if data != None:
        l += data
    if len(l) > size:
        l = l[-size:]
    # if len(l) == size:
        # print(size)
        # d = np.frombuffer(l, dtype=np.int16)
        # duration = d.shape[0] / size
        # N = int(size * duration)

        # yf = rfft(d)
        # xf = rfftfreq(N, 1 / size)

        # plt.figure()
        # plt.plot(xf, np.abs(yf))
        # plt.xscale('log')
        # plt.savefig("./output")
        # plt.close()
    return l


def parse_arg():
    parser = argparse.ArgumentParser(description='Python Equalizer')
    parser.add_argument('-t', metavar='type', nargs=1, required=True,
                        help='enter one of LPF, HPF, BPF1, BPF2, notch, APF, peakingEQ, lowShelf, highShelf')
    parser.add_argument('-f', metavar='frequency (f, Hz)', nargs=1, required=True, type=int,
                        help='enter between 20 ~ 20000Hz')
    parser.add_argument('-a', metavar='gain (G, dB)', nargs=1, required=True, type=int,
                        help='enter gain')
    parser.add_argument('-q', metavar='quality factor (Q)', nargs=1, required=True, type=float,
                        help='enter quality factor (Q)')
    return parser.parse_args()

if __name__ == "__main__":
    # args = parse_arg()

    wf = wave.open('./input3.wav', 'rb')
    CHUNK = 1

    p = pyaudio.PyAudio()

    channels, sampwidth, framerate, nframes, comptype, compname = wf.getparams()
    print(wf.getparams())

    eq = Equalizer(framerate)

    # eq.set_coef(1, "lowShelf", 100, 6, 1)
    eq.set_coef(2, "highShelf", 2000, -20, 1)
    eq.set_coef(3, "lowShelf", 100, -6, 0.2)
    # eq.set_coef(4, "peakingEQ", 2000, 10, 1)
    eq.set_coef(5, "peakingEQ", 600, -10, 0.2)

    # open stream (2)
    stream = p.open(format=pyaudio.paInt16,
                    channels=channels,
                    rate=framerate,
                    output=True)

    # read data
    data = wf.readframes(CHUNK)

    # play stream (3)
    while len(data) > 0:
        data = eq.run(data)
        stream.write(data)
        data = wf.readframes(CHUNK)

    # stop stream (4)
    stream.stop_stream()
    stream.close()

    # close PyAudio (5)
    p.terminate()

    # filt = Filter(framerate)
    # b, a = filt.filter("lowShelf", 300, -5, 2)
    # print(b, a)

    # b2, a2 = filt.filter("highShelf", 1000, -10, 2)
    # print(b2, a2)

    # # pylab plot and show
    # plt.figure()
    # w0 = 2 * args.f[0] * 2 * np.pi
    # plt.axvline(x=w0)
    # sw, sh = freqs([1 / (w0**2), 10 ** (args.a[0] / 40) / args.q[0] / w0, 1],
    #                [1 / (w0**2), 1/(10 ** (args.a[0] / 40) * args.q[0]) / w0, 1])
    # plt.plot(sw, 20 * np.log10(abs(sh)), 'r', alpha=0.5)
    # w, h = freqz(b, a, 10000, fs=framerate)
    # plt.plot(w, 20 * np.log10(abs(h)), 'g', alpha=0.5)
    # plt.xscale('log')
    # plt.xlabel('Frequency [rad/s]')
    # plt.ylabel('Amplitude [dB]')
    # plt.savefig("./output")


    # sinal = [b[0]]
    # sinal += [b[1]-sinal[-1]*a[1]]
    # sinal += [b[2]-sinal[-1]*a[1]-sinal[-2]*a[2]]
    # for i in xrange(44100):  # for 1 second
    #     sinal.append(-sinal[-1]*a[1]-sinal[-2]*a[2])

    # # fft and modulus
    # fft = np.fft.fft(sinal)
    # m = np.abs(fft)
    # p.plot(m)
    # p.show()
