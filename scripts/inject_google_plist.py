#!/usr/bin/env python3
"""
Injecte GoogleService-Info.plist dans ios/Runner.xcodeproj/project.pbxproj.

flutter create génère un project.pbxproj vierge qui ne référence pas
GoogleService-Info.plist → Firebase crashe au lancement (plist absente du bundle).

Ce script fait 4 insertions chirurgicales SANS reformater le fichier :
  1. PBXBuildFile entry
  2. PBXFileReference entry
  3. Référence UUID dans le groupe Runner (après AppDelegate.swift)
  4. Référence UUID dans Copy Bundle Resources (après Assets.xcassets)

Pourquoi Python et pas xcodeproj (gem Ruby) ?
  La gem xcodeproj réécrit tout le pbxproj dans son propre format.
  Le Swift Build System de Xcode 15+ (SWBUtil) rejette ce format avec :
  "unable to read input file as a property list (PropertyListConversionError 2)"
"""

import re
import secrets
import sys

PBXPROJ = "ios/Runner.xcodeproj/project.pbxproj"


def new_uuid() -> str:
    """UUID au format pbxproj : 24 caractères hexadécimaux majuscules."""
    return secrets.token_hex(12).upper()


def main() -> None:
    with open(PBXPROJ, "r", encoding="utf-8") as f:
        content = f.read()

    if "GoogleService-Info.plist" in content:
        print("[inject_google_plist] GoogleService-Info.plist déjà présent — skip")
        return

    file_ref_id = new_uuid()   # PBXFileReference UUID
    build_file_id = new_uuid() # PBXBuildFile UUID

    # ── 1. PBXBuildFile ────────────────────────────────────────────────────
    build_file_entry = (
        f"\t\t{build_file_id} /* GoogleService-Info.plist in Resources */ = "
        f"{{isa = PBXBuildFile; fileRef = {file_ref_id}"
        f" /* GoogleService-Info.plist */; }};\n"
    )
    content = content.replace(
        "/* Begin PBXBuildFile section */",
        "/* Begin PBXBuildFile section */\n" + build_file_entry,
        1,
    )

    # ── 2. PBXFileReference ────────────────────────────────────────────────
    file_ref_entry = (
        f"\t\t{file_ref_id} /* GoogleService-Info.plist */ = "
        f"{{isa = PBXFileReference; fileEncoding = 4; "
        f"lastKnownFileType = text.plist.xml; "
        f'name = "GoogleService-Info.plist"; '
        f'path = "GoogleService-Info.plist"; '
        f'sourceTree = "<group>"; }};\n'
    )
    content = content.replace(
        "/* Begin PBXFileReference section */",
        "/* Begin PBXFileReference section */\n" + file_ref_entry,
        1,
    )

    # ── 3. Groupe Runner (après AppDelegate.swift) ─────────────────────────
    content = re.sub(
        r"(AppDelegate\.swift \*/,)",
        r"\1\n\t\t\t\t" + file_ref_id + r" /* GoogleService-Info.plist */,",
        content,
        count=1,
    )

    # ── 4. Copy Bundle Resources (après Assets.xcassets) ──────────────────
    content = re.sub(
        r"(Assets\.xcassets in Resources \*/,)",
        r"\1\n\t\t\t\t" + build_file_id + r" /* GoogleService-Info.plist in Resources */,",
        content,
        count=1,
    )

    with open(PBXPROJ, "w", encoding="utf-8") as f:
        f.write(content)

    print("[inject_google_plist] GoogleService-Info.plist injecté avec succès ✓")
    print(f"  PBXFileReference : {file_ref_id}")
    print(f"  PBXBuildFile     : {build_file_id}")


if __name__ == "__main__":
    main()
