#!/usr/bin/env python3
"""Redacted privacy scanner.

Prints ONLY `path:line [CATEGORY]` for sensitive-looking content.
Never prints the matched text, the surrounding line, or any value.

Exit codes: 0 = clean, 1 = findings, 2 = usage error.
"""
import re
import sys
import os

# Categories are deliberately conservative: we would rather over-report a
# location than leak a value. Every report line carries the category only.
PATTERNS = [
    ("IPV4", re.compile(r"\b(?:(?:25[0-5]|2[0-4]\d|1?\d?\d)\.){3}"
                        r"(?:25[0-5]|2[0-4]\d|1?\d?\d)\b")),
    ("IPV6", re.compile(r"\b(?:[0-9a-fA-F]{1,4}:){2,7}[0-9a-fA-F]{0,4}\b")),
    ("EMAIL", re.compile(r"\b[A-Za-z0-9._%+\-]+@[A-Za-z0-9.\-]+\.[A-Za-z]{2,}\b")),
    ("AGE-RECIPIENT", re.compile(r"\bage1[0-9ac-hj-np-z]{20,}\b")),
    ("AGE-SECRET", re.compile(r"\bAGE-SECRET-KEY-1[0-9A-Z]{20,}\b")),
    ("SSH-PRIVATE", re.compile(r"-----BEGIN (?:OPENSSH|RSA|EC|PGP) PRIVATE KEY-----")),
    # NOTE: authorized SSH *public* keys are intentionally public and are not
    # flagged. Only private key material is a finding.
    ("AGE-PRIVATE", re.compile(r"AGE-SECRET-KEY-1")),
    ("GITHUB-TOKEN", re.compile(r"\b(?:ghp|gho|ghu|ghs|ghr)_[A-Za-z0-9]{20,}\b")),
    ("SLACK-TOKEN", re.compile(r"\bxox[abposr]-[A-Za-z0-9\-]{10,}\b")),
    ("TS-AUTHKEY", re.compile(r"\btskey-[a-z]+-[A-Za-z0-9]{10,}\b")),
    ("CLOUDFLARE-TOKEN", re.compile(r"\b[A-Za-z0-9_\-]{40}\b")),
    ("OPENAI-TOKEN", re.compile(r"\bsk-[A-Za-z0-9\-]{20,}\b")),
    ("TELEGRAM-BOT", re.compile(r"\b\d{8,10}:[A-Za-z0-9_\-]{30,}\b")),
    ("GHCR-PRIVATE", re.compile(r"\bghcr\.io/[A-Za-z0-9._\-]+/[A-Za-z0-9._\-/]+")),
]

# A hostname-shaped token is only interesting when it is a real registrable
# domain, so exclude the well-known public/documentation ones.
DOMAIN_RE = re.compile(
    r"(?<![\w./\-])(?:[A-Za-z0-9](?:[A-Za-z0-9\-]{0,61}[A-Za-z0-9])?\.)+"
    r"(?:com|net|org|io|dev|app|xyz|cloud|systems|tech|fr|dz|ai)\b"
)
DOMAIN_ALLOW = {
    "example.com", "example.org", "example.net", "github.com", "gitlab.com",
    "nixos.org", "nixos.wiki", "nix-community.org", "cachix.org", "nix.dev",
    "podman.io", "cloudflare.com", "tailscale.com", "sops.dev", "mozilla.org",
    "w3.org", "json-schema.org", "opencode.ai", "commandcode.ai", "openclaw.ai",
    "deepwiki.com", "oneuptime.com", "python.org", "gnu.org", "kernel.org",
    "freedesktop.org", "archlinux.org", "debian.org", "ubuntu.com", "ovh.com",
    "letsencrypt.org", "zerossl.com", "npmjs.com", "docker.io", "quay.io",
    "readthedocs.io", "rust-lang.org", "golang.org", "crates.io", "pypi.org",
    "schema.org", "tailwindcss.com", "reactjs.org", "gnome.org", "kde.org",
    "mirkolenz.github.io", "seiarotg.github.io", "docs.openclaw.ai",
    "discord.gg", "discord.com", "telegram.org", "grafana.com", "prometheus.io",
    "llm7.io", "mistral.ai", "groq.com", "openrouter.ai", "nvidia.com",
    "google.com", "googleapis.com", "api.telegram.org", "nixos-cn.org",
    "niri-epireyn.cachix.org", "noctalia.cachix.org",
    "registry.opentofu.org", "registry.terraform.io",
    # Public Nix project infrastructure cited in the docs. These belong here for
    # the same reason `nixos.org` does: they name an upstream project, not the
    # owner. Subdomains are NOT covered by the parent entry (the match is
    # exact), so each one that appears in prose must be listed separately.
    "search.nixos.org", "cache.nixos.org", "status.nixos.org",
    "discourse.nixos.org", "releases.nixos.org", "channels.nixos.org",
    "noogle.dev", "mynixos.com", "zero-to-nix.com", "git.lix.systems",
}

# Tailscale's documented CGNAT IPv6 range is a structural constant, not an
# owner identifier.
BENIGN_IPV6_PREFIXES = ("100.64.0.0", "fd7a:115c:a1e0")

# Paths whose whole point is to hold encrypted or generated data.
SKIP_PATH_PARTS = (".git/", "node_modules/", ".direnv/", "result", "/result-",
                   "scripts/privacy-scan.py")
SKIP_EXT = (".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".tiff",
            ".woff", ".woff2", ".ttf", ".otf", ".ico", ".pdf", ".zip", ".tar",
            ".gz", ".zst", ".lock")


def is_skipped(path):
    p = path.replace(os.sep, "/")
    if any(part in p for part in SKIP_PATH_PARTS):
        return True
    return p.lower().endswith(SKIP_EXT)


def scan_file(path, findings):
    try:
        with open(path, "r", encoding="utf-8", errors="strict") as fh:
            lines = fh.readlines()
    except (UnicodeDecodeError, OSError):
        return
    for lineno, line in enumerate(lines, 1):
        for category, pat in PATTERNS:
            # CLOUDFLARE-TOKEN is a very loose 40-char rule; require it to look
            # like an assignment or a clearly token-ish context to reduce noise.
            if category == "CLOUDFLARE-TOKEN":
                if not re.search(r"(TOKEN|token|API_KEY|api_key)\s*[:=]", line):
                    continue
            if pat.search(line):
                if category == "IPV4":
                    suspicious = [m.group(0) for m in pat.finditer(line)
                                  if m.group(0) not in BENIGN_IPS]
                    if not suspicious:
                        continue
                if category == "IPV6":
                    hits = [m.group(0) for m in pat.finditer(line)]
                    if all(h.lower().startswith(BENIGN_IPV6_PREFIXES)
                           for h in hits):
                        continue
                if category == "EMAIL":
                    addrs = [m.group(0).lower() for m in pat.finditer(line)]
                    if all(a.rsplit("@", 1)[-1] in BENIGN_EMAIL_DOMAINS
                           for a in addrs):
                        continue
                findings.append((path, lineno, category))
                break
        else:
            for m in DOMAIN_RE.finditer(line):
                host = m.group(0).lower()
                if host in DOMAIN_ALLOW:
                    continue
                # Allow obviously-placeholder or generic names.
                if host.startswith(("redacted", "private", "placeholder")):
                    continue
                if looks_like_nix_attr(host, line, m.end()):
                    continue
                if host.endswith(RESERVED_TLDS):
                    continue
                findings.append((path, lineno, "DOMAIN"))
                break


# Values that are structurally benign: loopback, wildcard, the Tailscale CGNAT
# documentation range, and RFC-reserved placeholder addresses.
BENIGN_IPS = {
    "127.0.0.1", "0.0.0.0", "255.255.255.255", "100.64.0.0",
    "192.0.2.1", "198.51.100.1", "203.0.113.1",
}
BENIGN_EMAIL_DOMAINS = {"example.com", "example.org", "example.net", "example.invalid"}
# RFC 2606 / RFC 6761 reserved TLDs can never be a real owner domain.
RESERVED_TLDS = ("example.invalid", ".invalid", ".test", ".localhost", ".example")

# Nix attribute paths look exactly like hostnames (e.g. "den.aspects" + ".dev").
# A real registrable domain never starts with one of these labels.
NIX_NAMESPACES = {
    "den", "inputs", "config", "lib", "pkgs", "hosts", "users", "programs",
    "services", "system", "boot", "networking", "sops", "web",
    "virtualisation", "environment", "security", "hardware", "home", "xdg",
    "perSystem", "flake", "flake-file", "nix", "nixpkgs", "systemd",
    "time", "i18n", "console", "zramSwap", "age", "ssh", "assertions",
}


def looks_like_nix_attr(host, line, end_index):
    labels = host.lower().split(".")
    if labels[0] in NIX_NAMESPACES:
        return True
    # A trailing "-" or "_" means the path continues (dev-tools, nvf_ai).
    if end_index < len(line) and line[end_index] in "-_":
        return True
    return False


def iter_targets(root):
    for dirpath, dirnames, filenames in os.walk(root):
        dirnames[:] = [
            d for d in dirnames
            if d not in {".git", "node_modules", ".direnv", ".terraform"}
        ]
        for name in filenames:
            path = os.path.join(dirpath, name)
            if not is_skipped(path):
                yield path


def main(argv):
    if len(argv) < 2:
        print("usage: privacy-scan.py PATH [PATH...]", file=sys.stderr)
        return 2

    findings = []
    for target in argv[1:]:
        if os.path.isfile(target):
            if not is_skipped(target):
                scan_file(target, findings)
        elif os.path.isdir(target):
            for path in iter_targets(target):
                scan_file(path, findings)
        else:
            print(f"privacy-scan: no such path (redacted name)", file=sys.stderr)

    # Deduplicate, keep deterministic order.
    for path, lineno, category in sorted(set(findings)):
        print(f"{path}:{lineno} [{category}]")

    if findings:
        print(f"\n{len(set(findings))} finding(s). Values intentionally not shown.",
              file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
