import os,sys,json
out=sys.argv[1]
G={'close':"#.....#|.#...#.|..#.#..|...#...|..#.#..|.#...#.|#.....#",'minimize':".......|.......|.......|.......|.......|.......|#######",'maximize':"#######|#.....#|#.....#|#.....#|#.....#|#.....#|#######",
'restore':"..#####|..#...#|#####.#|#...#.#|#...###|#...#..|#####..",'alldesktops':".......|...#...|..###..|.#####.|..###..|...#...|.......",'keepabove':"...#...|..#.#..|.#...#.|#..#..#|..#.#..|.#...#.|#.....#",
'keepbelow':"#.....#|.#...#.|..#.#..|#..#..#|.#...#.|..#.#..|...#...",'shade':"#######|.......|...#...|..#.#..|.#...#.|#.....#|.......",'help':"..###..|.#...#.|.....#.|...##..|...#...|.......|...#...",'appmenu':".......|#######|.......|#######|.......|#######|......."}
PL,PT,PB,R=34,22,46,8
def theme(name,label,c):
    d=f'{out}/{name}'; os.makedirs(d,exist_ok=True)
    def btn(n):
        states=[('active',c['btn'],1),('hover','#f3531a',1),('pressed','#b93a10',1),('inactive',c['ibtn'],1),('hover-inactive','#f3531a',1),('pressed-inactive','#b93a10',1),('deactivated',c['ibtn'],.5),('deactivated-inactive',c['ibtn'],.5)]
        if n in('keepabove','keepbelow','alldesktops','shade'): states[2]=('pressed','#f3531a',1)
        s=''
        for i,(st,col,op) in enumerate(states):
            x0=i*30; s+=f'<g id="{st}-center" transform="translate({x0} 0)"><rect width="20" height="20" fill="#000" fill-opacity="0"/>'+''.join(f'<circle cx="{4+2*x}" cy="{4+2*y}" r=".86" fill="{col}" fill-opacity="{op}"/>' for y,r in enumerate(G[n].split('|')) for x,v in enumerate(r) if v=='#')+'</g>'
        open(f'{d}/{n}.svg','w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="{30*len(states)}" height="20" viewBox="0 0 {30*len(states)} 20">{s}</svg>')
    for n in G:
        assert all(len(r)==7 for r in G[n].split('|')) and G[n].count('|')==6,n
        btn(n)
    def frame(prefix,bg,line,sh,oy):
        W=2*(PL+R)+20; a=PL+R; t=PT+R; b=PB+R
        st=''.join(f'<stop offset="{o}" stop-color="#000" stop-opacity="{round(sh*v,3)}"/>' for o,v in((0,1),(.2,.8),(.4,.46),(.6,.22),(.8,.07),(1,0)))
        D='';E=''
        def rg(i,x,y,rx,ry):
            return f'<radialGradient id="{prefix}{i}" gradientUnits="userSpaceOnUse" cx="0" cy="0" r="1" gradientTransform="translate({x} {y}) scale({rx} {ry})">{st}</radialGradient>'
        def lg(i,x1,y1,x2,y2): return f'<linearGradient id="{prefix}{i}" gradientUnits="userSpaceOnUse" x1="{x1}" y1="{y1}" x2="{x2}" y2="{y2}">{st}</linearGradient>'
        X=[0,a+10,a+20+10+10]; Y=[oy,oy+t+10,oy+t+20+10+10]   # 10 px gaps between pieces
        D+=rg('tl',X[0]+a,Y[0]+t,a,t)+rg('tr',X[2],Y[0]+t,a,t)+rg('bl',X[0]+a,Y[2],a,b)+rg('br',X[2],Y[2],a,b)
        D+=lg('t',0,Y[0]+t,0,Y[0])+lg('b',0,Y[2],0,Y[2]+b)+lg('l',X[0]+a,0,X[0],0)+lg('r',X[2],0,X[2]+a,0)
        def el(i,x,y,w,h,body): return f'<g id="{prefix}-{i}"><rect x="{x}" y="{y}" width="{w}" height="{h}" fill="url(#{prefix}{ {"topleft":"tl","topright":"tr","bottomleft":"bl","bottomright":"br","top":"t","bottom":"b","left":"l","right":"r"}[i]})"/>{body}</g>'
        x,y=X[0]+PL,Y[0]+PT
        E+=el('topleft',X[0],Y[0],a,t,f'<path d="M{x} {y+R}a{R} {R} 0 0 1 {R} -{R}v{R}z" fill="{line}"/><path d="M{x+1} {y+R}a{R-1} {R-1} 0 0 1 {R-1} -{R-1}v{R-1}z" fill="{bg}"/>')
        x2=X[2]
        E+=el('topright',x2,Y[0],a,t,f'<path d="M{x2+R} {y+R}a{R} {R} 0 0 0 -{R} -{R}v{R}z" fill="{line}"/><path d="M{x2+R-1} {y+R}a{R-1} {R-1} 0 0 0 -{R-1} -{R-1}v{R-1}z" fill="{bg}"/>')
        E+=el('top',X[1],Y[0],20,t,f'<rect x="{X[1]}" y="{y}" width="20" height="{R}" fill="{bg}"/><rect x="{X[1]}" y="{y}" width="20" height="1" fill="{line}"/>')
        E+=el('left',X[0],Y[1],a,20,f'<rect x="{x}" y="{Y[1]}" width="{R}" height="20" fill="{bg}"/><rect x="{x}" y="{Y[1]}" width="1" height="20" fill="{line}"/>')
        E+=el('right',x2,Y[1],a,20,f'<rect x="{x2}" y="{Y[1]}" width="{R}" height="20" fill="{bg}"/><rect x="{x2+R-1}" y="{Y[1]}" width="1" height="20" fill="{line}"/>')
        E+=f'<rect id="{prefix}-center" x="{X[1]}" y="{Y[1]}" width="20" height="20" fill="{bg}"/>'
        E+=el('bottomleft',X[0],Y[2],a,b,f'<rect x="{x}" y="{Y[2]}" width="{R}" height="{R}" fill="{line}"/><rect x="{x+1}" y="{Y[2]}" width="{R-1}" height="{R-1}" fill="{bg}"/>')
        E+=el('bottomright',x2,Y[2],a,b,f'<rect x="{x2}" y="{Y[2]}" width="{R}" height="{R}" fill="{line}"/><rect x="{x2}" y="{Y[2]}" width="{R-1}" height="{R-1}" fill="{bg}"/>')
        E+=el('bottom',X[1],Y[2],20,b,f'<rect x="{X[1]}" y="{Y[2]}" width="20" height="{R}" fill="{bg}"/><rect x="{X[1]}" y="{Y[2]+R-1}" width="20" height="1" fill="{line}"/>')
        return D,E
    D1,E1=frame('decoration',c['bg'],c['line'],c['sh'],0); D2,E2=frame('decoration-inactive',c['ibg'],c['iline'],c['sh']*.55,200)
    E3=f'<rect id="decoration-maximized-center" x="300" y="0" width="20" height="20" fill="{c["bg"]}"/><rect id="decoration-maximized-inactive-center" x="300" y="40" width="20" height="20" fill="{c["ibg"]}"/>'
    open(f'{d}/decoration.svg','w').write(f'<svg xmlns="http://www.w3.org/2000/svg" width="340" height="400" viewBox="0 0 340 400"><defs>{D1}{D2}</defs>{E1}{E2}{E3}</svg>')
    open(f'{d}/{name}rc','w').write(f'''[General]
ActiveTextColor={c['text']},255
InactiveTextColor={c['itext']},255
UseTextShadow=false
TitleAlignment=Center
TitleVerticalAlignment=Center
Animation=120
Shadow=true

[Layout]
BorderLeft=1
BorderRight=1
BorderBottom=1
ButtonWidth=20
ButtonHeight=20
ButtonSpacing=4
ButtonMarginTop=0
ExplicitButtonSpacer=8
PaddingLeft={PL}
PaddingRight={PL}
PaddingTop={PT}
PaddingBottom={PB}
TitleBorderLeft=6
TitleBorderRight=6
TitleEdgeLeft=7
TitleEdgeRight=7
TitleEdgeTop=5
TitleEdgeBottom=4
TitleEdgeLeftMaximized=7
TitleEdgeRightMaximized=7
TitleEdgeTopMaximized=4
TitleEdgeBottomMaximized=4
TitleHeight=20
''')
    json.dump({"KPlugin":{"Id":name,"Name":label,"Description":"Dot-matrix title bar buttons","License":"GPL-3.0-or-later","Version":"1.0"}},open(f'{d}/metadata.json','w'),indent=1)
    open(f'{d}/metadata.desktop','w').write(f'[Desktop Entry]\nName={label}\nComment=Dot-matrix title bar buttons\nX-KDE-PluginInfo-Name={name}\nX-KDE-PluginInfo-Version=1.0\nX-KDE-PluginInfo-License=GPL-3.0-or-later\nType=Service\n')
theme('framework-dots','Framework Dots',dict(bg='#252525',ibg='#1e1e1e',line='#4a4a4a',iline='#3a3a3a',btn='#e8e8e8',ibtn='#6e6e6e',text='246,246,246',itext='122,122,122',sh=.42))
theme('framework-dots-light','Framework Dots Light',dict(bg='#dedede',ibg='#e8e8e8',line='#b0b0b0',iline='#c4c4c4',btn='#252525',ibtn='#969696',text='37,37,37',itext='120,120,120',sh=.18))
