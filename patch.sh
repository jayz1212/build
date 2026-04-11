#!/usr/bin/env python3
#
# Python3-safe version of check_radio_versions.py
#

import os
import sys

def check_file(fn, key, allowed):
    try:
        with open(fn + ".sha1", "r") as f:
            version = f.read().strip()
    except IOError:
        print("*** Error opening \"%s.sha1\"; can't verify %s" % (fn, key))
        return False

    if not any(v in allowed for v in [version]):
        print("*** \"%s\" is version %s; not any %s allowed by \"%s\"." %
              (fn, version, allowed, key))
        return False

    return True


def main():
    # If no args, just exit clean (TWRP doesn't really need this)
    if len(sys.argv) < 2:
        return 0

    success = True

    for arg in sys.argv[1:]:
        parts = arg.split("=")
        if len(parts) != 2:
            continue

        key = parts[0]
        allowed = parts[1].split(",")

        fn = os.path.join("radio", key)

        if not check_file(fn, key, allowed):
            success = False

    return 0 if success else 1


if __name__ == "__main__":
    sys.exit(main())
