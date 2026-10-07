"""Makes the original game playable alone (in Ruffle) for comparisons: $KKP_WORK/puzzlemanda/ref.swf (from K-Train's
ref_swf.py).

game.swf holds the game code in the exported clip "90D*" that the KadoKado loader attached, with the KKApi of the
loader (obfuscated name ";ndCG"). Added here, as AVM1 bytecode:
  - before the code of "90D*": a KKApi stub (available, const, aconst, val, addScore: summed in _global.__score,
    gameOver, flagCheater): Puzzle-Manda's Const calls KKApi.const while its classes are defined;
  - at the end of that frame: Haxe's __closure replaced by a plain AS2 closure (Ruffle has no arguments.callee: the
    button handlers and the animation callbacks would never run), Manager.init() ("980Sb"["}-B2"]) and onEnterFrame =
    Manager.main ("0D 6"), with the state sent to the page after every frame (ExternalInterface "rlog", see
    ruffle/ref.html): the score, the level, the time left, the sequence (x, y, symbol of each fruit), the grid size;
  - on the main timeline: attachMovie("90D*", "code", 1).
The stage of game.swf is 550 x 400 (the loader showed it in 300 x 300): set to 300 x 300.
usage: ref_swf.py [name clip...]   (after prepare_game.sh: $KKP_WORK/puzzlemanda/game.swf)
"""
import os, sys, struct, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'puzzlemanda', '')


# ---------------------------------------------------------------- AVM1 assembler (the few actions needed)
def push(*vals):
    b = b''
    for v in vals:
        if v is True or v is False:
            b += b'\x05' + (b'\x01' if v else b'\x00')
        elif isinstance(v, int):
            b += b'\x07' + struct.pack('<i', v)
        else:
            b += b'\x00' + v.encode('latin-1') + b'\x00'
    return b'\x96' + struct.pack('<H', len(b)) + b


GETVAR, SETVAR, GETMEMBER, SETMEMBER, CALLMETHOD, NEWOBJECT, POP, RETURN = (
    b'\x1c', b'\x1d', b'\x4e', b'\x4f', b'\x52', b'\x40', b'\x17', b'\x3e')
ADD2 = b'\x47'


def function(params, body):
    """DefineFunction (anonymous: pushed on the stack)"""
    h = b'\x00' + struct.pack('<H', len(params)) + b''.join(p.encode() + b'\x00' for p in params) + struct.pack('<H', len(body))
    return b'\x9b' + struct.pack('<H', len(h)) + h + body


def call(obj_code, method, nargs=0):
    return push(nargs) + obj_code + push(method) + CALLMETHOD


def tag(code, body):
    # (long form for everything but the empty tags: some tags must be long, any can be)
    if len(body) == 0:
        return struct.pack('<H', (code << 6) | len(body)) + body
    return struct.pack('<HI', (code << 6) | 63, len(body)) + body


def rect(x0, x1, y0, y1):
    """SWF RECT in twips, 15 bits per value"""
    n = 15
    bits = format(n, '05b') + ''.join(format(v & ((1 << n) - 1), '0%db' % n) for v in (x0, x1, y0, y1))
    bits += '0' * (-len(bits) % 8)
    return bytes(int(bits[i:i + 8], 2) for i in range(0, len(bits), 8))


# KKApi stub
ret_arg = push('v') + GETVAR + RETURN
add_score = push('_global') + GETVAR + push('__score', '_global') + GETVAR + push('__score') + GETMEMBER + push('v') + GETVAR + ADD2 + SETMEMBER
api = {
    '(kJ+1(': function([], push(True) + RETURN),      # available
    '-Q)9)': function(['v'], ret_arg),                 # const
    '*G6KR': function(['v'], ret_arg),                 # aconst
    '8kN': function(['v'], ret_arg),                   # val
    '5b)bA(': function(['v'], add_score),              # addScore
    '7T4cF(': function(['s'], b''),                    # gameOver
    '0ze*c': function([], b''),                        # flagCheater
}
manager = push('980Sb') + GETVAR
# (installed before the game code: its static constants call KKApi.const while the classes are defined)
pre = push('__kk', 0, 'Object') + NEWOBJECT + SETVAR
pre += push('_global') + GETVAR + push(';ndCG', '__kk') + GETVAR + SETMEMBER
pre += push('_global') + GETVAR + push('__score', 0) + SETMEMBER
for name, fn in api.items():
    pre += push('__kk') + GETVAR + push(name) + fn + SETMEMBER
pre += b'\x00'
code = b''
# Haxe's __closure (obfuscated "]6=8H(", the button handlers and the callbacks of the animations) calls its method
# through arguments.callee, which Ruffle does not give: replaced by a plain AS2 closure doing the same
DEFINELOCAL = b'\x3c'
inner = push('arguments') + GETVAR + push('o') + GETVAR + push(2, 'f') + GETVAR + push('apply') + CALLMETHOD + RETURN
outer = push('f', 'o') + GETVAR + push('name') + GETVAR + GETMEMBER + DEFINELOCAL + function([], inner) + RETURN
code += push('this') + GETVAR + push(']6=8H(') + function(['name', 'o'], outer) + SETMEMBER
code += call(manager, '}-B2') + POP
# ref_<name>.swf (arguments: name, then clips of the game to hide, as paths of obfuscated fields from Game._main)
NAME = sys.argv[1] if len(sys.argv) > 1 else None
for path in sys.argv[2:]:
    code += manager + push('_main') + GETMEMBER
    for field in path.split('.'):
        code += push(field) + GETMEMBER
    code += push('_visible', False) + SETMEMBER
# the state sent after every frame: paths of obfuscated names from a variable, "/" between the fields (Game "44{N":
# level "=HU11"[0], cTime "1Ht])"[0], width "}FGV8", height "9Cw4q", suite "=Lg 6": list " ]55", the eaten ones
# "(gy5+"; a cell: x "((", y ")(", symbol "9+y1J"), then env LOG (more paths, "|" between them)
LOG = ['_global/__score', '44{N/=HU11/0', '44{N/1Ht])/0', '44{N/}FGV8', '44{N/9Cw4q', '44{N/=Lg 6/(gy5+/length']
for i in range(8):
    LOG += ['44{N/=Lg 6/ ]55/%d/((' % i, '44{N/=Lg 6/ ]55/%d/)(' % i, '44{N/=Lg 6/ ]55/%d/9+y1J' % i]
LOG += [p for p in os.environ.get('LOG', '').split('|') if p]
frame = call(manager, '0D 6') + POP
for path in reversed(LOG):
    parts = path.split('/')
    frame += push(parts[0]) + GETVAR
    for field in parts[1:]:
        frame += push(int(field) if field.isdigit() else field) + GETMEMBER
frame += push('rlog', len(LOG) + 1, 'flash') + GETVAR + push('external') + GETMEMBER + push('ExternalInterface') + GETMEMBER
frame += push('call') + CALLMETHOD + POP
code += push('this') + GETVAR + push('onEnterFrame') + function([], frame) + SETMEMBER
code += b'\x00'
attach = push(1, 'code', '90D*', 3, 'this') + GETVAR + push('attachMovie') + CALLMETHOD + POP + b'\x00'

raw = open(W + 'game.swf', 'rb').read()
data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
hb = SD.Bits(data, 8)
hb.rect()
rect_end = hb.pos
hb.u16(); hb.u16()
header_end = hb.pos
out = bytearray()
root_done = False
for c, body in SD.read_tags(data, header_end, len(data)):
    if c == 39 and struct.unpack_from('<H', body, 0)[0] == 20481:
        inner = bytearray(body[:4]) + tag(12, pre)
        added = False
        for c2, b2 in SD.read_tags(body, 4, len(body)):
            if c2 == 1 and not added:
                inner += tag(12, code)
                added = True
            inner += tag(c2, b2)
        assert added
        body = bytes(inner)
    if c == 1 and not root_done:
        out += tag(12, attach)
        root_done = True
    out += tag(c, body)
swf = bytearray(b'FWS') + data[3:4] + b'\0\0\0\0' + rect(0, 6000, 0, 6000) + data[rect_end:header_end] + out
struct.pack_into('<I', swf, 4, len(swf))
name = 'ref_%s.swf' % NAME if NAME else 'ref.swf'
open(W + name, 'wb').write(swf)
print(name, len(swf))
