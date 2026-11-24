import subprocess,sys
src,n,th,out=sys.argv[1],int(sys.argv[2]),float(sys.argv[3]),sys.argv[4]
px=n*16
raw=subprocess.run(['magick','-background','white','-density','1200',src,'-resize',f'{px}x{px}!','-colorspace','Gray','-depth','8','gray:-'],capture_output=True,check=True).stdout
p=24/n; c=[]
for y in range(n):
    r=''
    for x in range(n):
        v=sum(255-raw[(y*16+j)*px+x*16+i] for j in range(16) for i in range(16))/(256*255)
        r+='#' if v>th else '.'
        if v>th: c.append(f'<circle cx="{(x+.5)*p:.3f}" cy="{(y+.5)*p:.3f}" r="{p*.42:.3f}"/>')
    print(r)
open(out,'w').write('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24"><defs><style id="current-color-scheme" type="text/css">.ColorScheme-Text{color:#fcfcfc;}</style></defs><g class="ColorScheme-Text" fill="currentColor">'+''.join(c)+'</g></svg>')
