import sys,math,re
p=sys.argv[1]; R=15; C=30; G=7.5; s=open(p).read()
def dots(x,y,w,h,corner=None):
    o=[]
    for j in range(round(h/G)):
        for i in range(round(w/G)):
            px,py=x+i*G+G/2,y+j*G+G/2
            if corner and math.hypot(px-corner[0],py-corner[1])>R-2.6: continue
            o.append(f'<circle cx="{px}" cy="{py}" r="2.35"/>')
    return '<g fill="#ffffff" fill-opacity=".08">'+''.join(o)+'</g>'
F='fill="#0c0c0c" fill-opacity=".86"'; a=0;b=R;c=b+C;e=c+R;f=0;g=R;h=g+C;k=h+R
P=lambda i,d,dd:f'<g id="{i}"><path {F} d="{d}"/>{dd}</g>'
Q=lambda i,x,y,w,hh:f'<g id="{i}"><rect {F} x="{x}" y="{y}" width="{w}" height="{hh}"/>{dots(x,y,w,hh)}</g>'
new='\n'.join([P('topleft',f'M{a},{g}A{R},{R} 0 0 1 {b},{f}V{g}Z',dots(a,f,R,R,(b,g))),P('topright',f'M{c},{f}A{R},{R} 0 0 1 {e},{g}H{c}Z',dots(c,f,R,R,(c,g))),P('bottomleft',f'M{a},{h}A{R},{R} 0 0 0 {b},{k}V{h}Z',dots(a,h,R,R,(b,h))),P('bottomright',f'M{c},{k}A{R},{R} 0 0 0 {e},{h}H{c}Z',dots(c,h,R,R,(c,h))),Q('top',b,f,C,R),Q('bottom',b,h,C,R),Q('left',a,g,R,C),Q('right',c,g,R,C),Q('center',b,g,C,C)])
for i in('topleft','topright','bottomleft','bottomright','top','bottom','left','right','center'):
    s,n=re.subn(rf'<(path|rect) id="{i}"[^>]*/>\n?','',s); assert n==1,(i,n)
s=s.replace('</svg>',new+'</svg>'); open(p,'w').write(s)
