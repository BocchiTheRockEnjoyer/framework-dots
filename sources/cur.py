import os,sys,struct,shutil,re
src,dst=sys.argv[1:3]; os.makedirs(dst+'/cursors',exist_ok=True)
OR=(243,83,26); BK=(14,14,14)
def px(p):
    a=p>>24
    if a==0: return 0
    r,g,b=[min(255,((p>>s)&255)*255//a) for s in(16,8,0)]
    mx,mn=max(r,g,b),min(r,g,b)
    if mx-mn>60: c=(252,252,252) if (b>r or g>r) else ((14,14,14) if b>g+20 else (r,g,b))
    elif a<110 and mx<40: c=(0,0,0)         # soft shadow
    else:
        t=(r+g+b)/765; c=tuple(round(BK[i]+(OR[i]-BK[i])*t) for i in range(3))
    return (a<<24)|((c[0]*a//255)<<16)|((c[1]*a//255)<<8)|(c[2]*a//255)
for n in os.listdir(src+'/cursors'):
    s=f'{src}/cursors/{n}'; d=f'{dst}/cursors/{n}'
    if os.path.lexists(d): os.remove(d)
    if os.path.islink(s): os.symlink(os.readlink(s),d); continue
    b=bytearray(open(s,'rb').read())
    if b[:4]!=b'Xcur': continue
    nt=struct.unpack_from('<I',b,12)[0]
    for i in range(nt):
        ty,sub,pos=struct.unpack_from('<III',b,16+12*i)
        if ty!=0xfffd0002: continue
        hs=struct.unpack_from('<I',b,pos)[0]; w,h=struct.unpack_from('<II',b,pos+16)
        o=pos+hs; v=struct.unpack_from(f'<{w*h}I',b,o); cache={}
        struct.pack_into(f'<{w*h}I',b,o,*[cache.setdefault(p,px(p)) for p in v])
    open(d,'wb').write(b)
if os.path.isdir(src+'/cursors_scalable'):
    shutil.rmtree(dst+'/cursors_scalable',ignore_errors=True); shutil.copytree(src+'/cursors_scalable',dst+'/cursors_scalable',symlinks=True)
    for r,_,fs in os.walk(dst+'/cursors_scalable'):
        for f in fs:
            p=os.path.join(r,f)
            if f.endswith('.svg') and not os.path.islink(p):
                t=open(p).read()
                t=re.sub(r'(?i)(fill|stroke)(="|:)\s*(#fff(?:fff)?|white|#fcfcfc|#eff0f1)\b',r'\1\2#f3531a',t)
                def hx(m):
                    h=m[2]; h=''.join(c*2 for c in h) if len(h)==3 else h
                    r,g,b=[int(h[i:i+2],16) for i in(0,2,4)]
                    if max(r,g,b)-min(r,g,b)<=60 or h.lower()=='f3531a': return m[0]
                    return m[1]+('#fcfcfc' if (b>r or g>r) else '#0e0e0e' if b>g+20 else '#'+h)
                t=re.sub(r'((?:fill|stroke|stop-color)(?:="|:)\s*)#([0-9a-fA-F]{6}|[0-9a-fA-F]{3})\b',hx,t)
                d=os.path.basename(r)
                if d in('not-allowed','no-drop','dnd-no-drop','circle','crossed_circle','forbidden'): t=t.replace('#f3531a','#161616')
                open(p,'w').write(t)
open(dst+'/index.theme','w').write('[Icon Theme]\nName=Graphite Orange\nComment=Breeze cursors, black with an orange edge\nInherits=breeze_cursors\n')
