"""Fetch only Windows x64 export templates from the official Godot archive.

HTTP byte ranges avoid downloading other platform templates. No dependencies.
"""
import io
import pathlib
import urllib.request
import zipfile

URL = "https://github.com/godotengine/godot/releases/download/4.5.1-stable/Godot_v4.5.1-stable_export_templates.tpz"


class RemoteZip(io.RawIOBase):
    def __init__(self, url):
        request = urllib.request.Request(url, headers={"Range": "bytes=0-0"})
        with urllib.request.urlopen(request, timeout=60) as response:
            self.url = response.url
            self.length = int(response.headers["Content-Range"].split("/")[1])
        self.pos = 0

    def seek(self, offset, whence=0):
        self.pos = offset if whence == 0 else (self.pos + offset if whence == 1 else self.length + offset)
        return self.pos

    def tell(self):
        return self.pos

    def read(self, count=-1):
        if count < 0:
            count = self.length - self.pos
        if count == 0:
            return b""
        end = min(self.length, self.pos + count) - 1
        request = urllib.request.Request(self.url, headers={"Range": f"bytes={self.pos}-{end}"})
        with urllib.request.urlopen(request, timeout=180) as response:
            if response.status != 206:
                raise RuntimeError("Server did not honor range request")
            result = response.read()
        self.pos += len(result)
        return result


if __name__ == "__main__":
    destination = pathlib.Path(__file__).resolve().parent / "templates"
    destination.mkdir(exist_ok=True)
    with zipfile.ZipFile(RemoteZip(URL)) as archive:
        for filename in ("windows_release_x86_64.exe", "windows_debug_x86_64.exe"):
            member = "templates/" + filename
            print("Fetching", member, flush=True)
            content = archive.read(member)
            (destination / filename).write_bytes(content)
            print("Verified ZIP CRC; wrote", len(content), "bytes", flush=True)
