import subprocess,sys
raw=subprocess.run(['magick',sys.argv[1],'-crop','2880x60+0+0','+repage','-colorspace','Gray','-depth','8','gray:-'],capture_output=True).stdout
W=2880;H=len(raw)//W
on=[any(raw[y*W+x]>85 for y in range(4,H-4)) for x in range(W)]
seg=[];s=None;gap=0
for x in range(W):
    if on[x]:
        if s is None: s=x
        e=x;gap=0
    elif s is not None:
        gap+=1
        if gap>9: seg.append((s,e)); s=None
if s is not None: seg.append((s,e))
p=None
for a,b in seg:
    ys=[y for y in range(H) if any(raw[y*W+x]>85 for x in range(a,b+1))]
    print(f'x {a/2:7.1f}-{b/2:7.1f} w {(b-a+1)/2:5.1f} y {ys[0]/2:4.1f}-{ys[-1]/2:4.1f} h {(ys[-1]-ys[0]+1)/2:4.1f} gap {"" if p is None else (a-p)/2}')
    p=b
