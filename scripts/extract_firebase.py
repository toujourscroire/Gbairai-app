#!/usr/bin/env python3
"""
Décode GOOGLE_SERVICE_INFO_PLIST (base64) et extrait les valeurs Firebase.
Sortie : commandes `export KEY=VALUE` prêtes pour eval dans bash.

Usage dans CI :
    eval $(python3 scripts/extract_firebase.py "$GOOGLE_SERVICE_INFO_PLIST")

Sur erreur (plist invalide, secret absent) : exporte des strings vides.
FcmService.dart détecte les valeurs vides et désactive FCM silencieusement.
"""
import sys
import base64
import plistlib

# Mapping clés plist → noms de variables bash
KEYS = [
    ("API_KEY",        "FIREBASE_API_KEY"),
    ("GOOGLE_APP_ID",  "FIREBASE_APP_ID"),
    ("GCM_SENDER_ID",  "FIREBASE_SENDER_ID"),
    ("PROJECT_ID",     "FIREBASE_PROJECT_ID"),
    ("STORAGE_BUCKET", "FIREBASE_STORAGE_BUCKET"),
    ("BUNDLE_ID",      "FIREBASE_IOS_BUNDLE_ID"),
]

FALLBACK_BUNDLE = "ci.gbairai.app"


def emit_empty() -> None:
    """Exporte des valeurs vides — Firebase désactivé, app ne crashe pas."""
    for _, env_key in KEYS:
        default = FALLBACK_BUNDLE if env_key == "FIREBASE_IOS_BUNDLE_ID" else ""
        print(f"export {env_key}='{default}'")


def main() -> None:
    if len(sys.argv) < 2 or not sys.argv[1].strip():
        print("# extract_firebase: GOOGLE_SERVICE_INFO_PLIST absent", file=sys.stderr)
        emit_empty()
        return

    b64_input = sys.argv[1].strip()

    try:
        # base64.b64decode ignore les whitespace/newlines — plus robuste que base64 CLI
        raw = base64.b64decode(b64_input + "==")  # padding tolérant
        plist = plistlib.loads(raw)
    except Exception as exc:
        print(f"# extract_firebase: décodage échoué — {exc}", file=sys.stderr)
        emit_empty()
        return

    for plist_key, env_key in KEYS:
        val = str(plist.get(plist_key, "")).strip()
        if not val and env_key == "FIREBASE_IOS_BUNDLE_ID":
            val = FALLBACK_BUNDLE
        # Échapper les apostrophes pour la syntaxe bash single-quote
        val_escaped = val.replace("'", "'\\''")
        print(f"export {env_key}='{val_escaped}'")

    print("# extract_firebase: OK", file=sys.stderr)


if __name__ == "__main__":
    main()
