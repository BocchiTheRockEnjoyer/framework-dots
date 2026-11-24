import glob,os,re
src='/usr/share/icons/breeze-dark'
have={}
for p in glob.glob(src+'/**/*.svg',recursive=True): have.setdefault(os.path.basename(p)[:-4],[]).append(p)
names={}
for f in glob.glob('/usr/share/applications/kcm_*.desktop')+glob.glob('/usr/share/systemsettings/categories/*.desktop')+glob.glob('/usr/share/applications/kcm*.desktop'):
    s=open(f,errors='ignore').read(); m=re.search(r'^Icon=(.+)$',s,re.M)
    if m: names.setdefault(m[1].strip(),[]).append(os.path.basename(f)[:-8])
import sys
for n in sorted(names): print(f"{n:48}", 'sym' if n+'-symbolic' in have else '---', [p[len(src)+1:].rsplit('/',1)[0] for p in have.get(n,[])][:5], names[n][:2])
