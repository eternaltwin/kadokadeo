"""Makes the original Memopsy playable alone (in Ruffle) for comparisons: $KKP_WORK/memopsy/ref.swf (from the Logico and
K-Train ports' ref_swf.py: the same obfuscated names of the KadoKado API).

memo.swf holds the game code in the exported clip "90D*" that the KadoKado loader attached, with the KKApi of the
loader (obfuscated name ";ndCG"). Added here, as AVM1 bytecode:
  - at the start of the frame of "90D*": a KKApi stub (available, const, addScore, registerButton, gameOver,
    flagCheater, val, cmult, cadd: the static initialisers of the game call it, Const.C10 = KKApi.const(10));
  - at the end of that frame (after the classes are defined): Manager.init(this) ("980Sb"["}-B2"]) and
    onEnterFrame = Manager.main ("0D 6"), with optional logging (env LOG, below);
  - on the main timeline: attachMovie("90D*", "code", 1).
The stage of memo.swf says 700 x 480 (the loader showed the game in its 300 x 300 square): set to 300 x 300 here.
usage: ref_swf.py [name clip...]   (after prepare_game.sh: $KKP_WORK/memopsy/memo.swf)
"""
import os, sys, struct, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'memopsy', '')


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


# KKApi stub
ret_arg = push('v') + GETVAR + RETURN
api = {
    '(kJ+1(': function([], push(True) + RETURN),      # available
    '-Q)9)': function(['v'], ret_arg),                 # const
    '*G6KR': function(['v'], ret_arg),                 # aconst (Const.POINTS)
    '5b)bA(': function(['v'], ret_arg),                # addScore
    '7vdL6(': function(['b'], b''),                    # registerButton
    '7T4cF(': function(['s'], b''),                    # gameOver
    '0ze*c': function([], b''),                        # flagCheater
    '8kN': function(['v'], ret_arg),                   # val
    '4u57)': function(['a', 'b'], push('a') + GETVAR + push('b') + GETVAR + b'\x0c' + RETURN),   # cmult (Multiply)
    '3B(*': function(['a', 'b'], push('a') + GETVAR + push('b') + GETVAR + b'\x47' + RETURN),    # cadd (Add2)
}
manager = push('980Sb') + GETVAR
# the API exists before the code of the game runs: its static initialisers call it
api_code = push('__kk', 0, 'Object') + NEWOBJECT + SETVAR
api_code += push('_global') + GETVAR + push(';ndCG', '__kk') + GETVAR + SETMEMBER
for name, fn in api.items():
    api_code += push('__kk') + GETVAR + push(name) + fn + SETMEMBER
# What the KadoKado loader gave the MTypes code (from the Oursou Invader port's ref_swf.py): Std ("3Wt": random,
# getTimer, attachMC, createEmptyMC) and here also callback ("6{VYR": obj[method](arg) in a closure, the onPress
# handlers) and xmouse / ymouse (",))hC" / "8p1P5": _root._xmouse / _ymouse). Without it Std.random is undefined and
# Tools.randomProbas loops forever (while (undefined >= p) is true in AVM1).
MULTIPLY, GETTIME = b'\x0c', b'\x34'
api_code += push('_global') + GETVAR + push('3Wt', 0, 'Object') + NEWOBJECT + SETMEMBER


def std(name, fn):
    return push('_global') + GETVAR + push('3Wt') + GETMEMBER + push(name) + fn + SETMEMBER


# the loader's Std.attachMC named every clip "<link>@<counter>" (see the Hypercube port): an AVM1 MovieClip value is
# a path by its name, so clips sharing one name alias each other (Memopsy's life.remove(l) then never finds its bead)
ADD2 = b'\x47'
GG = push('_global') + GETVAR
bump = GG + push('__amc') + GG + push('__amc') + GETMEMBER + push(1) + ADD2 + SETMEMBER
uname = push('l') + GETVAR + push('@') + ADD2 + GG + push('__amc') + GETMEMBER + ADD2
api_code += GG + push('__amc', 0) + SETMEMBER
api_code += std('7bSH*', function(['mc', 'l', 'd'], bump + push('d') + GETVAR + uname + push('l') + GETVAR
                                  + push(3, 'mc') + GETVAR + push('attachMovie') + CALLMETHOD + RETURN))
api_code += std('-4*l((', function(['mc', 'd'], bump + push('d') + GETVAR + push('e') + GG + push('__amc') + GETMEMBER
                                   + ADD2 + push(2, 'mc') + GETVAR + push('createEmptyMovieClip') + CALLMETHOD + RETURN))
api_code += std('random', function(['n'], push(0, 'Math') + GETVAR + push('random') + CALLMETHOD + push('n') + GETVAR
                                   + MULTIPLY + push(1, 'Math') + GETVAR + push('floor') + CALLMETHOD + RETURN))
api_code += std('getTimer', function([], GETTIME + RETURN))
api_code += std('6{VYR', function(['o', 'm', 'a'], function([], push('a') + GETVAR + push(1, 'o') + GETVAR + push('m')
                                                                  + GETVAR + CALLMETHOD + RETURN) + RETURN))
api_code += std(',))hC', function([], push('_root') + GETVAR + push('_xmouse') + GETMEMBER + RETURN))
api_code += std('8p1P5', function([], push('_root') + GETVAR + push('_ymouse') + GETMEMBER + RETURN))
# the Array of MTypes (from the Oursou Invader port's ref_swf.py): duplicate ("],lYS") and remove ("0ENPA": the first
# occurrence, true when found). Memopsy's looseLife / addLife call life.remove(l): without it the life bar never
# shrinks in Ruffle
DEFLOCAL, LESS2, EQUALS2, NOT, INCREMENT = b'\x3c', b'\x48', b'\x49', b'\x12', b'\x50'


def branch(op, off):
    return op + struct.pack('<Hh', 2, off)


def remove_body():
    test = push('i') + GETVAR + push('this') + GETVAR + push('length') + GETMEMBER + LESS2 + NOT
    found = push(1, 'i') + GETVAR + push(2, 'this') + GETVAR + push('splice') + CALLMETHOD + POP + push(True) + RETURN
    cmp = push('this') + GETVAR + push('i') + GETVAR + GETMEMBER + push('x') + GETVAR + EQUALS2 + NOT
    step = push('i', 'i') + GETVAR + INCREMENT + SETVAR
    end = push(False) + RETURN
    # loop: test; if (!(i < length)) goto end; cmp; if (this[i] != x) goto next; found; next: step; goto loop; end
    tail = step + branch(b'\x9d', 0)                   # placeholder jump, fixed below
    loop_len = len(test) + 5 + len(cmp) + 5 + len(found) + len(tail)
    jump_back = branch(b'\x99', -loop_len)
    tail = step + jump_back
    body = test + branch(b'\x9d', len(cmp) + 5 + len(found) + len(tail)) + cmp + branch(b'\x9d', len(found)) + found + tail + end
    return push('i', 0) + DEFLOCAL + body


AP = push('Array') + GETVAR + push('prototype') + GETMEMBER
api_code += AP + push('],lYS') + function([], push(0, 'this') + GETVAR + push('slice') + CALLMETHOD + RETURN) + SETMEMBER
api_code += AP + push('0ENPA') + function(['x'], remove_body()) + SETMEMBER
api_code += b'\x00'
# Manager.init(mc): the game is attached in the code clip
code = b'' if os.environ.get('NOINIT') else push('this') + GETVAR + call(manager, '}-B2', 1) + POP
# ref_<name>.swf (arguments: name, then clips of the game to hide, as paths of obfuscated fields from Game)
NAME = sys.argv[1] if len(sys.argv) > 1 else None
for path in sys.argv[2:]:
    code += manager + push('mode') + GETMEMBER
    for field in path.split('.'):
        code += push(field) + GETMEMBER
    code += push('_visible', False) + SETMEMBER
# env LOG: values sent to the page after every frame (ExternalInterface.call("rlog", ...), see ruffle/ref.html), paths
# of obfuscated names from a global separated by "/" ("980Sb/mode/5U4B/0": Game.time), joined by "|"; "!a/b/m" calls the
# method m of a.b without argument
frame = call(manager, '0D 6') + POP


def path_code(path):
    """a value from a path of obfuscated names ("a/b/0/c"); "!a/b/m": the method m of a.b called without argument"""
    meth = path.startswith('!')
    parts = path.lstrip('!').split('/')
    c = b''
    if meth:
        c += push(0)
        parts, m = parts[:-1], parts[-1]
    c += push(parts[0]) + GETVAR
    for field in parts[1:]:
        c += (push(int(field)) if field.isdigit() else push(field)) + GETMEMBER
    if meth:
        c += push(m) + CALLMETHOD
    return c


# env CALLS: methods called every frame instead of Manager.main ("!a/b/m|..."), debug of a hang
if os.environ.get('CALLS'):
    frame = b''.join(path_code(p) + POP for p in os.environ['CALLS'].split('|'))
# env MAXF=n: Manager.main stops after n frames (debug of a hang: the state stays readable)
if os.environ.get('MAXF'):
    api_code = api_code[:-1] + push('_global') + GETVAR + push('__f', 0) + SETMEMBER + b'\x00'
    g = push('_global') + GETVAR
    stop = push(0) + RETURN
    frame = (g + push('__f') + g + push('__f') + GETMEMBER + push(1) + b'\x47' + SETMEMBER
             + g + push('__f') + GETMEMBER + push(int(os.environ['MAXF'])) + b'\x67' + b'\x12'
             + b'\x9d' + struct.pack('<Hh', 2, len(stop)) + stop + frame)
LOG =[p for p in os.environ.get('LOG', '').split('|') if p]
if LOG:
    for path in reversed(LOG):
        meth = path.startswith('!')
        parts = path.lstrip('!').split('/')
        if meth:
            frame += push(0)
            parts, m = parts[:-1], parts[-1]
        frame += push(parts[0]) + GETVAR
        for field in parts[1:]:
            frame += (push(int(field)) if field.isdigit() else push(field)) + GETMEMBER
        if meth:
            frame += push(m) + CALLMETHOD
    frame += push('rlog', len(LOG) + 1, 'flash') + GETVAR + push('external') + GETMEMBER + push('ExternalInterface') + GETMEMBER
    frame += push('call') + CALLMETHOD + POP
# env NOMAIN=1: Manager.init only (no Manager.main every frame), NOINIT=1: neither (debug of the reference)
if not os.environ.get('NOMAIN') and not os.environ.get('NOINIT'):
    code += push('this') + GETVAR + push('onEnterFrame') + function([], frame) + SETMEMBER
code += b'\x00'
attach = push(1, 'code', '90D*', 3, 'this') + GETVAR + push('attachMovie') + CALLMETHOD + POP + b'\x00'

raw = open(W + 'memo.swf', 'rb').read()
data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
hb = SD.Bits(data, 8)
hb.rect(); hb.u16(); hb.u16()
header_end = hb.pos
out = bytearray()
root_done = False
# the id of the clip exported as "90D*"
code_id = None
for c, body in SD.read_tags(data, header_end, len(data)):
    if c == 56:
        n = struct.unpack_from('<H', body, 0)[0]
        p = 2
        for _ in range(n):
            cid = struct.unpack_from('<H', body, p)[0]
            e = body.index(0, p + 2)
            if body[p + 2:e] == b'90D*':
                code_id = cid
            p = e + 1
assert code_id is not None
for c, body in SD.read_tags(data, header_end, len(data)):
    if c == 39 and struct.unpack_from('<H', body, 0)[0] == code_id:
        inner = bytearray(body[:4]) + tag(12, api_code)
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


def rect300():
    """RECT 0..6000 x 0..6000 twips (15 bits per field)"""
    nb, v = 15, [0, 6000, 0, 6000]
    bits = format(nb, '05b') + ''.join(format(x, '0%db' % nb) for x in v)
    bits += '0' * (-len(bits) % 8)
    return bytes(int(bits[i:i + 8], 2) for i in range(0, len(bits), 8))


# (frame rate and frame count kept: 40 frames/s, like the KadoKado loader)
swf = bytearray(b'FWS') + data[3:4] + b'\0\0\0\0' + rect300() + data[header_end - 4:header_end] + out
struct.pack_into('<I', swf, 4, len(swf))
name = 'ref_%s.swf' % NAME if NAME else 'ref.swf'
open(W + name, 'wb').write(swf)
print(name, len(swf))
