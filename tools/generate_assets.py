#!/usr/bin/env python3
"""Generate original vector-style launcher artwork and store graphic. Requires Pillow."""
from pathlib import Path
import math
from PIL import Image,ImageDraw,ImageFont
ROOT=Path(__file__).resolve().parents[1]
TEAL='#67dfc7'; GOLD='#e7c47b'; BG='#102235'
def hex_points(cx,cy,r):
 return [(cx+math.cos(math.radians(60*i-30))*r,cy+math.sin(math.radians(60*i-30))*r) for i in range(6)]
def motif(draw,cx,cy,scale,color=GOLD):
 def pts(coords): return [(cx+x*scale,cy+y*scale) for x,y in coords]
 draw.polygon(pts([(-80,72),(-80,-55),(-40,-55),(-40,-13),(-15,-13),(-15,-79),(16,-79),(16,-13),(41,-13),(41,-55),(81,-55),(81,72)]),fill=color)
 draw.polygon(pts([(0,-140),(23,-101),(0,-68),(-23,-101)]),fill=TEAL if color!= '#ffffff' else color)
 draw.line(pts([(-99,97),(99,97)]),fill=TEAL if color!='#ffffff' else color,width=max(1,int(9*scale)))
def icon(size,foreground=False,mono=False):
 image=Image.new('RGBA',(size,size),(0,0,0,0) if foreground or mono else BG); d=ImageDraw.Draw(image)
 if not foreground and not mono:
  d.polygon(hex_points(size/2,size/2,size*.43),fill='#244d56',outline=TEAL,width=int(size*.024))
  d.polygon(hex_points(size/2,size/2,size*.34),fill='#163444')
 motif(d,size/2,size/2,size/512*(.82 if foreground or mono else 1), '#ffffff' if mono else GOLD)
 return image
def font(size): return ImageFont.truetype('/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf',size)
def main():
 assets=ROOT/'assets'; release=ROOT/'google-play-release'; assets.mkdir(exist_ok=True); release.mkdir(exist_ok=True)
 icon(512).save(assets/'icon.png'); icon(512).save(release/'app-icon-512.png')
 icon(432,True).save(assets/'adaptive-foreground.png'); icon(432,mono=True).save(assets/'adaptive-monochrome.png')
 Image.new('RGB',(432,432),BG).save(assets/'adaptive-background.png')
 im=Image.new('RGB',(1024,500),'#07141f'); d=ImageDraw.Draw(im)
 colors=['#205950','#6c653c','#3b536c','#345a3b','#603c50']
 for row in range(6):
  for col in range(10):
   cx=col*104+(row%2)*52-12; cy=row*90-10
   d.polygon(hex_points(cx,cy,57),fill=colors[(col+row*3)%5],outline='#102835',width=5)
 d.rectangle((0,0,1024,500),fill=None)
 d.rounded_rectangle((48,64,976,436),radius=32,fill=BG,outline='#467d7a',width=3)
 d.polygon(hex_points(200,250,122),fill='#244d56',outline=TEAL,width=4); motif(d,200,250,.67)
 d.text((368,131),'HEXBOUND',font=font(55),fill=TEAL)
 d.text((368,199),'KINGDOMS',font=font(55),fill=GOLD)
 d.text((370,289),'Light the beacons.',font=font(26),fill='#e4ebe9')
 d.text((370,326),'Bind the scattered realms.',font=font(26),fill='#e4ebe9')
 im.save(release/'feature-graphic-1024x500.png')
 print('Original icons and feature graphic generated')
if __name__=='__main__': main()
