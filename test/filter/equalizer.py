# Ref: https: // www.musicdsp.org/en/latest/_downloads/3e1dc886e7849251d6747b194d482272/Audio-EQ-Cookbook.txt
import numpy as np
from numpy.core.fromnumeric import clip
import pyaudio
import wave
import argparse
import matplotlib.pyplot as plt
from scipy import signal
from scipy.signal import freqs, freqz
from scipy.fft import fft, fftfreq, rfft, rfftfreq, ifft, irfft


class Filter():
    def __init__(self, Fs):
        self.type = type
        self.Fs = Fs  # sample frequency
        self.b = [0, 0, 0]  # b0, b1, b2
        self.a = [0, 0, 0]  # a0, a1, a2

        self.A = 0
        self.w0 = 0
        self.cw0 = 0
        self.sw0 = 0
        self.alpha = 0

        self.filter_map = {
            "LPF": self.low_pass,
            "HPF": self.high_pass,
            "BPF1": self.band_pass1,
            "BPF2": self.band_pass2,
            "notch": self.notch,
            "APF": self.all_pass,
            # only below will be used
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

    def low_pass(self):
        self.b = [(1-self.cw0)/2, 1-self.cw0, (1-self.cw0)/2]
        self.a = [1+self.alpha, -2*self.cw0, 1-self.alpha]
        return self.b, self.a

    def high_pass(self):
        self.b = [(1+self.cw0)/2, -(1+self.cw0), (1+self.cw0)/2]
        self.a = [1+self.alpha, -2*self.cw0, 1-self.alpha]
        return self.b, self.a

    def band_pass1(self):  # (constant skirt gain, peak gain = Q)
        self.b = [self.sw0/2, 0, -self.sw0/2]
        self.a = [1+self.alpha, -2*self.cw0, 1-self.alpha]
        return self.b, self.a

    def band_pass2(self):  # (constant 0 dB peak gain)
        self.b = [self.alpha, 0, -self.alpha]
        self.a = [1+self.alpha, -2*self.cw0, 1-self.alpha]
        return self.b, self.a

    def notch(self):
        self.b = [1, -2*self.cw0, 1]
        self.a = [1+self.alpha, -2*self.cw0, 1-self.alpha]
        return self.b, self.a

    def all_pass(self):
        self.b = [1-self.alpha, -2*self.cw0, 1+self.alpha]
        self.a = [1+self.alpha, -2*self.cw0, 1-self.alpha]
        return self.b, self.a

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

    def filter(self, type, f0, dbgain, Q):
        self._cal_common(f0, dbgain, Q)
        return self.filter_map[type]()


def byte_to_int(b):
    # 2 channel
    return [int.from_bytes(b[:2], byteorder='little', signed=True), int.from_bytes(b[2:], byteorder='little', signed=True)]


def int_to_byte(c):
    # 2 channel
    c = clip16(c)
    return c[0].to_bytes(2, byteorder='little', signed=True) + c[1].to_bytes(2, byteorder='little', signed=True)


def clip16(x):
    # Clipping for 16 bits
    for i in range(0, len(x)):
        if x[i] > 32767:
            x[i] = 32767
        elif x[i] < -32768:
            x[i] = -32768
        else:
            x[i] = int(x[i])
    return x


def apply_filt(y, x, b, a, data):
    x[2][0] = x[1][0]
    x[2][1] = x[1][1]
    x[1][0] = x[0][0]
    x[1][1] = x[0][1]

    y[2][0] = y[1][0]
    y[2][1] = y[1][1]
    y[1][0] = y[0][0]
    y[1][1] = y[0][1]

    x[0] = byte_to_int(data)

    print(b[0]/a[0], b[1]/a[0], b[2]/a[0], a[1]/a[0], a[2]/a[0])

    y[0][0] = (b[0]/a[0])*x[0][0] + (b[1]/a[0])*x[1][0] + (b[2]/a[0]) * \
        x[2][0] - (a[1]/a[0])*y[1][0] - (a[2]/a[0]) * y[2][0]
    y[0][1] = (b[0]/a[0])*x[0][1] + (b[1]/a[0])*x[1][1] + (b[2]/a[0]) * \
        x[2][1] - (a[1]/a[0])*y[1][1] - (a[2]/a[0]) * y[2][1]
    return y, x, int_to_byte(y[0])


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


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description='Python Equalizer')
    parser.add_argument('-t', metavar='type', nargs=1, required=True,
                        help='enter one of LPF, HPF, BPF1, BPF2, notch, APF, peakingEQ, lowShelf, highShelf')
    parser.add_argument('-f', metavar='frequency (f, Hz)', nargs=1, required=True, type=int,
                        help='enter between 20 ~ 20000Hz')
    parser.add_argument('-a', metavar='gain (G, dB)', nargs=1, required=True, type=int,
                        help='enter gain')
    parser.add_argument('-q', metavar='quality factor (Q)', nargs=1, required=True, type=float,
                        help='enter quality factor (Q)')
    args = parser.parse_args()

    wf = wave.open('./input2.wav', 'rb')
    CHUNK = 1
    # instantiate PyAudio (1)
    p = pyaudio.PyAudio()

    channels, sampwidth, framerate, nframes, comptype, compname = wf.getparams()
    print(wf.getparams())

    filt = Filter(framerate)
    b, a = filt.filter(args.t[0], args.f[0], args.a[0], args.q[0])
    print(b, a)

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

    # open stream (2)
    stream = p.open(format=pyaudio.paInt16,
                    channels=channels,
                    rate=framerate,
                    output=True)

    # read data
    data = wf.readframes(CHUNK)
    y = [[0, 0], [0, 0], [0, 0]]
    x = [[0, 0], [0, 0], [0, 0]]

    l = b''

    # play stream (3)
    while len(data) > 0:
        y, x, data = apply_filt(y, x, b, a, data)
        l = fix_size_list(l, 44100, data)
        stream.write(data)
        # print(data)
        data = wf.readframes(CHUNK)

    # stop stream (4)
    stream.stop_stream()
    stream.close()

    # close PyAudio (5)
    p.terminate()

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
