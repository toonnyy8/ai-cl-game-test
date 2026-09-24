#!/usr/bin/env python3
"""Pose solver: mirror of anim.lisp FK for the right arm + blade (weapon_r, blade along -Z).
Stdin lines, each cumulative over the previous (a line "!" resets to STANCE):
    chest.twist=-40 arm.side=80 arm.flex=20 elbow.flex=20 az=-100 el=5
Channels: pelvis/spine/chest.{flex,twist,side}, arm.*, elbow.*, hand.*, root.{yaw,pitch} (deg).
With az=/el= (blade azimuth: 0 fwd, + left; elevation: + up) it solves hand.twist/hand.flex and
prints them; otherwise it prints the resulting blade direction.  Usage: python3 tools/pose-solve.py < keys.txt
"""
import math,sys
D=math.radians
def mm(a,b): return [[sum(a[i][k]*b[k][j] for k in range(3)) for j in range(3)] for i in range(3)]
def mv(a,v): return [sum(a[i][k]*v[k] for k in range(3)) for i in range(3)]
def Rx(t): c,s=math.cos(t),math.sin(t); return [[1,0,0],[0,c,-s],[0,s,c]]
def Ry(t): c,s=math.cos(t),math.sin(t); return [[c,0,s],[0,1,0],[-s,0,c]]
def Rz(t): c,s=math.cos(t),math.sin(t); return [[c,-s,0],[s,c,0],[0,0,1]]
def eul(tw,fl,sd): return mm(mm(Rz(sd),Rx(fl)),Ry(tw))
STANCE={'pelvis.twist':15,'spine.flex':8,'chest.twist':-10,'head.twist':-5,'arm.flex':25,'arm.side':20,'elbow.flex':50,'hand.flex':-45}
def blade(p):
    g=lambda k:D(p.get(k,0))
    R=Ry(g('root.yaw'))
    R=mm(R,Rx(-g('root.pitch')))
    R=mm(R,eul(g('pelvis.twist'),-g('pelvis.flex'),g('pelvis.side')))
    R=mm(R,eul(g('spine.twist'),-g('spine.flex'),g('spine.side')))
    R=mm(R,eul(g('chest.twist'),-g('chest.flex'),g('chest.side')))
    # shoulder: no channels
    R=mm(R,eul(g('arm.twist'),g('arm.flex'),g('arm.side')))
    Rua=R
    R=mm(R,eul(g('elbow.twist'),g('elbow.flex'),g('elbow.side')))
    R=mm(R,eul(g('hand.twist'),g('hand.flex'),g('hand.side')))
    b=mv(R,[0,0,-1]); fa=mv(Rua,[0,-1,0])
    f=lambda v:"(r%+.2f u%+.2f f%+.2f)"%(v[0],v[1],-v[2])
    # angle in horizontal plane: 0=fwd, +=left
    az=math.degrees(math.atan2(-b[0],-b[2])); el=math.degrees(math.asin(max(-1,min(1,b[1]))))
    return "blade %s az%+4.0f el%+4.0f  upperarm %s"%(f(b),az,el,f(fa))
def parse(s,base):
    p=dict(base)
    for tok in s.split():
        k,v=tok.split('=');p[k]=float(v)
    return p
if False:
    base=dict(STANCE)
    for line in sys.stdin:
        line=line.strip()
        if not line or line.startswith('#'): print(line); continue
        if line.startswith('!'): base=parse(line[1:],{}) if line[1:].strip()!='stance' else dict(STANCE); continue
        p=parse(line,base); base=p
        print("%-70s %s"%(line[:70],blade(p)))

def bdir(p):
    g=lambda k:D(p.get(k,0))
    R=Ry(g('root.yaw')); R=mm(R,Rx(-g('root.pitch')))
    for j in ('pelvis','spine','chest'):
        R=mm(R,eul(g(j+'.twist'),-g(j+'.flex'),g(j+'.side')))
    R=mm(R,eul(g('arm.twist'),g('arm.flex'),g('arm.side')))
    R=mm(R,eul(g('elbow.twist'),g('elbow.flex'),g('elbow.side')))
    R=mm(R,eul(g('hand.twist'),g('hand.flex'),g('hand.side')))
    return mv(R,[0,0,-1])
def solve(p,az,el):
    t=[-math.sin(D(az))*math.cos(D(el)), math.sin(D(el)), -math.cos(D(az))*math.cos(D(el))]
    best=None
    for tw in range(-180,181,5):
        for fl in range(-90,91,5):
            q=dict(p); q['hand.twist']=tw; q['hand.flex']=fl
            b=bdir(q); e=sum((b[i]-t[i])**2 for i in range(3))+0.00002*(tw*tw+fl*fl)
            if best is None or e<best[0]: best=(e,tw,fl)
    return best
def run2():
    base=dict(STANCE)
    for line in sys.stdin:
        line=line.strip()
        if not line or line.startswith('#'): print(line); continue
        if line.startswith('!'): base=dict(STANCE); continue
        toks=line.split(); want=[t for t in toks if t.startswith('az=') or t.startswith('el=')]
        rest=' '.join(t for t in toks if t not in want)
        p=parse(rest,base) if rest else dict(base)
        if want:
            az=float(want[0][3:]); el=float(want[1][3:])
            e,tw,fl=solve(p,az,el); p['hand.twist']=tw; p['hand.flex']=fl
            print("%-60s -> hand.twist=%d hand.flex=%d err %.3f | %s"%(line[:60],tw,fl,e,blade(p)))
        else: print("%-60s %s"%(line[:60],blade(p)))
        base=p
if __name__ == "__main__": run2()
