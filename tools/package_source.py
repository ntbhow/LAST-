"""Create a portable source archive without engines, caches or user settings."""
from pathlib import Path
from zipfile import ZipFile, ZIP_DEFLATED

root = Path(__file__).resolve().parent.parent
files = [root / name for name in (
    "project.godot", "main.tscn", "export_presets.cfg", "README.md", "LICENSE", ".gitignore"
)]
for directory in ("scripts", "data", "assets", "docs"):
    files.extend(p for p in (root / directory).rglob("*") if p.is_file() and p.suffix != ".import")
files.extend(p for p in (root / "tools").iterdir() if p.suffix in (".ps1", ".py", ".gd"))
files.extend(p for p in (root / "tests").iterdir() if p.suffix in (".gd", ".json", ".png"))
with ZipFile(root / "build/DUSTLINE-Source.zip", "w", ZIP_DEFLATED) as archive:
    for path in files:
        archive.write(path, "DUSTLINE/" + path.relative_to(root).as_posix())
print("Source archive:", len(files), "files")
