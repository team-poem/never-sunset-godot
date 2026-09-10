"""Original deterministic quiet ambience and footsteps. No external sound samples."""
import math, random, struct, wave
from pathlib import Path
folder = Path(__file__).resolve().parent.parent / "assets" / "audio"
folder.mkdir(exist_ok=True)
rate = 22050
rng = random.Random(104)
def render(name, seconds, sample):
    count = int(seconds * rate)
    values = bytearray()
    for i in range(count):
        t = i / rate
        fade = min(1.0, t / .08, (seconds-t) / .1)
        value = max(-.95, min(.95, sample(t) * max(0,fade)))
        values.extend(struct.pack("<h", int(value * 32767)))
    with wave.open(str(folder / name), "wb") as f:
        f.setnchannels(1); f.setsampwidth(2); f.setframerate(rate); f.writeframes(values)
brown = [0.0]
def room(t):
    brown[0] = (brown[0] + rng.uniform(-1,1)*.012) / 1.015
    return .07*math.sin(2*math.pi*55*t) + .025*math.sin(2*math.pi*110*t) + brown[0]*.45
render("room.wav", 12, room)
brown[0]=0
def pipe(t):
    brown[0]=(brown[0]+rng.uniform(-1,1)*.02)/1.03
    breath=max(0,math.sin(math.pi*t/3))**3
    return breath*(brown[0]*1.2+.08*math.sin(2*math.pi*42*t))
render("pipe.wav", 12, pipe)
def step(t):
    return .36*math.exp(-t*28)*math.sin(2*math.pi*(100-60*t)*t)+rng.uniform(-1,1)*.07*math.exp(-t*22)
render("step.wav", .28, step)
def pulse(t):
    beat=t%1.2
    return .12*math.exp(-beat*12)*math.sin(2*math.pi*38*beat)
render("pulse.wav", 6, pulse)
render("pulse-beat.wav", 1, pulse)
render("ceramic.wav", .45, lambda t:.09*math.exp(-t*15)*(math.sin(2*math.pi*900*t)+.4*math.sin(2*math.pi*1320*t)))
print("Generated six original WAV assets")
