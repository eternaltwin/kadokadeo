"""Makes the original game playable alone (in Ruffle) for comparisons: $KKP_WORK/quadrikolor/ref.swf
(from opalusfactory/ref_swf.py).

taupebille.swf holds the game code (MTypes) in the exported clip "90D*" (sprite 173) that the KadoKado loader attached.
The loader also gave the code its API and the MTypes standard library; added here, as AVM1 bytecode, in a DoAction
BEFORE the code of "90D*" (Const calls KKApi.const / aconst while the classes are defined):
  - KKApi (";ndCG"): available, const, aconst, val, cadd, cmult, addScore, registerButton, gameOver, flagCheater;
  - Std ("3Wt"): random, getTimer, isNaN, xmouse / ymouse (_root._xmouse), attachMC (attachMovie as link@depth),
    createEmptyMC, callback (a closure: o[f].apply(o, arguments)), setGlobal;
  - Log ("]{i"): setColor, trace (nothing);
and after the code: Manager.init(this) ("980Sb"["}-B2"]) and onEnterFrame = Manager.main ("0D 6"); on the main
timeline: attachMovie("90D*", "code", 1). The stage is cut to the 300 x 300 of the game (the loader's 700 x 480).
usage: ref_swf.py      (after prepare_game.sh: $KKP_WORK/quadrikolor/taupebille.swf)
"""
import os, sys, struct, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'quadrikolor', '')


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


GETVAR, SETVAR, GETMEMBER, SETMEMBER, CALLMETHOD, CALLFUNCTION, NEWOBJECT, POP, RETURN = (
    b'\x1c', b'\x1d', b'\x4e', b'\x4f', b'\x52', b'\x3d', b'\x40', b'\x17', b'\x3e')
ADD2, MULTIPLY, RANDOM, GETTIME = b'\x47', b'\x0c', b'\x30', b'\x34'


def function(params, body):
    """DefineFunction (anonymous: pushed on the stack)"""
    h = b'\x00' + struct.pack('<H', len(params)) + b''.join(p.encode() + b'\x00' for p in params) + struct.pack('<H', len(body))
    return b'\x9b' + struct.pack('<H', len(h)) + h + body


def var(name):
    return push(name) + GETVAR


def call(obj_code, method, nargs=0):
    return push(nargs) + obj_code + push(method) + CALLMETHOD


def tag(code, body):
    if len(body) == 0:
        return struct.pack('<H', (code << 6) | len(body)) + body
    return struct.pack('<HI', (code << 6) | 63, len(body)) + body


def global_object(name, methods):
    code = push('__o', 0, 'Object') + NEWOBJECT + SETVAR
    code += var('_global') + push(name) + var('__o') + SETMEMBER
    for m, fn in methods.items():
        code += var('__o') + push(m) + fn + SETMEMBER
    return code


ret_arg = var('v') + RETURN
noop = lambda *p: function(list(p), b'')
KKAPI = {
    '(kJ+1(': function([], push(True) + RETURN),      # available
    '-Q)9)': function(['v'], ret_arg),                 # const
    '*G6KR': function(['v'], ret_arg),                 # aconst
    '8kN': function(['v'], ret_arg),                   # val
    '3B(*': function(['a', 'b'], var('a') + var('b') + ADD2 + RETURN),         # cadd
    '4u57)': function(['a', 'b'], var('a') + var('b') + MULTIPLY + RETURN),    # cmult
    '5b)bA(': function(['v'], ret_arg),                # addScore
    '7vdL6(': noop('b'),                               # registerButton
    '7T4cF(': noop('s'),                               # gameOver
    '0ze*c': noop(),                                   # flagCheater
}
STD = {
    'random': function(['n'], var('n') + RANDOM + RETURN),
    'getTimer': function([], GETTIME + RETURN),
    'isNaN': function(['v'], var('v') + push(1, 'isNaN') + CALLFUNCTION + RETURN),
    ',))hC': function([], var('_root') + push('_xmouse') + GETMEMBER + RETURN),     # xmouse
    '8p1P5': function([], var('_root') + push('_ymouse') + GETMEMBER + RETURN),     # ymouse
    # attachMC(mc, link, depth): mc.attachMovie(link, link + "@" + depth, depth)
    '7bSH*': function(['mc', 'l', 'd'], var('d') + var('l') + push('@') + ADD2 + var('d') + ADD2 + var('l') +
                      push(3) + var('mc') + push('attachMovie') + CALLMETHOD + RETURN),
    # createEmptyMC(mc, depth): mc.createEmptyMovieClip("empty@" + depth, depth)
    '-4*l((': function(['mc', 'd'], var('d') + push('empty@') + var('d') + ADD2 +
                       push(2) + var('mc') + push('createEmptyMovieClip') + CALLMETHOD + RETURN),
    # callback(o, f): function() { return o[f].apply(o, arguments) }
    '6{VYR': function(['o', 'f'], function([], var('arguments') + var('o') + push(2) + var('o') + var('f') + GETMEMBER +
                                           push('apply') + CALLMETHOD + RETURN) + RETURN),
    # setGlobal(name, v)
    '3Wr3K(': function(['n', 'v'], var('_global') + var('n') + var('v') + SETMEMBER),
}
LOG = {'(H5 S': noop('c'), 'trace': noop('s')}

stub = global_object(';ndCG', KKAPI) + global_object('3Wt', STD) + global_object(']{i', LOG) + b'\x00'
manager = var('980Sb')
start = push('this') + GETVAR + push(1) + manager + push('}-B2') + CALLMETHOD + POP
start += push('this') + GETVAR + push('onEnterFrame') + function([], call(manager, '0D 6') + POP) + SETMEMBER
start += b'\x00'
attach = push(1, 'code', '90D*', 3, 'this') + GETVAR + push('attachMovie') + CALLMETHOD + POP + b'\x00'

raw = open(W + 'taupebille.swf', 'rb').read()
data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
hb = SD.Bits(data, 8)
hb.rect(); hb.u16(); hb.u16()
header_end = hb.pos
rate_count = data[header_end - 4:header_end]
out = bytearray()
root_done = False
for c, body in SD.read_tags(data, header_end, len(data)):
    if c == 39 and struct.unpack_from('<H', body, 0)[0] == 173:
        inner = bytearray(body[:4])
        n = 0
        for c2, b2 in SD.read_tags(body, 4, len(body)):
            if c2 == 12 and n == 0:
                inner += tag(12, stub) + tag(12, b2) + tag(12, start)
                n += 1
                continue
            inner += tag(c2, b2)
        assert n == 1
        body = bytes(inner)
    if c == 1 and not root_done:
        out += tag(12, attach)
        root_done = True
    out += tag(c, body)


# the stage: 300 x 300 (RECT of 15 bits per value: 0, 6000, 0, 6000 twips)
def rect(x0, x1, y0, y1):
    nb = 15
    bits = format(nb, '05b') + ''.join(format(v, '0%db' % nb) for v in (x0, x1, y0, y1))
    bits += '0' * (-len(bits) % 8)
    return bytes(int(bits[i:i + 8], 2) for i in range(0, len(bits), 8))


swf = bytearray(b'FWS') + data[3:4] + b'\0\0\0\0' + rect(0, 6000, 0, 6000) + rate_count + out
struct.pack_into('<I', swf, 4, len(swf))
open(W + 'ref.swf', 'wb').write(swf)
print('ref.swf', len(swf))
