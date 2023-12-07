#!/usr/bin/env python

from PIL import Image, ImageColor

target_initial_hue = 254


def tween_closed(minimum, maximum, steps):
    yield minimum
    step_size = (maximum - minimum) / (steps - 1)
    for i in range(1, steps):
        yield minimum + step_size * i


def tween_half_open(minimum, maximum, steps):
    yield minimum
    step_size = (maximum - minimum) / steps
    for i in range(1, steps):
        yield minimum + step_size * i


img = Image.new(mode="RGB", size=(64, 1))

grays = tuple(tween_closed(0, 255, 8))
hues = tuple(tween_half_open(0, 360, 56))

offset = 0
for hue in hues:
    if abs(hue - target_initial_hue) < abs(offset - target_initial_hue):
        offset = hue

i = 0
for hue in hues:
    offset_hue = (hue + offset) % 360
    img.putpixel((i, 0), ImageColor.getrgb(f'hsv({offset_hue},100%,100%)'))
    i = i + 1

for gray in map(round, grays):
    img.putpixel((i, 0), (gray, gray, gray))
    i = i + 1

img.save('chesttools_palette_4dir.a.png', 'PNG')

img = Image.new(mode="RGB", size=(64, 1))
hues = tuple(tween_half_open(0, 360, 14))

offset = 0
for hue in hues:
    if abs(hue - target_initial_hue) < abs(offset - target_initial_hue):
        offset = hue

i = 0
for hue in hues:
    offset_hue = (hue + offset) % 360
    img.putpixel((i, 0), ImageColor.getrgb(f'hsv({offset_hue},100%,100%)'))
    i = i + 1
    img.putpixel((i, 0), ImageColor.getrgb(f'hsv({offset_hue},100%,50%)'))
    i = i + 1
    img.putpixel((i, 0), ImageColor.getrgb(f'hsv({offset_hue},70.7%,70.7%)'))
    i = i + 1
    img.putpixel((i, 0), ImageColor.getrgb(f'hsv({offset_hue},50%,100%)'))
    i = i + 1

for gray in map(round, grays):
    img.putpixel((i, 0), (gray, gray, gray))
    i = i + 1


img.save('chesttools_palette_4dir.b.png', 'PNG')
