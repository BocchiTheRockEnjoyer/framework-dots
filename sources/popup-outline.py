"""Adds the grey board outline to the theme's pop-up background."""
import sys,re
for path,line in zip(sys.argv[1::2],sys.argv[2::2]):
    s=open(path).read()
    if 'id="fd-' in s or 'data-outline' in s: continue
    R=14
    ring={'topleft':f'M0,14A14,14 0 0 1 14,0V1A13,13 0 0 0 1,14Z','topright':'M34,0A14,14 0 0 1 48,14H47A13,13 0 0 0 34,1Z','bottomleft':'M0,34A14,14 0 0 0 14,48V47A13,13 0 0 1 1,34Z','bottomright':'M34,48A14,14 0 0 0 48,34H47A13,13 0 0 1 34,47Z',
          'top':'M14,0H34V1H14Z','bottom':'M14,47H34V48H14Z','left':'M0,14H1V34H0Z','right':'M47,14H48V34H47Z'}
    for i,d in ring.items():
        m=re.search(rf'<(path|rect) id="{i}" [^>]*/>',s); assert m,(path,i)
        body=m[0].replace(f' id="{i}"','',1)
        s=s.replace(m[0],f'<g id="{i}" data-outline="1">{body}<path fill="{line}" d="{d}"/></g>')
    open(path,'w').write(s)
