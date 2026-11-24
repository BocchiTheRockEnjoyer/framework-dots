"""Makes SpaceMono-SemiBold.ttf: the Bold outlines, labelled semi-bold, so apps asking for semi-bold don't get an italic."""
import sys
from fontTools.ttLib import TTFont
f=TTFont(sys.argv[1]); f['OS/2'].usWeightClass=600; f['OS/2'].fsSelection=(f['OS/2'].fsSelection&~0x61); f['head'].macStyle=0
for r in f['name'].names:
    if r.nameID in(1,): r.string='Space Mono SemiBold'
    elif r.nameID==2: r.string='Regular'
    elif r.nameID==3: r.string='SpaceMono-SemiBold (from Bold)'
    elif r.nameID==4: r.string='Space Mono SemiBold'
    elif r.nameID==6: r.string='SpaceMono-SemiBold'
have={r.nameID for r in f['name'].names}
for i,v in((16,'Space Mono'),(17,'SemiBold')):
    f['name'].setName(v,i,3,1,0x409)
f.save(sys.argv[2])
