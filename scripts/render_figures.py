#!/usr/bin/env python3
"""Render the book's exact diagrams. --check needs only Python; PDF needs reportlab."""
from pathlib import Path
from html import escape
import argparse
import json
from io import BytesIO
import math

ROOT = Path(__file__).resolve().parents[1]
DATA = json.loads((ROOT / 'projects/figures/data.json').read_text())
INK, MUTED, TEAL, AMBER = '#193442', '#49616b', '#006b75', '#99500c'
PAPER, LINE, PALE, WARM = '#fffdf7', '#bdc9cb', '#e4f2f0', '#fff0d8'

class Figure:
    def __init__(self, chapter, name, height, title, description):
        self.chapter, self.name, self.h = chapter, name, height
        self.title, self.description = title, description
        self.items = []
        self.rect(0, 0, 1100, height, PAPER, PAPER)
        self.text(40, 45, title, 30, bold=True)

    def rect(self, x, y, w, h, fill='white', stroke=LINE, radius=12, width=2):
        self.items.append(('rect', x,y,w,h,fill,stroke,radius,width))
    def text(self, x, y, value, size=21, color=INK, anchor='start', bold=False, mono=False):
        self.items.append(('text', x,y,str(value),size,color,anchor,bold,mono))
    def line(self, points, color=LINE, width=2, arrow=False, dashed=False):
        self.items.append(('line', points,color,width,arrow,dashed))
    def circle(self,x,y,r,label=None,fill='white',stroke=TEAL):
        self.items.append(('circle',x,y,r,fill,stroke))
        if label is not None:self.text(x,y+7,label,23,anchor='middle',bold=True)
    def box(self,x,y,w,h,title,lines=(),fill='white',stroke=LINE):
        self.rect(x,y,w,h,fill,stroke)
        self.text(x+18,y+30,title,23,bold=True)
        for i,s in enumerate(lines):self.text(x+18,y+61+26*i,s,20)
    def arrowhead(self, points):
        (x0,y0),(x,y)=points[-2:]
        a=math.atan2(y-y0,x-x0)
        return [(x-12*math.cos(a-.45),y-12*math.sin(a-.45)),(x,y),
                (x-12*math.cos(a+.45),y-12*math.sin(a+.45))]
    def svg(self):
        out=[f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1100 {self.h}" role="img" aria-labelledby="title desc">',
             f'<title id="title">{escape(self.title)}</title>',f'<desc id="desc">{escape(self.description)}</desc>']
        for item in self.items:
            kind,*v=item
            if kind=='rect':
                x,y,w,h,fill,stroke,r,width=v
                out.append(f'<rect x="{x}" y="{y}" width="{w}" height="{h}" rx="{r}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>')
            elif kind=='text':
                x,y,s,size,color,anchor,bold,mono=v
                font='Courier New, monospace' if mono else 'Arial, Helvetica, sans-serif'
                out.append(f'<text x="{x}" y="{y}" fill="{color}" font-family="{font}" font-size="{size}" font-weight="{700 if bold else 400}" text-anchor="{anchor}">{escape(s)}</text>')
            elif kind=='circle':
                x,y,r,fill,stroke=v
                out.append(f'<circle cx="{x}" cy="{y}" r="{r}" fill="{fill}" stroke="{stroke}" stroke-width="3"/>')
            elif kind=='line':
                points,color,width,arrow,dashed=v
                p=' '.join(f'{x},{y}' for x,y in points)
                dash=' stroke-dasharray="7 6"' if dashed else ''
                out.append(f'<polyline points="{p}" fill="none" stroke="{color}" stroke-width="{width}" stroke-linejoin="round"{dash}/>')
                if arrow:
                    p=' '.join(f'{x:.2f},{y:.2f}' for x,y in self.arrowhead(points))
                    out.append(f'<polyline points="{p}" fill="none" stroke="{color}" stroke-width="{width}"/>')
        return '\n'.join(out+['</svg>',''])
    def pdf(self):
        from reportlab.pdfgen.canvas import Canvas
        from reportlab.lib.colors import toColor
        buffer=BytesIO()
        c=Canvas(buffer,pagesize=(1100,self.h),invariant=1)
        c.setTitle(self.title);c.setAuthor('GPT-6 Astra');c.setSubject(self.description)
        for kind,*v in self.items:
            if kind=='rect':
                x,y,w,h,fill,stroke,r,width=v
                c.setFillColor(toColor(fill));c.setStrokeColor(toColor(stroke));c.setLineWidth(width)
                c.roundRect(x,self.h-y-h,w,h,r,fill=1,stroke=1)
            elif kind=='text':
                x,y,s,size,color,anchor,bold,mono=v
                font=('Courier' if mono else 'Helvetica')+('-Bold' if bold else '')
                c.setFont(font,size);c.setFillColor(toColor(color))
                fn={'start':c.drawString,'middle':c.drawCentredString,'end':c.drawRightString}[anchor]
                fn(x,self.h-y,s)
            elif kind=='circle':
                x,y,r,fill,stroke=v
                c.setFillColor(toColor(fill));c.setStrokeColor(toColor(stroke));c.setLineWidth(3)
                c.circle(x,self.h-y,r,fill=1,stroke=1)
            elif kind=='line':
                points,color,width,arrow,dashed=v
                c.setStrokeColor(toColor(color));c.setLineWidth(width);c.setDash([7,6] if dashed else [])
                def draw(ps):
                    p=c.beginPath();p.moveTo(ps[0][0],self.h-ps[0][1])
                    for x,y in ps[1:]:p.lineTo(x,self.h-y)
                    c.drawPath(p)
                draw(points);c.setDash([])
                if arrow:draw(self.arrowhead(points))
        c.showPage();c.save()
        return buffer.getvalue()


def holes():
    f=Figure(2,'element-subtree-holes',650,'What exactly did we remove?',
        'Both panels start with Node(1,Node(2,Tip,Tip),Tip). Removing the element 2 retains its two Tip children. Removing its entire subtree leaves one subtree hole; the two children travel with the removed subtree. Both contexts retain parent 1 and its right Tip sibling.')
    f.text(40,82,'Same tree and focus: Node(1, Node(2, Tip, Tip), Tip)',22,mono=True)
    for left,subtree in [(35,False),(570,True)]:
        f.rect(left,110,495,435)
        f.text(left+22,145,'Subtree hole' if subtree else 'Element hole',25,bold=True)
        x=left+255
        f.line([(x,203),(x-115,289)]);f.line([(x,203),(x+110,289)])
        f.circle(x,203,26,'1');f.text(x+110,314,'Tip',21,anchor='middle')
        if subtree:
            f.rect(x-167,266,104,62,WARM,AMBER)
            f.text(x-115,304,'hole',22,AMBER,anchor='middle',bold=True)
            f.text(left+24,402,'Remove the whole Node(2, Tip, Tip).',21)
            f.text(left+24,436,'Its children leave with it.',21)
            f.text(left+24,496,'Fill with any tree, including Tip.',21,TEAL,bold=True)
        else:
            f.line([(x-115,313),(x-178,370)]);f.line([(x-115,313),(x-52,370)])
            f.rect(x-146,266,62,55,WARM,AMBER)
            f.text(x-115,301,'?',27,AMBER,anchor='middle',bold=True)
            f.text(x-178,396,'Tip',21,anchor='middle');f.text(x-52,396,'Tip',21,anchor='middle')
            f.text(left+24,446,'Remove only 2; keep both children.',21)
            f.text(left+24,496,'Fill with an element value.',21,TEAL,bold=True)
    f.text(40,589,'In both panels, the path remembers parent 1 and the untouched right Tip.',22)
    f.text(40,626,'An element context also keeps the two children at the focused node.',22,bold=True)
    return f


def machine():
    f=Figure(3,'evaluator-frames',830,'Pending work becomes data',
        'Ten actual machine states evaluate (2+3)*4 to 20. Eval descends into the left operand, Right frames remember right operands and environments, and Combine frames remember computed left values. Stack top is shown on the left. At Eval 2, the surrounding context is (hole+3)*4.')
    f.text(40,84,'Evaluate (2 + 3) * 4 left to right. Stack top is on the left.',22)
    f.text(48,127,'Step',20,bold=True);f.text(130,127,'Current state',20,bold=True)
    f.text(510,127,'Stack: the work still to do',20,bold=True)
    for i,row in enumerate(DATA['machine']):
        y=147+i*54
        f.rect(36,y,1028,47,PALE if row['mode']=='Eval' else WARM,PAPER,6,1)
        f.text(61,y+31,i,21,mono=True)
        f.text(130,y+31,row['mode']+' '+row['value'],26,mono=True)
        if not row['stack']:f.text(514,y+31,'[]',21,mono=True)
        for j,frame in enumerate(row['stack']):
            x=502+j*278
            f.rect(x,y+4,270,39,'white',TEAL if j==0 else LINE,6,1)
            label = frame.replace('Right(', 'R(').replace(', [])', ')').replace('Combine(', 'C(')
            f.text(x+10,y+30,label,26,mono=True)
    f.rect(40,711,1020,84,'white',LINE)
    f.text(58,744,'At step 2, the context is (hole + 3) * 4.',22,bold=True)
    f.text(58,777,'R(op, b) = Right(op, b, []); C(op, x) = Combine(op, x).',24)
    return f


def search():
    f=Figure(8,'search-interpretations',670,'One search tree, three observations',
        'pairs 4 chooses x and y from 1,2,3 and retains x+y=4. Of nine leaves, (1,3), (2,2), and (3,1) succeed. All returns those three pairs in that order, first returns Some(1,3), and count returns 3. All other leaves fail.')
    f.text(40,83,'pairs 4: choose x, choose y, then keep x + y = 4.',22)
    f.circle(550,140,32,'x')
    good={tuple(p) for p in DATA['search']['all']}
    for x in range(1,4):
        cx=200+(x-1)*350
        f.line([(550,174),(cx,233)],TEAL,2,True)
        f.box(cx-135,239,270,76,f'x = {x}',('choose y = 1, 2, 3',),PALE,TEAL)
        for y in range(1,4):
            lx=cx+(y-2)*106
            ok=(x,y) in good
            f.line([(cx,315),(lx,354)],TEAL if ok else LINE,2,True)
            f.rect(lx-49,360,98,88,PALE if ok else 'white',TEAL if ok else LINE,8,3 if ok else 1)
            f.text(lx,392,f'({x},{y})',20,anchor='middle',mono=True)
            f.text(lx,426,'Return' if ok else 'Fail',19,TEAL if ok else MUTED,anchor='middle',bold=True)
    f.text(40,495,'Read the surviving leaves from left to right:',22)
    s=DATA['search'];pairs='['+'; '.join(f'({x},{y})' for x,y in s['all'])+']'
    for x,w,title,result in [(35,465,'all',pairs),(520,290,'first',f"Some ({s['first'][0]},{s['first'][1]})"),(830,235,'count',str(s['count']))]:
        f.rect(x,520,w,108,WARM,AMBER)
        f.text(x+18,555,title,24,bold=True)
        f.text(x+18,600,result,22,mono=True)
    return f


def ownership():
    f=Figure(9,'continuation-ownership',790,'A suspended continuation has one owner',
        'While a task is paused, its owner stores continuation k. Before acting, the scheduler takes k and clears its ownership slot. It then either continues k with a value or discontinues k with Cancelled, never both. Resumed work may suspend with a fresh continuation. Cancellation unwinds scopes and runs non-suspending finalizers.')
    f.text(40,82,'One suspension, one consuming action. A later yield creates a fresh continuation.',21)
    f.box(250,110,620,91,'Paused: the owner stores k',('The ownership slot is occupied.',),PALE,TEAL)
    f.line([(560,201),(560,239)],TEAL,3,True)
    f.box(250,248,620,88,'Take k; clear the slot',('Task state becomes Running before control transfers.',),WARM,AMBER)
    f.text(560,379,'Choose exactly one action',23,anchor='middle',bold=True)
    f.line([(560,391),(300,391),(300,420)],TEAL,3,True)
    f.line([(560,391),(835,391),(835,420)],AMBER,3,True)
    f.box(135,430,350,92,'Continue',('continue k value',),PALE,TEAL)
    f.box(625,430,410,92,'Cancel',('discontinue k Cancelled',),WARM,AMBER)
    f.line([(310,522),(310,557)],TEAL,3,True)
    f.line([(830,522),(830,557)],AMBER,3,True)
    f.box(135,565,350,105,'Resume the computation',('Finish, or suspend again', 'with a fresh continuation.'),PALE,TEAL)
    f.box(625,565,410,105,'Unwind resource scopes',('Run finalizers, then finish', 'or propagate cancellation.'),WARM,AMBER)
    f.line([(135,615),(85,615),(85,154),(240,154)],TEAL,2,True,True)
    f.text(39,714,'A consumed k is never stored or resumed again.',23,bold=True)
    f.text(39,756,'Task contract: respect cancellation; finalizers must not suspend.',22)
    return f


def game():
    f=Figure(10,'shared-game-trace',770,'One recorded input, the same observable trace',
        'Four snapshots are selected from the common game trace: tick 2 has ball (7,0) and a paddle collision; tick 5 has (10,3) and a wall collision; tick 8 has (7,6) and a ceiling collision; tick 14 has (1,0) and a miss. Streams, incremental signals and effects all produce the entire identical fourteen-tick trace; the drawing shows only these four event ticks.')
    f.text(40,84,'Input moves: 1, 1, 0, -1, then ten zeros. Start: ball (5,2), paddle 5.',21)
    ticks=[2,5,8,14];rows=[DATA['game'][i-1] for i in ticks]
    for i,s in enumerate(rows):
        left=35+265*i
        f.rect(left,112,235,271,'white',LINE)
        f.text(left+18,145,f"Tick {s['tick']}",23,bold=True)
        x0,y0,scale=left+20,169,19.5
        f.rect(x0,y0,195,117,PAPER,LINE,0,1)
        for x in range(1,10):f.line([(x0+x*scale,y0),(x0+x*scale,y0+117)],LINE,.6)
        for y in range(1,6):f.line([(x0,y0+y*scale),(x0+195,y0+y*scale)],LINE,.6)
        paddle=s['paddle']
        f.line([(x0+(paddle-1)*scale,y0+117),(x0+(paddle+1)*scale,y0+117)],TEAL,8)
        f.circle(x0+s['x']*scale,y0+(6-s['y'])*scale,7,None,WARM,AMBER)
        f.text(left+18,325,f"Ball ({s['x']},{s['y']})",22,mono=True)
        f.text(left+18,360,s['events'][0],22,AMBER,bold=True)
    f.text(40,424,'The same step function is used in each interpretation:',22)
    for j,name in enumerate(['Streams','Signals','Effects']):
        y=452+j*77
        f.rect(35,y,1030,63,PALE if j!=1 else WARM,PAPER,9,1)
        f.text(51,y+39,name,23,bold=True)
        for i,s in enumerate(rows):
            x=245+i*207
            if i<3:f.line([(x+142,y+33),(x+186,y+33)],MUTED,2,True)
            f.rect(x,y+11,143,41,'white',LINE,6,1)
            f.text(x+72,y+38,f"({s['x']},{s['y']})",22,anchor='middle',mono=True)
    f.text(40,714,'Selected event ticks are shown; the tests compare all fourteen complete states',21)
    f.text(40,746,'and event lists. Drawing is a consumer of the trace.',21)
    return f


def main():
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--check',action='store_true',help='compare SVGs with source/data; no PDF dependencies')
    parser.add_argument('--pdf',action='store_true',help='also generate deterministic vector PDFs (reportlab)')
    args=parser.parse_args()
    errors=[]
    for f in [holes(),machine(),search(),ownership(),game()]:
        path=ROOT/f'chapter{f.chapter}'/(f.name+'.svg')
        content=f.svg()
        if args.check:
            if not path.exists() or path.read_text()!=content:errors.append(str(path.relative_to(ROOT)))
        else:path.write_text(content)
        if args.pdf:
            pdf_path = path.with_suffix('.pdf')
            pdf_content = f.pdf()
            if args.check:
                if not pdf_path.exists() or pdf_path.read_bytes()!=pdf_content:
                    errors.append(str(pdf_path.relative_to(ROOT)))
            else:pdf_path.write_bytes(pdf_content)
    if errors:raise SystemExit('Regenerate diagrams: '+', '.join(errors))
    print('Five diagrams '+('match source and checked implementation data.' if args.check else 'rendered.'))

if __name__=='__main__':main()
