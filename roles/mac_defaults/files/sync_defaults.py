#!/usr/bin/python3
"""defaults の値をまとめて揃える。

osx_defaults は 1 項目ごとに Python を起動して 0.2 秒かかるので、ドメインごとに
`defaults export` で 1 回だけ読み、違う項目だけ `defaults write` する。
型も比べるので、型違いで入っている値 (旧 playbook の string など) も書き直される。

usage: sync_defaults.py check|apply '<items の JSON>'
  item: {domain, key, type: bool|int|float|string, value, host?: currentHost, state?: absent}
変えた (check では変える) 項目を 1 行ずつ出す。何も出なければ変更なし。
"""
import json
import plistlib
import subprocess
import sys

TYPES = {"bool": bool, "int": int, "float": float, "string": str}


def defaults(host):
    return ["defaults", "-currentHost"] if host == "currentHost" else ["defaults"]


def export(domain, host):
    out = subprocess.run(defaults(host) + ["export", domain, "-"], check=True, capture_output=True).stdout
    return plistlib.loads(out)


def main():
    mode, items = sys.argv[1], json.loads(sys.argv[2])
    current = {}
    for item in items:
        domain, key, host = item["domain"], item["key"], item.get("host")
        if (domain, host) not in current:
            current[(domain, host)] = export(domain, host)
        prefs = current[(domain, host)]

        if item.get("state") == "absent":
            if key not in prefs:
                continue
            cmd = defaults(host) + ["delete", domain, key]
            print(f"{domain} {key}: {prefs[key]!r} -> (absent)")
        else:
            want_type = TYPES[item["type"]]
            want = want_type(item["value"])
            # bool は int のサブクラスなので type で厳密に比べる
            if key in prefs and type(prefs[key]) is want_type and prefs[key] == want:
                continue
            value = str(want).lower() if want_type is bool else str(want)
            cmd = defaults(host) + ["write", domain, key, "-" + item["type"], value]
            print(f"{domain} {key}: {prefs.get(key)!r} -> {want!r}")
            # 値が等しいと型が違っても書き込みが省かれる (int 55 に -float 55 を書いても int のまま)。
            # 型が違うときは先に消す
            if key in prefs and type(prefs[key]) is not want_type and mode == "apply":
                subprocess.run(defaults(host) + ["delete", domain, key], check=True)

        if mode == "apply":
            subprocess.run(cmd, check=True)


if __name__ == "__main__":
    main()
