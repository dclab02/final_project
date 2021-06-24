import pyaudio
import wave
import sys
import numpy as np
import math
from scipy import signal

CHUNK = 1024

def low_pass(data, freq, fs, order=2): # cutoff freq, samplerate, order
    nyq = 0.5 * fs
    f = freq / nyq
    b, a = signal.butter(order, f, btype='lowpass', output='ba')
    filtered_data = signal.lfilter(b, a, data)
    return filtered_data

def high_pass(data, freq, fs, order=2):
    nyq = 0.5 * fs
    f = freq / nyq
    b, a = signal.butter(order, f, btype='highpass', output='ba')
    filtered_data = signal.lfilter(b, a, data)
    return filtered_data

def band_pass(data, l, h, fs, order=2):
    nyq = 0.5 * fs
    low = l / nyq
    high = h / nyq
    b, a = signal.butter(order, [low, high], btype='bandpass', output='ba')
    filtered_data = signal.lfilter(b, a, data)
    return filtered_data

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Plays a wave file.\n\nUsage: %s filename.wav" % sys.argv[0])
        sys.exit(-1)

    wf = wave.open(sys.argv[1], 'rb')

    # instantiate PyAudio (1)
    p = pyaudio.PyAudio()

    channels, sampwidth, framerate, nframes, comptype, compname = wf.getparams()

    print(wf.getparams())

    # open stream (2)
    stream = p.open(format=p.get_format_from_width(sampwidth),
                    channels=channels,
                    rate=framerate,
                    output=True)

    # read data
    data = wf.readframes(CHUNK)

    # play stream (3)
    while len(data) > 0:
        data = np.frombuffer(data, dtype=np.int16)
        data = high_pass(data, 120, framerate).astype(np.int16).tobytes()        
        stream.write(data)
        data = wf.readframes(CHUNK)

    # stop stream (4)
    stream.stop_stream()
    stream.close()

    # close PyAudio (5)
    p.terminate()

