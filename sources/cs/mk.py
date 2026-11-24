import sys
O='243,83,26'
def sec(n,bg,alt,fg='240,240,240',ina='154,154,154',sel=False):
    if sel: act=lnk=neg=neu=pos=vis='20,20,20'
    else: act,lnk,neg,neu,pos,vis=O,'255,128,82','237,70,70','246,170,60','110,185,120','190,150,135'
    hov='154,154,154'
    return f'[{n}]\nBackgroundAlternate={alt}\nBackgroundNormal={bg}\nDecorationFocus={O}\nDecorationHover={O}\nForegroundActive={act}\nForegroundInactive={ina}\nForegroundLink={lnk}\nForegroundNegative={neg}\nForegroundNeutral={neu}\nForegroundNormal={fg}\nForegroundPositive={pos}\nForegroundVisited={vis}\n\n'
t='''[ColorEffects:Disabled]
Color=56,56,56
ColorAmount=0
ColorEffect=0
ContrastAmount=0.65
ContrastEffect=1
IntensityAmount=0.1
IntensityEffect=2

[ColorEffects:Inactive]
ChangeSelectionColor=true
Color=112,112,112
ColorAmount=0.025
ColorEffect=2
ContrastAmount=0.1
ContrastEffect=2
Enable=false
IntensityAmount=0
IntensityEffect=0

'''
t+=sec('Colors:Button','68,68,68','110,50,25')
t+=sec('Colors:Complementary','26,26,26','37,37,37')
t+=sec('Colors:Header','26,26,26','37,37,37')+sec('Colors:Header][Inactive','32,32,32','26,26,26')
t+=sec('Colors:Selection',O,'200,66,18','20,20,20','60,25,10',True)
t+=sec('Colors:Tooltip','26,26,26','37,37,37')
t+=sec('Colors:View','26,26,26','32,32,32')
t+=sec('Colors:Window','37,37,37','44,44,44')
t+='''[General]
ColorScheme=FrameworkGraphite
Name=Framework Graphite
shadeSortColumn=true

[KDE]
contrast=4

[WM]
activeBackground=26,26,26
activeBlend=240,240,240
activeForeground=240,240,240
inactiveBackground=32,32,32
inactiveBlend=154,154,154
inactiveForeground=154,154,154
'''
open(sys.argv[1],'w').write(t)
