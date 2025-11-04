#!/usr/bin/env python3

import os
import sys
import json
import shutil
import tempfile
import datetime
import subprocess

INPUT  = "/input"
OUTPUT = "/output/image.tar"
CACHE  = "/cache"
LAYERS = f"{CACHE}/layers"
BUILD  = f"{CACHE}/build"
BLOBS  = "blobs"
BLOBS_SHA256 = f"{BLOBS}/sha256"

def info(msg):
    blue  = f"\x1B[34;1m"
    green = f"\x1B[32;1m"
    reset = f"\x1B[0m"
    sys.stderr.write(f"{blue}[{green}*{blue}]{reset} {msg}\n")


def read_json(filename):
    return json.load(open(filename))


def write_json(filename, js):
    tmpname = f"{filename}.tmp"
    with open(tmpname, "w") as fd:
        fd.write(json.dumps(js, indent=4))
    os.utime(tmpname, ns=(0,0))
    os.replace(tmpname, filename)


def write_blob(filename, mimetype):
    hash = subprocess.check_output(["sha256sum", filename], text=True).split()[0]
    size = os.path.getsize(filename)
    os.utime(filename, ns=(0,0))
    os.replace(filename, f"{BLOBS_SHA256}/{hash}")

    layer_info = {
        "mediaType": mimetype,
        "digest": f"sha256:{hash}",
        "size": size
    }

    return layer_info


def write_json_blob(js, mimetype):
    write_json("tmp.json", js)
    return write_blob("tmp.json", mimetype)


MIME_TYPE_IMAGE_LAYER    = "application/vnd.oci.image.layer.v1.tar"
MIME_TYPE_IMAGE_CONFIG   = "application/vnd.oci.image.config.v1+json"
MIME_TYPE_IMAGE_MANIFEST = "application/vnd.oci.image.manifest.v1+json"
MIME_TYPE_IMAGE_INDEX    = "application/vnd.oci.image.index.v1+json"

def build():
    raptor_info = read_json(f"{INPUT}/raptor.json")
    target = raptor_info["targets"][0]

    info(f"Building layers for target [{target}]..")
    layers = []
    for layer in raptor_info["layers"][target]:
        TMP = "tmp.tar"
        layer_id = layer.split("-")[-1]
        cache_blob = f"{LAYERS}/{layer_id}"
        cache_json = f"{cache_blob}.json"
        try:
            layer_info = read_json(cache_json)
            info(f" .. [{layer}] (cached)")
            hash = layer_info["digest"].split(":")[1]
            os.link(cache_blob, f"{BLOBS_SHA256}/{hash}")
            layers.append(layer_info)
            continue
        except Exception as exc:
            pass

        info(f" .. [{layer}] (new)")
        subprocess.check_call(["tar", "-cf", TMP, "-C", f"{INPUT}/{layer}", "."])
        os.utime(TMP, ns=(0,0))
        os.link(TMP, cache_blob)
        layer_info = write_blob(TMP, MIME_TYPE_IMAGE_LAYER)
        write_json(cache_json, layer_info)
        layers.append(layer_info)

    newest = max(os.stat(f"{INPUT}/{layer}").st_mtime for layer in raptor_info["layers"][target])
    created = datetime.datetime.fromtimestamp(newest).astimezone(datetime.UTC)

    config = {
        # FIXME: don't assume os and arch
        "architecture": "amd64",
        "os": "linux",
        "created": created.strftime("%Y-%m-%dT%H:%M:%S.%f%:z"),
        "rootfs": {
            "type": "layers",
            "diff_ids": [layer["digest"] for layer in layers],
        },
    }
    config_blob = write_json_blob(config, MIME_TYPE_IMAGE_CONFIG)

    manifest = {
        "schemaVersion": 2,
        "mediaType": MIME_TYPE_IMAGE_MANIFEST,
        "config": config_blob,
        "layers": layers,
    }
    manifest_blob = write_json_blob(manifest, MIME_TYPE_IMAGE_MANIFEST)

    index = {
        "schemaVersion": 2,
        "mediaType": MIME_TYPE_IMAGE_INDEX,
        "manifests": [manifest_blob]
    }

    if target.startswith("$."):
        refname = target[2:]
    elif target.startswith("$"):
        refname = target[1:]
    else:
        refname = target[0:]

    # refname = "/".join(refname.split("."))

    manifest = [
        {
            "Config": config_blob["digest"].replace("sha256:", f"{BLOBS_SHA256}/"),
            "RepoTags": [f"{refname}:latest"],
            "Layers": [layer["digest"].replace("sha256:", f"{BLOBS_SHA256}/") for layer in layers],
            "LayerSources": { item["digest"]: item for item in layers }
        }
    ]

    write_json("index.json", index)
    write_json("manifest.json", manifest)
    write_json("oci-layout", {"imageLayoutVersion": "1.0.0"})

    info(f"Building tar for target [{target}]")

    os.utime(BLOBS, ns=(0,0))
    os.utime(BLOBS_SHA256, ns=(0,0))
    subprocess.check_call(["tar", "-cf", OUTPUT, "blobs", "index.json", "manifest.json", "oci-layout"])

    info(f"Done")


def main():
    os.makedirs(LAYERS, exist_ok=True)
    os.makedirs(BUILD, exist_ok=True)

    with tempfile.TemporaryDirectory(dir=BUILD) as build_dir:
        os.chdir(build_dir)
        os.makedirs(BLOBS_SHA256)
        build()

if __name__ == "__main__":
    main()
