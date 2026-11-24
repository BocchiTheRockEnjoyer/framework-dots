import sys,os,re
out,mk=sys.argv[1],sys.argv[2]
G={m[1]:m[2].split() for m in re.finditer(r"'(\w+)':\"([^\"]+)\"",open(mk).read())}
N={
'home':".....#..... ....###.... ...##.##... ..##...##.. .##.....##. ##.......## .#.......#. .#..###..#. .#..#.#..#. .#..#.#..#. .####.####.",
'desk':"........... ########### #.........# #.........# #.........# #.........# #.........# ########### ........... ...#####... ...........",
'down':".....#..... .....#..... .....#..... .....#..... ..#..#..#.. ...#.#.#... ....###.... .....#..... #.........# #.........# ###########",
'trash':"....###.... ########### ........... .#########. .#.......#. .#.#.#.#.#. .#.#.#.#.#. .#.#.#.#.#. .#.#.#.#.#. .#.......#. ..#######..",
'trashfull':"...##.##... ########### ........... .#########. .#########. .#.#.#.#.#. .#.#.#.#.#. .#.#.#.#.#. .#.#.#.#.#. .#########. ..#######..",
'folder':"........... .####...... #....#..... #.....##### #.........# #.........# #.........# #.........# #.........# ########### ...........",
'usb':"...#####... ...#.#.#... ...#####... .#########. .#.......#. .#.......#. .#.......#. .#.......#. .#.......#. .#.......#. ..#######..",
'disc':"...#####... ..#.....#.. .#.......#. #....#....# #...#.#...# #..#...#..# #...#.#...# #....#....# .#.......#. ..#.....#.. ...#####...",
'code':"........... ...#...#... ..#....#.#. .#.....#..# #.....#...# #.....#...# #....#....# .#...#...#. ..#..#..#.. ...#.#.#... ...........",
'cloud':"........... ....###.... ..##...#... .#......##. #.........# #.........# .#########. ........... ........... ........... ...........",
'share':".......###. .......#.#. .....#####. ...##...... ####....... #.#........ ####....... ...##...... .....#####. .......#.#. .......###.",
'git':"..##....... ..##....... ...#....##. ...#....##. ...#...#... ...#..#.... ...###..... ...#....... ..##....... ..##....... ...........",
'code2':"........... ........... ...#...#... ..#.....#.. .#.......#. #.........# .#.......#. ..#.....#.. ...#...#... ........... ...........",
}
N['code']=N['code2']
for k,v in N.items(): G[k]=v.split()
for k,r in G.items(): assert len(r)==11 and all(len(x)==11 for x in r),(k,[len(x) for x in r])
hdr='<defs><style id="current-color-scheme" type="text/css">.ColorScheme-Text{color:#fcfcfc;}</style></defs>'
def small(k): return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 22 22" width="22" height="22">{hdr}<g class="ColorScheme-Text" fill="currentColor">'+''.join(f'<circle cx="{2*x+1}" cy="{2*y+1}" r=".85"/>' for y,r in enumerate(G[k]) for x,c in enumerate(r) if c!='.')+'</g></svg>'
def big(k):
    p=2.5; ox=32-5.5*p; oy=37-5.5*p
    if k=='folder': dots=''.join(f'<circle cx="{48+i*3.4:.1f}" cy="49" r="1.2" fill="#f3531a"/>' for i in range(3))
    else: dots='<g fill="#f3531a">'+''.join(f'<circle cx="{ox+(x+.5)*p:.2f}" cy="{oy+(y+.5)*p:.2f}" r="1.06"/>' for y,r in enumerate(G[k]) for x,c in enumerate(r) if c!='.')+'</g>'
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><path d="M5 14a4 4 0 0 1 4-4h14.5a4 4 0 0 1 2.8 1.2L30 15h25a4 4 0 0 1 4 4v30H5z" fill="#2b2b2b"/><rect x="5" y="19" width="54" height="36" rx="4" fill="#484848"/><path d="M9 19h46a4 4 0 0 1 4 4v1a4 4 0 0 0-4-4H9a4 4 0 0 0-4 4v-1a4 4 0 0 1 4-4z" fill="#6a6a6a"/>{dots}</svg>'
F={'folder':'folder','inode-directory':'folder','stock_folder':'folder','folder-open':'folder','user-home':'home','folder-home':'home','user-desktop':'desk','folder-desktop':'desk','desktop':'desk','folder-documents':'doc','folder-text':'doc','folder-txt':'doc','folder-downloads':'down','folder-download':'down','folder-music':'note','folder-sound':'note','folder-pictures':'image','folder-picture':'image','folder-images':'image','folder-image':'image','folder-videos':'film','folder-video':'film','folder-network':'globe','folder-remote':'globe','folder-cloud':'cloud','folder-publicshare':'share','folder-public':'share','folder-templates':'windows','folder-recent':'clock','folder-open-recent':'clock','folder-games':'pad','folder-development':'code','folder-script':'code','folder-html':'code','folder_html':'code','folder-git':'git','folder-favorites':'star','folder-bookmark':'star','folder-locked':'lock','folder-encrypted':'lock','folder-mail':'speech','folder-activities':'activities','folder-root':'disk','folder-print':'doc'}
O={'user-trash':'trash','user-trash-full':'trashfull','document-open-recent':'clock','network-workgroup':'network','network-server':'proxy','drive':'disk','drive-harddisk':'disk','drive-harddisk-root':'disk','drive-harddisk-encrypted':'lock','drive-partition':'disk','drive-multidisk':'disk','drive-removable-media':'usb','drive-removable-media-usb':'usb','drive-removable-media-usb-pendrive':'usb','media-flash-memory-stick':'usb','media-flash-sd-mmc':'usb','drive-optical':'disc','media-optical':'disc','computer':'monitor','phone':'phone','favorites':'star'}
for d in('places','folders'): os.makedirs(f'{out}/{d}',exist_ok=True)
for n,k in F.items():
    open(f'{out}/folders/{n}.svg','w').write(big(k))
for n,k in {**F,**O}.items():
    for s in('','-symbolic'):
        open(f'{out}/places/{n}{s}.svg','w').write(small(k))
# user-desktop-symbolic already exists in tray/: keep that one
p=f'{out}/places/user-desktop-symbolic.svg'; os.path.exists(p) and os.remove(p)
i=out+'/index.theme'; t=open(i).read()
if 'places' not in t:
    t=t.replace('tray,settings','tray,settings,places,folders')+'\n[places]\nSize=22\nMinSize=8\nMaxSize=24\nType=Scalable\nContext=Places\n\n[folders]\nSize=64\nMinSize=25\nMaxSize=512\nType=Scalable\nContext=Places\n'
    open(i,'w').write(t)
print(len(F),len(O))
