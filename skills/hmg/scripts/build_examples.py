r"""Compile every examples\*.prg with HMG5's build64.bat (no run) and report OK / FAIL.

Usage:  python skills/hmg/scripts/build_examples.py [path-to-HMG]   (default: two folders up)
Exit code 0 when all build. Run it after editing an example or updating HMG.
"""
import glob, os, subprocess, sys

HMG = sys.argv[1] if len(sys.argv) > 1 else os.path.abspath(os.path.join(os.path.dirname(__file__), '..', '..', '..'))
EX = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'examples'))
build = os.path.join(HMG, 'build64.bat')
bad = 0
for prg in sorted(glob.glob(os.path.join(EX, '*.prg'))):
    name = os.path.basename(prg)
    exe = prg[:-4] + '.exe'
    for f in (exe, os.path.join(EX, 'error.log')):
        if os.path.exists(f):
            os.remove(f)
    subprocess.run(['cmd', '/c', build, '/n', name], cwd=EX, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    err = os.path.join(EX, 'error.log')
    if os.path.exists(err) or not os.path.exists(exe):
        bad += 1
        print('FAIL', name)
        if os.path.exists(err):
            lines = [l for l in open(err, encoding='latin-1') if 'rror' in l][:5]
            print(''.join('     ' + l for l in lines), end='')
    else:
        print('OK  ', name)
print('%d of %d examples build' % (len(glob.glob(os.path.join(EX, '*.prg'))) - bad, len(glob.glob(os.path.join(EX, '*.prg')))))
sys.exit(1 if bad else 0)
