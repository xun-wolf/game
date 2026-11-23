"""只保留本次改动的贴图在 .import/ 里的 .stex 缓存，其余缓存回滚到 git 版本。

背景：Godot 编辑器每次扫描都会重写全部 .import 缓存（source_md5 与仓库中存的不一致），
造成几百个无意义改动。这里先把改过的贴图对应 .stex 备份出来，回滚缓存后再放回去。
"""

import glob
import os
import shutil
import subprocess
import tempfile

ROOT = r"D:\aigame\GameIame"
SOURCES = glob.glob(os.path.join(ROOT, "seasons", "summer", "farm", "*.png"))
SOURCES.append(os.path.join(ROOT, "seasons", "fx", "snow.png"))

backup = tempfile.mkdtemp(prefix="stex_")
saved = []
for src in SOURCES:
    imp = src + ".import"
    if not os.path.exists(imp):
        print("no .import for", src)
        continue
    rel = None
    with open(imp, "r", encoding="utf-8") as f:
        for line in f:
            if line.startswith('path="res://.import/'):
                rel = line[len('path="res://'):].rstrip('"\r\n')
                break
    if not rel:
        print("no path in", imp)
        continue
    stex = os.path.join(ROOT, rel.replace("/", os.sep))
    if not os.path.exists(stex):
        print("missing stex", stex)
        continue
    dst = os.path.join(backup, os.path.basename(stex))
    shutil.copy2(stex, dst)
    saved.append((stex, dst))
    print("kept", os.path.basename(stex), "<-", os.path.basename(src))

subprocess.run(["git", "-C", ROOT, "checkout", "--", ".import"], check=True)
subprocess.run(["git", "-C", ROOT, "checkout", "--", "default_bus_layout.tres"], check=False)

for stex, dst in saved:
    shutil.copy2(dst, stex)
print("restored", len(saved), "stex files")
