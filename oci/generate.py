#!/usr/bin/env python3

import os
import sys
import json
import subprocess

OUTPUT = "/output/image.tar"
BUILD  = "/build"


def info(msg):
    blue  = f"\x1B[34;1m"
    green = f"\x1B[32;1m"
    reset = f"\x1B[0m"
    sys.stderr.write(f"{blue}[{green}*{blue}]{reset} {msg}\n")


def read_json(filename):
    return json.load(open(filename))


def write_json(filename, js):
    with open(filename, "w") as fd:
        fd.write(json.dumps(js, indent=4))


def write_blob(filename, mimetype):
    hash = subprocess.check_output(["sha256sum", filename], text=True).split()[0]
    size = os.path.getsize(filename)
    os.rename(filename, f"blobs/sha256/{hash}")

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

def main():
    os.mkdir(BUILD)
    os.chdir(BUILD)
    os.makedirs("blobs/sha256")

    raptor_info = read_json("/input/raptor.json")
    target = raptor_info["targets"][0]

    info(f"Building layers for target [{target}]..")
    layers = []
    for layer in raptor_info["layers"][target]:
        TMP = "tmp.tar"
        info(f" .. [{layer}]")
        subprocess.check_call(["tar", "-cf", TMP, "-C", f"/input/{layer}", "."])
        layer_info = write_blob(TMP, MIME_TYPE_IMAGE_LAYER)
        layers.append(layer_info)

    config = {
        # FIXME: don't assume os and arch
        "architecture": "amd64",
        "os": "linux",
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
            "Config": config_blob["digest"].replace("sha256:", "blobs/sha256/"),
            "RepoTags": [f"{refname}:latest"],
            "Layers": [layer["digest"].replace("sha256:", "blobs/sha256/") for layer in layers],
            "LayerSources": { item["digest"]: item for item in layers }
        }
    ]

    write_json("index.json", index)
    write_json("manifest.json", manifest)
    write_json("oci-layout", {"imageLayoutVersion": "1.0.0"})

    info(f"Building tar for target [{target}]")

    subprocess.check_call(["tar", "-cf", OUTPUT, "blobs", "index.json", "manifest.json", "oci-layout"])

    info(f"Done")


if __name__ == "__main__":
    main()
