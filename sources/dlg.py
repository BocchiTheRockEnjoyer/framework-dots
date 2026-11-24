import sys
T=sys.argv[1]; R=14; O=20; K=R+O; C=20
def frame(pre,x0,y0,attr):
    a=x0;b=x0+R;c=x0+R+C;e=c+R; f=y0;g=y0+R;h=y0+R+C;k=h+R
    p=lambda i,d:f'<path id="{pre}{i}" {attr} d="{d}"/>'
    q=lambda i,x,y,w,hh:f'<rect id="{pre}{i}" {attr} x="{x}" y="{y}" width="{w}" height="{hh}"/>'
    return "\n".join([p("topleft",f"M{a},{g}A{R},{R} 0 0 1 {b},{f}V{g}Z"),p("topright",f"M{c},{f}A{R},{R} 0 0 1 {e},{g}H{c}Z"),
      p("bottomleft",f"M{a},{h}A{R},{R} 0 0 0 {b},{k}V{h}Z"),p("bottomright",f"M{c},{k}A{R},{R} 0 0 0 {e},{h}H{c}Z"),
      q("top",b,f,C,R),q("bottom",b,h,C,R),q("left",a,g,R,C),q("right",c,g,R,C),q("center",b,g,C,C)])
def shadow(x0,y0):
    a=x0;b=x0+K;c=b+C;f=y0;g=y0+K;h=g+C; out=[]
    stops='<stop offset="0" stop-color="#000" stop-opacity=".28"/><stop offset=".4" stop-color="#000" stop-opacity=".1"/><stop offset="1" stop-color="#000" stop-opacity="0"/>'
    rs=f'<stop offset="{R/K}" stop-color="#000" stop-opacity=".28"/><stop offset="{(R+.4*O)/K}" stop-color="#000" stop-opacity=".1"/><stop offset="1" stop-color="#000" stop-opacity="0"/>'
    def corner(n,x,y,cx,cy,d):
        out.append(f'<radialGradient id="g{n}" gradientUnits="userSpaceOnUse" cx="{cx}" cy="{cy}" r="{K}">{rs}</radialGradient><g id="shadow-{n}"><rect x="{x}" y="{y}" width="{K}" height="{K}" fill="#000" fill-opacity="0"/><path d="{d}" fill="url(#g{n})"/></g>')
    corner("topleft",a,f,b,g,f"M{a},{g}A{K},{K} 0 0 1 {b},{f}V{f+O}A{R},{R} 0 0 0 {a+O},{g}Z")
    corner("topright",c,f,c,g,f"M{c+K},{g}A{K},{K} 0 0 0 {c},{f}V{f+O}A{R},{R} 0 0 1 {c+R},{g}Z")
    corner("bottomleft",a,h,b,h,f"M{a},{h}A{K},{K} 0 0 0 {b},{h+K}V{h+R}A{R},{R} 0 0 1 {a+O},{h}Z")
    corner("bottomright",c,h,c,h,f"M{c+K},{h}A{K},{K} 0 0 1 {c},{h+K}V{h+R}A{R},{R} 0 0 0 {c+R},{h}Z")
    def side(n,x,y,w,hh,gr,rx,ry,rw,rh):
        out.append(f'<linearGradient id="g{n}" gradientUnits="userSpaceOnUse" {gr}>{stops}</linearGradient><g id="shadow-{n}"><rect x="{x}" y="{y}" width="{w}" height="{hh}" fill="#000" fill-opacity="0"/><rect x="{rx}" y="{ry}" width="{rw}" height="{rh}" fill="url(#g{n})"/></g>')
    side("top",b,f,C,K,f'x1="0" x2="0" y1="{f+O}" y2="{f}"',b,f,C,O)
    side("bottom",b,h,C,K,f'x1="0" x2="0" y1="{h+R}" y2="{h+K}"',b,h+R,C,O)
    side("left",a,g,K,C,f'y1="0" y2="0" x1="{a+O}" x2="{a}"',a,g,O,C)
    side("right",c,g,K,C,f'y1="0" y2="0" x1="{c+R}" x2="{c+K}"',c+R,g,O,C)
    out.append(f'<rect id="shadow-center" x="{b}" y="{g}" width="{C}" height="{C}" fill="#000" fill-opacity="0"/>')
    return "\n".join(out)
def hints(pre,n,y):
    return "\n".join(f'<rect id="{pre}hint-{s}-margin" x="{300+i*30}" y="{y}" width="{n}" height="{n}" fill="#f0f"/>' for i,s in enumerate(("top","bottom","left","right")))
for sub,op in (("",.96),("translucent/",.85),("solid/",1)):
    body=frame("",0,0,f'class="ColorScheme-Background" fill="currentColor" fill-opacity="{op}"')
    svg=f'''<svg xmlns="http://www.w3.org/2000/svg" width="460" height="300" viewBox="0 0 460 300">
<defs><style id="current-color-scheme" type="text/css">.ColorScheme-Background{{color:#eff0f1;}}</style></defs>
{body}
{frame("mask-",80,0,'fill="#000"')}
{shadow(0,100)}
{hints("",8,0)}
{hints("thick-",8,30)}
{hints("shadow-",O,60)}
<rect id="hint-tile-center" x="300" y="100" width="4" height="4" fill="#f0f"/>
</svg>'''
    open(f"{T}/{sub}dialogs/background.svg","w").write(svg)
