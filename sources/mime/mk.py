import sys,os,re,glob,collections
out,a,b=sys.argv[1:4]
G={}
for f in (a,b):
    for m in re.finditer(r"'(\w+)':\"([^\"]+)\"",open(f).read()): G[m[1]]=m[2].split()
N={
'code':G['code2'] and "........... ...#...#... ..#.....#.. .#.......#. #.........# .#.......#. ..#.....#.. ...#...#... ........... ........... ...........",
'zip':"....##..... .....##.... ....##..... .....##.... ....##..... .....##.... ....####... ....#..#... ....#..#... ....####... ...........",
'text':"........... #########.. ........... ###########  ........... #######.... ........... ##########. ........... #####...... ...........",
'pdf':"........... ###.##..### #.#.#.#.#.. #.#.#.#.##. ###.#.#.#.. #...#.#.#.. #...##..#.. ........... ########### ........... ######.....",
'sheet':"########### #..#...#..# ########### #..#...#..# #..#...#..# ########### #..#...#..# #..#...#..# ########### ........... ...........",
'slides':"........... .........## .........## ......##.## ......##.## ...##.##.## ...##.##.## ##.##.##.## ##.##.##.## ........... ###########",
'term':"........... #.......... .#......... ..#........ ...#....... ..#........ .#......... #....###### ........... ........... ...........",
'box':".....#..... ...##.##... .##.....##. #.........# ##.......## #.##...##.# #...###...# #....#....# .##..#..##. ...#####... .....#.....",
'mail':"........... ########### ##.......## #.#.....#.# #..#...#..# #...#.#...# #....#....# #.........# ########### ........... ...........",
'db':"..#######.. #.........# ##.......## #.#######.# #.........# ##.......## #.#######.# #.........# #.........# ..#######.. ...........",
'vector':"###.....### #.#######.# ###.....### .#.......#. .#.......#. .#.......#. .#.......#. .#.......#. ###.....### #.#######.# ###.....###",
'book':".########.. ##......##. #.#......#. #.#......#. #.#......#. #.#......#. #.#......#. #.########. ##......##. .########.. ...........",
'cal':"..#.....#.. ########### ########### #.........# #.#.#.#.#.# #.........# #.#.#.#.#.# #.........# #.#.#.....# #.........# ###########",
'unk':"...#####... ..#.....#.. ..#.....#.. ........#.. .......#... ......#.... .....#..... .....#..... ........... .....#..... ...........",
}
for k,v in N.items(): G[k]=v.split()
for k in N: assert len(G[k])==11 and all(len(x)==11 for x in G[k]),(k,[len(x) for x in G[k]])
R=[ (r'^inode-directory|^folder',None),(r'calendar|[-.]ics$','cal'),(r'wps-office.(doc|dot)','doc'),(r'wps-office.(pot|ppt)|keynote','slides'),(r'wps-office.xl|gnumeric','sheet'),(r'kdenlive|realmedia','film'),(r'audacity','note'),(r'[-.]iso$|squashfs','disc'),(r'debian.binary|app-bundle','box'),(r'godot|x-awk|x-designer|relaxng','code'),(r'^inode',  'disk'),
(r'pdf|postscript|dvi|djvu|xps','pdf'),(r'epub|ebook|mobi|fb2|comic|cbr|cbz','book'),
(r'svg|illustrator|vector|opendocument.graphics|drawing|coreldraw|eps|inkscape|model|blender|3d|stl|cad|dwg|dxf','vector'),
(r'^image|krita|gimp|photoshop|xcf|raw$','image'),(r'^video|matroska|flash-video|shockwave|subrip|subtitle','film'),
(r'^audio|playlist|midi|ogg|cue$','note'),
(r'spreadsheet|excel|csv|calc|sheet|lotus','sheet'),(r'presentation|powerpoint|impress|slideshow','slides'),(r'chart|formula','slides'),
(r'iso9660|cd-image|raw-disk|disk-image|qemu|virtualbox|vmdk|vdi|cdrom|optical|apple-diskimage','disc'),
(r'deb$|rpm|package-archive|appimage|flatpak|snap|x-apk|android-package|jar|java-archive|msi','box'),
(r'zip|tar|rar|7z|compress|archive|gzip|bzip|lzma|xz|zst|arj|x-ace|x-arc$|lha|stuffit|cpio|x-ar$|x-archive','zip'),
(r'shellscript|executable-script|x-sh$|terminal|x-nushell|fish|bat$|msdos-program|ms-dos','term'),
(r'executable|sharedlib|x-object|ms-shortcut|x-desktop|dosexec|firmware|core','gear'),
(r'font','fontA'),(r'sql|database|access|sqlite|\bbase\b|opendocument.database','db'),
(r'html|xhtml|url|www|mhtml|rss|atom','globe'),
(r'mail|message|mbox|rfc822|partial','mail'),(r'vcard|contact|directory$','person'),(r'calendar|ics','cal'),
(r'key|pgp|signature|certificate|pkcs|encrypted|pem|keepass','lock'),(r'torrent','down'),
(r'python|java|script|x-c|csrc|chdr|c\+\+|cpp|hdr|json|xml|yaml|toml|css|php|ruby|perl|rust|go$|lua|haskell|qml|makefile|cmake|patch|diff|source|src|code|x-tex|latex|x-lyx|bibtex|pascal|fortran|scala|kotlin|swift|dart|typescript|sass|less|vala|x-r|nim|elixir|clojure|docker|asm|meson|objc|lisp|scheme|ocaml|erlang|groovy|matlab|sql','code'),
(r'word|opendocument.text|wordprocessing|rtf|abiword|writer|document','doc'),(r'^text|plain|readme|log|markdown|copying|authors|changelog','text'),
(r'unknown|octet','unk')]
src=glob.glob('/usr/share/icons/breeze-dark/mimetypes/*/*.svg')
names={os.path.basename(p)[:-4] for p in src}
for d in('mimes','mimesbig'):
    os.makedirs(f'{out}/{d}',exist_ok=True)
hdr='<defs><style id="current-color-scheme" type="text/css">.ColorScheme-Text{color:#fcfcfc;}</style></defs>'
def small(k): return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 22 22" width="22" height="22">{hdr}<g class="ColorScheme-Text" fill="currentColor">'+''.join(f'<circle cx="{2*x+1}" cy="{2*y+1}" r=".85"/>' for y,r in enumerate(G[k]) for x,c in enumerate(r) if c!='.')+'</g></svg>'
def big(k):
    p=2.5;ox=32-5.5*p;oy=37-5.5*p
    d=''.join(f'<circle cx="{ox+(x+.5)*p:.2f}" cy="{oy+(y+.5)*p:.2f}" r="1.06"/>' for y,r in enumerate(G[k]) for x,c in enumerate(r) if c!='.')
    return f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64" width="64" height="64"><path d="M16 4h23l13 13v39a4 4 0 0 1-4 4H16a4 4 0 0 1-4-4V8a4 4 0 0 1 4-4z" fill="#3a3a3a"/><path d="M39 4l13 13H43a4 4 0 0 1-4-4z" fill="#6a6a6a"/><g fill="#f3531a">{d}</g></svg>'
cnt=collections.Counter(); used={}
for n in sorted(names):
    if n.endswith('-rtl'): continue
    b=n.removesuffix('-symbolic'); k='text' if b.startswith('text') else None
    for rx,c in R:
        if re.search(rx,b): k=c; break
    if k is None: continue
    cnt[k]+=1; used[n]=k
for k in cnt:
    open(f'{out}/mimes/_{k}.svg','w').write(small(k)); open(f'{out}/mimesbig/_{k}.svg','w').write(big(k))
for n,k in used.items():
    for d in('mimes','mimesbig'):
        p=f'{out}/{d}/{n}.svg'
        if os.path.lexists(p): os.remove(p)
        os.symlink(f'_{k}.svg',p)
for d in('mimes','mimesbig'):
    p=f'{out}/{d}@2x'
    if not os.path.lexists(p): os.symlink(d,p)
i=out+'/index.theme';t=open(i).read()
if 'mimes' not in t:
    t=t.replace('folders,folders@2x','folders,folders@2x,mimes,mimes@2x,mimesbig,mimesbig@2x')
    for d,s,lo,hi in(('mimes',22,8,24),('mimesbig',64,25,512)):
        for sc in(1,2): t+=f'\n[{d}{"@2x" if sc==2 else ""}]\nSize={s}\n'+(f'Scale=2\n' if sc==2 else '')+f'MinSize={lo}\nMaxSize={hi}\nType=Scalable\nContext=MimeTypes\n'
    open(i,'w').write(t)
print(cnt); print('unk:',[n for n,k in used.items() if k=='unk'][:60])
