#!/usr/bin/env python3
import urllib.request
import json
import re
import sys
import os

HUB_URL = "https://antigravity-hub-auto-updater-974169037036.us-central1.run.app/releases"
IDE_URL = "https://antigravity-ide-auto-updater-974169037036.us-central1.run.app/releases"

def fetch_latest(url):
    try:
        req = urllib.request.Request(url, headers={'User-Agent': 'Mozilla/5.0'})
        with urllib.request.urlopen(req) as response:
            data = json.loads(response.read().decode('utf-8'))
            return data[0] if data else None
    except Exception as e:
        print(f"Error fetching {url}: {e}", file=sys.stderr)
        return None

def main():
    agent_data = fetch_latest(HUB_URL)
    ide_data = fetch_latest(IDE_URL)

    if not agent_data or not ide_data:
        print("Failed to fetch latest releases.", file=sys.stderr)
        sys.exit(1)

    agent_version = agent_data.get("version")
    agent_exec_id = agent_data.get("execution_id")

    ide_version = ide_data.get("version")
    ide_exec_id = ide_data.get("execution_id")

    if not all([agent_version, agent_exec_id, ide_version, ide_exec_id]):
        print("Invalid release data format.", file=sys.stderr)
        sys.exit(1)

    agent_url_x64 = f"https://storage.googleapis.com/antigravity-public/antigravity-hub/{agent_version}-{agent_exec_id}/linux-x64/Antigravity.tar.gz"
    agent_url_arm64 = f"https://storage.googleapis.com/antigravity-public/antigravity-hub/{agent_version}-{agent_exec_id}/linux-arm/Antigravity.tar.gz"

    ide_url_x64 = f"https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/{ide_version}-{ide_exec_id}/linux-x64/Antigravity%20IDE.tar.gz"
    ide_url_arm64 = f"https://edgedl.me.gvt1.com/edgedl/release2/j0qc3/antigravity/stable/{ide_version}-{ide_exec_id}/linux-arm/Antigravity%20IDE.tar.gz"

    print(f"Latest Agent: {agent_version} ({agent_url_x64})")
    print(f"Latest IDE: {ide_version} ({ide_url_x64})")

    # Update install.sh
    update_file("install.sh", {
        r'^VERSION_IDE=".*?"': f'VERSION_IDE="{ide_version}"',
        r'^VERSION_AGENT=".*?"': f'VERSION_AGENT="{agent_version}"',
        r'^DOWNLOAD_URL_IDE_X64=".*?"': f'DOWNLOAD_URL_IDE_X64="{ide_url_x64}"',
        r'^DOWNLOAD_URL_IDE_ARM64=".*?"': f'DOWNLOAD_URL_IDE_ARM64="{ide_url_arm64}"',
        r'^DOWNLOAD_URL_AGENT_X64=".*?"': f'DOWNLOAD_URL_AGENT_X64="{agent_url_x64}"',
        r'^DOWNLOAD_URL_AGENT_ARM64=".*?"': f'DOWNLOAD_URL_AGENT_ARM64="{agent_url_arm64}"',
    })

    # Update build.sh
    update_file("build.sh", {
        r'^FALLBACK_VERSION_IDE=".*?"': f'FALLBACK_VERSION_IDE="{ide_version}"',
        r'^FALLBACK_VERSION_AGENT=".*?"': f'FALLBACK_VERSION_AGENT="{agent_version}"',
        r'^FALLBACK_URL_IDE_X64=".*?"': f'FALLBACK_URL_IDE_X64="{ide_url_x64}"',
        r'^FALLBACK_URL_AGENT_X64=".*?"': f'FALLBACK_URL_AGENT_X64="{agent_url_x64}"',
    })

def update_file(filepath, replacements):
    if not os.path.exists(filepath):
        print(f"Warning: {filepath} not found.", file=sys.stderr)
        return

    with open(filepath, 'r') as f:
        content = f.read()

    new_content = content
    for pattern, repl in replacements.items():
        new_content = re.sub(pattern, repl, new_content, flags=re.MULTILINE)

    if new_content != content:
        with open(filepath, 'w') as f:
            f.write(new_content)
        print(f"Updated {filepath}")
    else:
        print(f"No changes needed in {filepath}")

if __name__ == "__main__":
    main()
