"""Makes the original game playable alone (in Ruffle) for comparisons: $KKP_WORK/oursouinvader/ref.swf
(klinkersurprise/ref_swf.py; the obfuscated names of the KadoKado API are the same).

temple.swf (the released game) holds the game code in the exported clip "90D*" (sprite 255) that the KadoKado loader
attached, with the KKApi of the loader (obfuscated name ";ndCG"). Added here, as AVM1 bytecode:
  - at the end of the frame of "90D*" (after the classes are defined): a KKApi stub (available, const, aconst, val,
    addScore, registerButton, gameOver, flagCheater), Manager.init(this) ("980Sb"["}-B2"]: the game is attached in the
    code clip) and onEnterFrame = Manager.main ("0D 6");
  - on the main timeline: attachMovie("90D*", "code", 1).
usage: ref_swf.py [name clip...]   (after prepare_game.sh: $KKP_WORK/oursouinvader/temple.swf)
"""
import os, sys, struct, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'oursouinvader', '')


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
    '5b)bA(': function(['v'], ret_arg),                # addScore
    '7vdL6(': function(['b'], b''),                    # registerButton
    '*G6KR': function(['v'], ret_arg),                 # aconst
    # val (the loader's gave the number: Ruffle draws nothing for a number written to TextField.text, a string here)
    '8kN': function(['v'], push('v') + GETVAR + push('') + b'\x47' + RETURN),
    '7T4cF(': function(['s'], b''),                    # gameOver
    '0ze*c': function([], b''),                        # flagCheater
}
manager = push('980Sb') + GETVAR
CALLFUNCTION, MULTIPLY, GETTIME = b'\x3d', b'\x0c', b'\x34'


def get(*path):
    """the value of a dotted path from a variable: get('_global', 'flash', 'filters')"""
    c = push(path[0]) + GETVAR
    for f in path[1:]:
        c += push(f) + GETMEMBER
    return c


def alias(obj_code, name, value_code):
    return obj_code + push(name) + value_code + SETMEMBER


def prop_alias(obj_code, name, real):
    """obj.addProperty(name, get: this[real], set: this[real] = v): a member renamed by the obfuscator"""
    getter = function([], push('this') + GETVAR + push(real) + GETMEMBER + RETURN)
    setter = function(['v'], push('this') + GETVAR + push(real, 'v') + GETVAR + SETMEMBER)
    return setter + getter + push(name, 3) + obj_code + push('addProperty') + CALLMETHOD + POP


# What the KadoKado loader gave the MTypes code (the obfuscated names of temple.swf): Std ("3Wt": attachMC,
# createEmptyMC, random, getTimer), the Flash 8 classes under the obfuscated package "[8X6+" (flash) and the members of
# the Flash 8 API the obfuscator renamed
code = push('_global') + GETVAR + push('3Wt', 0, 'Object') + NEWOBJECT + SETMEMBER
std = get('_global', '3Wt')
code += alias(std, '7bSH*', function(['mc', 'l', 'd'], push('d') + GETVAR + push('n', 'l') + GETVAR + push(3, 'mc') + GETVAR
                                     + push('attachMovie') + CALLMETHOD + RETURN))
code += alias(std, '-4*l((', function(['mc', 'd'], push('d') + GETVAR + push('e', 2, 'mc') + GETVAR
                                      + push('createEmptyMovieClip') + CALLMETHOD + RETURN))
code += alias(std, 'random', function(['n'], push(0, 'Math') + GETVAR + push('random') + CALLMETHOD + push('n') + GETVAR
                                      + MULTIPLY + push(1, 'Math') + GETVAR + push('floor') + CALLMETHOD + RETURN))
code += alias(std, 'getTimer', function([], GETTIME + RETURN))
fl = push('[8X6+') + GETVAR
code += alias(fl, '}ZF-m', push(0, 'Object') + NEWOBJECT) + alias(fl, '0000', push(0, 'Object') + NEWOBJECT)
code += alias(fl + push('3[4k{') + GETMEMBER, '*svPM', get('_global', 'flash', 'filters', 'GlowFilter'))
code += alias(fl + push('3[4k{') + GETMEMBER, '[TPul', get('_global', 'flash', 'filters', 'BlurFilter'))
code += alias(fl + push('}ZF-m') + GETMEMBER, '+S]rS', get('_global', 'flash', 'display', 'BitmapData'))
code += alias(fl + push('0000') + GETMEMBER, '=U(Tj', get('_global', 'flash', 'geom', 'Matrix'))
code += alias(fl + push('0000') + GETMEMBER, ')2AMG', get('_global', 'flash', 'geom', 'ColorTransform'))
for cls in ('GlowFilter', 'BlurFilter'):
    P = get('_global', 'flash', 'filters', cls, 'prototype')
    for n, r in (('4y=T(', 'blurX'), ('5y=T(', 'blurY'), ('}}+ss', 'strength'), ('6x9p', 'alpha')):
        code += prop_alias(P, n, r)
MCP = get('MovieClip', 'prototype')
code += prop_alias(MCP, '3[4k{', 'filters')
code += alias(MCP, ';_dAm', get('MovieClip', 'prototype', 'attachBitmap'))
MP = get('_global', 'flash', 'geom', 'Matrix', 'prototype')
code += alias(MP, '5DZk5', get('_global', 'flash', 'geom', 'Matrix', 'prototype', 'scale'))
code += alias(MP, ')+;+n', get('_global', 'flash', 'geom', 'Matrix', 'prototype', 'translate'))
BP = get('_global', 'flash', 'display', 'BitmapData', 'prototype')
code += alias(BP, '5JH+', get('_global', 'flash', 'display', 'BitmapData', 'prototype', 'draw'))
code += alias(BP, '1xgQq', get('_global', 'flash', 'display', 'BitmapData', 'prototype', 'colorTransform'))
code += prop_alias(BP, '4]REk', 'rectangle')
code += alias(BP, '-YK-m', get('_global', 'flash', 'display', 'BitmapData', 'prototype', 'dispose'))
# the Array of MTypes: duplicate ("],lYS") and remove ("0ENPA": the first occurrence, true when found)
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


AP = get('Array', 'prototype')
code += alias(AP, '],lYS', function([], push(0, 'this') + GETVAR + push('slice') + CALLMETHOD + RETURN))
code += alias(AP, '0ENPA', function(['x'], remove_body()))
code += push('__kk', 0, 'Object') + NEWOBJECT + SETVAR
code += push('_global') + GETVAR + push(';ndCG', '__kk') + GETVAR + SETMEMBER
for name, fn in api.items():
    code += push('__kk') + GETVAR + push(name) + fn + SETMEMBER
code += push('this') + GETVAR + call(manager, '}-B2', 1) + POP
# ref_<name>.swf (arguments: name, then clips of the game to hide, as paths of obfuscated fields from Game)
NAME = sys.argv[1] if len(sys.argv) > 1 else None
for path in sys.argv[2:]:
    code += manager + push('_main') + GETMEMBER
    for field in path.split('.'):
        code += push(field) + GETMEMBER
    code += push('_visible', False) + SETMEMBER
code += push('this') + GETVAR + push('onEnterFrame') + function([], call(manager, '0D 6') + POP) + SETMEMBER
code += b'\x00'
attach = push(1, 'code', '90D*', 3, 'this') + GETVAR + push('attachMovie') + CALLMETHOD + POP + b'\x00'

raw = open(W + 'temple.swf', 'rb').read()
data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
hb = SD.Bits(data, 8)
hb.rect(); hb.u16(); hb.u16()
header_end = hb.pos
out = bytearray()
root_done = False
for c, body in SD.read_tags(data, header_end, len(data)):
    if c == 39 and struct.unpack_from('<H', body, 0)[0] == 255:
        inner = bytearray(body[:4])
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
# the stage of the KadoKado games: 300 x 300 (temple.swf says 700 x 480, the size of the loader's page), shown at
# 600 x 600 by ref.html: x2 like the port
def rect_bytes(vals, nb=15):
    bits = '{:05b}'.format(nb) + ''.join(format(v & ((1 << nb) - 1), '0%db' % nb) for v in vals)
    bits += '0' * ((8 - len(bits) % 8) % 8)
    return bytes(int(bits[i:i + 8], 2) for i in range(0, len(bits), 8))


rect = rect_bytes([0, 6000, 0, 6000])
assert SD.Bits(rect, 0).rect() == [0.0, 300.0, 0.0, 300.0]
swf = bytearray(b'FWS') + data[3:4] + b'\0\0\0\0' + rect + data[header_end - 4:header_end] + out
struct.pack_into('<I', swf, 4, len(swf))
name = 'ref_%s.swf' % NAME if NAME else 'ref.swf'
open(W + name, 'wb').write(swf)
print(name, len(swf))
