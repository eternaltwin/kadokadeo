#!/usr/bin/env python3
import argparse, configparser, re, sys, os

parser = argparse.ArgumentParser(description="Set Godot custom templates in export_presets.cfg")
parser.add_argument("release_path", help="Path to custom_template/release")
parser.add_argument("--debug", dest="debug_path", help="Path to custom_template/debug (optional)")
parser.add_argument("--file", default="export_presets.cfg", help="Path to export_presets.cfg (default: export_presets.cfg)")
parser.add_argument("--preset-name", default="Web", help='Preset name to target (default: "Web")')
args = parser.parse_args()

cfg = configparser.ConfigParser(interpolation=None, strict=False)
# Keep case and slashes as-is
cfg.optionxform = str

if not os.path.exists(args.file):
    print(f"Error: {args.file} not found", file=sys.stderr)
    sys.exit(1)

cfg.read(args.file)

preset_num = None
rx = re.compile(r"^preset\.(\d+)$")

# Find preset.N where name == args.preset_name
for section in cfg.sections():
    m = rx.match(section)
    if not m:
        continue
    if cfg[section].get("name") == '"'+args.preset_name+'"':
        preset_num = m.group(1)
        break

if preset_num is None:
    print(f'Error: No preset with name="{args.preset_name}" found.', file=sys.stderr)
    sys.exit(2)

options_section = f"preset.{preset_num}.options"
if options_section not in cfg.sections():
    cfg.add_section(options_section)

cfg[options_section]['custom_template/release'] = '"'+args.release_path+'"'
if args.debug_path:
    cfg[options_section]['custom_template/debug'] = '"'+args.debug_path+'"'

with open(args.file, "w") as f:
    cfg.write(f)

print(f'Updated [{options_section}] custom_template/release = "{args.release_path}"')
if args.debug_path:
    print(f'Updated [{options_section}] custom_template/debug   = "{args.debug_path}"')
