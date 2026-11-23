"""合成两个音效：大虫子撞击（重击）和虫王出场（低频轰鸣）。

输出:
  GameIame/sfx/heavy_hit.wav   0.45s  低沉的"咚"，带一点碎土噪声
  GameIame/sfx/king_spawn.wav  1.2s   更低更长的轰鸣 + 轻微颤音
"""

import math
import pathlib
import random
import struct
import wave

RATE = 44100
OUT = pathlib.Path(r"D:\aigame\GameIame\sfx")


def lowpass(samples, alpha):
    out = []
    prev = 0.0
    for s in samples:
        prev = prev + alpha * (s - prev)
        out.append(prev)
    return out


def write_wav(path, samples):
    peak = max(1e-9, max(abs(s) for s in samples))
    scale = 0.85 / peak
    data = b"".join(struct.pack("<h", int(max(-1.0, min(1.0, s * scale)) * 32767)) for s in samples)
    with wave.open(str(path), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(RATE)
        w.writeframes(data)


def heavy_hit():
    n = int(RATE * 0.45)
    rng = random.Random(7)
    body, noise = [], []
    for i in range(n):
        t = i / RATE
        f = 95.0 * math.exp(-3.2 * t) + 42.0          # 音高快速下滑
        env = math.exp(-9.5 * t)
        body.append(math.sin(2 * math.pi * f * t) * env)
        # 碎裂噪声：前 60ms 最明显
        ne = math.exp(-28.0 * t)
        noise.append((rng.uniform(-1, 1) * ne))
    noise = lowpass(noise, 0.18)
    mix = [b * 0.9 + x * 0.55 for b, x in zip(body, noise)]
    # 收尾淡出，避免爆音
    tail = int(RATE * 0.05)
    for i in range(tail):
        mix[n - tail + i] *= (tail - i) / tail
    return mix


def king_spawn():
    n = int(RATE * 1.2)
    rng = random.Random(11)
    body, rumble, roar = [], [], []
    for i in range(n):
        t = i / RATE
        # 慢起音，然后长时间衰减
        attack = min(1.0, t / 0.18)
        env = attack * math.exp(-1.9 * t)
        f = 62.0 * math.exp(-0.9 * t) + 26.0
        body.append(math.sin(2 * math.pi * f * t) * env)
        rumble.append(rng.uniform(-1, 1) * env * 0.5)
        # 6Hz 颤音的"咆哮"
        vib = 1.0 + 0.12 * math.sin(2 * math.pi * 6.0 * t)
        roar.append(math.sin(2 * math.pi * 115.0 * vib * t) * env * 0.35)
    rumble = lowpass(rumble, 0.05)
    mix = [b * 0.95 + r * 0.9 + s * 0.6 for b, r, s in zip(body, rumble, roar)]
    tail = int(RATE * 0.12)
    for i in range(tail):
        mix[n - tail + i] *= (tail - i) / tail
    return mix


if __name__ == "__main__":
    write_wav(OUT / "heavy_hit.wav", heavy_hit())
    write_wav(OUT / "king_spawn.wav", king_spawn())
    print("saved heavy_hit.wav / king_spawn.wav")
