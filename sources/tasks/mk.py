import sys
W=32;H=16;M=6;C=6;r=12;i=3
out=[];y0=[0]
def frame(p,plate=None,po=0,dot=None,do=1):
    Y=y0[0];y0[0]+=60; X=[0,W+4,W+M+8]; Ys=[Y,Y+H+4,Y+H+C+8]
    f=lambda c,o:f'fill="{c}" fill-opacity="{o}"' if c!='T' else f'class="ColorScheme-Text" fill="currentColor" fill-opacity="{o}"'
    def el(n,x,y,w,h,inner=''):
        out.append(f'<g id="{p}-{n}"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="#000" fill-opacity="0"/>{inner}</g>')
    a=lambda d:f'<path {f(plate,po)} d="{d}"/>' if plate else ''
    x,y=X[0],Ys[0]; el('topleft',x,y,W,H,a(f'M{x+i},{y+H}V{y+i+r}A{r},{r} 0 0 1 {x+i+r},{y+i}H{x+W}V{y+H}Z'))
    x=X[2]; el('topright',x,y,W,H,a(f'M{x},{y+H}V{y+i}H{x+W-i-r}A{r},{r} 0 0 1 {x+W-i},{y+i+r}V{y+H}Z'))
    x=X[1]; el('top',x,y,M,H,a(f'M{x},{y+i}h{M}V{y+H}H{x}Z'))
    x,y=X[0],Ys[1]; el('left',x,y,W,C,a(f'M{x+i},{y}H{x+W}v{C}H{x+i}Z'))
    x=X[1]; el('center',x,y,M,C,a(f'M{x},{y}h{M}v{C}h-{M}Z'))
    x=X[2]; el('right',x,y,W,C,a(f'M{x},{y}H{x+W-i}v{C}H{x}Z'))
    x,y=X[0],Ys[2]; el('bottomleft',x,y,W,H,a(f'M{x+i},{y}H{x+W}V{y+H-i}H{x+i+r}A{r},{r} 0 0 1 {x+i},{y+H-i-r}Z'))
    x=X[2]; el('bottomright',x,y,W,H,a(f'M{x},{y}H{x+W-i}V{y+H-i-r}A{r},{r} 0 0 1 {x+W-i-r},{y+H-i}H{x}Z'))
    x=X[1]; d=f'<ellipse {f(dot,do)} cx="{x+M/2}" cy="{y+H-4}" rx="2.6" ry="2.6"/>' if dot else ''
    el('bottom',x,y,M,H,a(f'M{x},{y}h{M}V{y+H-i}h-{M}Z')+d)
    for k,(s,n) in enumerate((('top',4),('bottom',6),('left',4),('right',4))):
        out.append(f'<rect id="{p}-hint-{s}-margin" x="{140+k*12}" y="{Y}" width="{n}" height="{n}" fill="#f0f"/>')
    out.append(f'<rect id="{p}-hint-stretch-borders" x="200" y="{Y}" width="2" height="2" fill="#f0f"/>')
R='#e0232e'
frame('normal',dot='T',do=.85); frame('focus',plate='T',po=.10,dot=R); frame('hover',plate='T',po=.14)
frame('minimized',dot='T',do=.4); frame('attention',plate=R,po=.25,dot=R); frame('progress',plate='T',po=.18)
for k,s in enumerate(('top','bottom','left','right')):
    out.append(f'<rect id="group-expander-{s}" x="{140+k*12}" y="{y0[0]}" width="4" height="4" fill="#000" fill-opacity="0"/>')
open(sys.argv[1],'w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="220" height="{y0[0]+20}" viewBox="0 0 220 {y0[0]+20}"><defs><style id="current-color-scheme" type="text/css">.ColorScheme-Text{{color:#fcfcfc;}}</style></defs>'+"\n".join(out)+'</svg>')
