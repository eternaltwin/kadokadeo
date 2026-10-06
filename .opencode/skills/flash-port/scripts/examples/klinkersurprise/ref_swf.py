"""Makes the original game playable alone (in Ruffle) for comparisons: $KKP_WORK/klinkersurprise/ref.swf.

game.swf holds the game code in the exported clip "90D*" that the KadoKado loader attached, with the KKApi of the
loader (obfuscated name ";ndCG"). Added here, as AVM1 bytecode:
  - at the end of the frame of "90D*" (after the classes are defined): a KKApi stub (available, const, addScore,
    registerButton, gameOver, flagCheater), Manager.init() ("980Sb"["}-B2"]) and onEnterFrame = Manager.main ("0D 6");
  - on the main timeline: attachMovie("90D*", "code", 1).
usage: ref_swf.py [name clip...]   (after prepare_game.sh: $KKP_WORK/klinkersurprise/game.swf)
"""
import os, sys, struct, zlib

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, os.path.join(HERE, '..', '..', 'tools'))
import swfdump as SD

W = os.path.join(os.environ.get('KKP_WORK', os.path.expanduser('~/kadokadeo-port')), 'klinkersurprise', '')


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
    '7T4cF(': function(['s'], b''),                    # gameOver
    '0ze*c': function([], b''),                        # flagCheater
}
manager = push('980Sb') + GETVAR
code = push('__kk', 0, 'Object') + NEWOBJECT + SETVAR
code += push('_global') + GETVAR + push(';ndCG', '__kk') + GETVAR + SETMEMBER
for name, fn in api.items():
    code += push('__kk') + GETVAR + push(name) + fn + SETMEMBER
code += call(manager, '}-B2') + POP
# ref_<name>.swf (arguments: name, then clips of the game to hide, as paths of obfuscated fields from Game:
# "(KA" map, " uK=F" mcInter, "[;4B0(.-iB=" the root of the plasma)
NAME = sys.argv[1] if len(sys.argv) > 1 else None
for path in sys.argv[2:]:
    code += manager + push('_main') + GETMEMBER
    for field in path.split('.'):
        code += push(field) + GETMEMBER
    code += push('_visible', False) + SETMEMBER
code += push('this') + GETVAR + push('onEnterFrame') + function([], call(manager, '0D 6') + POP) + SETMEMBER
code += b'\x00'
attach = push(1, 'code', '90D*', 3, 'this') + GETVAR + push('attachMovie') + CALLMETHOD + POP + b'\x00'

raw = open(W + 'game.swf', 'rb').read()
data = raw[:8] + (zlib.decompress(raw[8:]) if raw[:3] == b'CWS' else raw[8:])
hb = SD.Bits(data, 8)
hb.rect(); hb.u16(); hb.u16()
header_end = hb.pos
out = bytearray()
root_done = False
for c, body in SD.read_tags(data, header_end, len(data)):
    if c == 39 and struct.unpack_from('<H', body, 0)[0] == 20481:
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
swf = bytearray(b'FWS') + data[3:4] + b'\0\0\0\0' + data[8:header_end] + out
struct.pack_into('<I', swf, 4, len(swf))
name = 'ref_%s.swf' % NAME if NAME else 'ref.swf'
open(W + name, 'wb').write(swf)
print(name, len(swf))
