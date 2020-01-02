#!/bin/env python

import subprocess, sys
from collections import namedtuple

WARN_NOT_FOUND = "WARNING: Package(s) not found"
RETURN_OK      = 0
RETURN_CANCEL  = 1

PackageInfo = namedtuple("PackageInfo", "requires required_by")

package_dict = {}
uninstalled_dict = {}

def pip_execute(args):
  try:
    cmdline = [
      sys.executable,
      "-m",
      "pip"
    ]
    cmdline.extend(args)
    return str(subprocess.check_output(cmdline))
  except subprocess.CalledProcessError:
    return ""

def package_info(name):
  r = []
  rb = []
  output = pip_execute(["show", name])
  if output == "": return None
  for line in output.split("\\n"):
    if line.startswith("Requires: "):
      r = line[10:].split(", ")
      continue
    if line.startswith("Required-by: "):
      rb = line[13:].split(", ")
      continue
  return PackageInfo(r, rb)

def user_input_proceed():
  return input()[0].lower() == "y"

def check_packages(package_list):
  global package_dict

  for package in package_list:
    if package == "": continue
    info = package_info(package)
    if not info: continue
    package_dict[package] = info

def uninstall_packages():
  global package_dict, uninstalled_dict

  for package in package_dict.keys():
    output = pip_execute(["uninstall", "-y", package])
    if output == "":
      print("> Error uninstalling package: %s" % package)
      print(output)
    else:
      print("> Uninstalled package successfully: %s" % package)
      uninstalled_dict[package] = package_dict[package]
  package_dict = {}

def handle_uninstall():
  global package_dict

  print("> Uninstalling the following packages:")
  for package in package_dict.keys():
    print(package)
  print("> Would you like to proceed? [y/n]")
  if not user_input_proceed(): return RETURN_CANCEL
  while True:
    print("\n> Would you like to keep any of these?")
    print("> Type package names to keep, separated by spaces:")
    invalid = False
    entries = input()
    if entries != "":
      for entry in entries:
        if entry not in package_dict:
          print("> Invalid entry: %s" % entry)
          invalid = True
      if invalid:
        print("> Failed to parse entries. Would you like to try again? [y / n]")
        if not user_input_proceed():
          print("> Would you like to quit? [y/n]")
          if user_input_proceed(): return RETURN_CANCEL
        else:
          continue
      else:
        for entry in entries:
          del package_dict[entry]
    break
  uninstall_packages()
  return RETURN_OK

def fetch_remaining():
  global uninstalled_dict

  stragglers = []
  for package in uninstalled_dict.keys():
    stragglers.extend(uninstalled_dict[package].requires)
  # removes duplicates
  stragglers = list(dict.fromkeys(stragglers))
  for package in stragglers:
    if package in uninstalled_dict.keys():
      stragglers.remove(package)
  uninstalled_dict = {}
  return stragglers

def main(args):
  global package_dict

  packages = args
  while len(packages) > 0:
    check_packages(packages)
    if len(package_dict) > 0:
      if handle_uninstall() == RETURN_CANCEL: return
      packages = fetch_remaining()
    else:
      break
  print("\n> Exiting...")

if __name__ == "__main__":
  if len(sys.argv) > 1:
    main(sys.argv[1:])
