#!/usr/bin/env python3
"""
Nemesis Korea Bundle - All-in-One USB Builder
현대·기아 Gen5W 한국형 차량을 위한 올인원 무선 설치 USB 번들 패키징 스크립트.
Stable(안정 버전) 및 Latest(최신 베타) 듀얼 채널 빌드를 지원합니다.
"""

from __future__ import annotations

import argparse
import hashlib
import os
import shutil
import sys
import urllib.request
import zipfile
from pathlib import Path

VERSION = "1.0.2"

OFFICIAL_URLS = {
    "ota_package.tar": "https://github.com/xwtk/hmg_nemesis/releases/latest/download/ota_package.tar",
    "stable_hmgapi": "https://github.com/Open-HMG/HMG-API/releases/download/v1.0.2/hmgapi-1.0.2-nemesis.zip",
    "stable_kp": "https://github.com/StopDragon/korea-projection/releases/download/v1.7.3/korea-projection-1.7.3-usb.zip",
    "latest_hmgapi": "https://github.com/Open-HMG/HMG-API/releases/download/v1.1.0-rc.8/hmgapi-1.1.0-rc.8-usb.zip",
    "latest_kp": "https://github.com/StopDragon/korea-projection/releases/download/v1.7.4/korea-projection-1.7.4-usb.zip",
    "factory82": "https://github.com/armandodollia/nemesis-package-builds/releases/download/v4.2.1/hkmc.factory82.bootready-v4.2.1.nemesis.zip",
}


def calculate_sha256(file_path: Path) -> str:
    sha = hashlib.sha256()
    with open(file_path, "rb") as f:
        while chunk := f.read(65536):
            sha.update(chunk)
    return sha.hexdigest()


def find_file(name: str, candidates: list[Path]) -> Path | None:
    for c in candidates:
        if c.is_file():
            return c
    return None


def download_file(url: str, dest: Path) -> Path | None:
    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"[*] Downloading missing component from GitHub:\n    {url}")
    req = urllib.request.Request(url, headers={"User-Agent": "NemesisKoreaBundle-Builder/1.0"})
    try:
        with urllib.request.urlopen(req) as resp, open(dest, "wb") as f:
            shutil.copyfileobj(resp, f)
        print(f"[+] Download complete: {dest.name}")
        return dest
    except Exception as e:
        print(f"[!] Download failed ({e}): {url}")
        if dest.is_file():
            dest.unlink()
        return None


def extract_zip_if_needed(zip_path: Path, target_dir: Path) -> Path:
    if not target_dir.is_dir() or not any(target_dir.iterdir()):
        target_dir.mkdir(parents=True, exist_ok=True)
        print(f"[*] Extracting cache: {zip_path.name} -> {target_dir.name}...")
        with zipfile.ZipFile(zip_path, "r") as zf:
            zf.extractall(target_dir)
    return target_dir


def zip_dir(src_dir: Path, target_zip: Path) -> None:
    target_zip.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(target_zip, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for root, _, files in os.walk(src_dir):
            for file in sorted(files):
                abs_p = Path(root) / file
                rel_p = abs_p.relative_to(src_dir)
                zf.write(abs_p, rel_p.as_posix())


def build_channel(channel: str, version: str, repo_root: Path, output_dir: Path) -> Path | None:
    workspace_root = repo_root.parent
    downloads = Path.home() / "Downloads"

    print(f"\n========================================================")
    print(f"[*] Building Channel: [{channel.upper()}] (v{version})")
    print(f"========================================================")

    # 1. ota_package.tar (공통)
    nemesis_tar_candidates = [
        workspace_root / "hmg_nemesis" / "ota_package.tar",
        repo_root / "sources" / "ota_package.tar",
        downloads / "네메시스" / "nemesis-1.16.7" / "ota_package.tar",
        downloads / "nemesis-1.16.7" / "ota_package.tar",
        downloads / "ota_package.tar",
    ]
    ota_tar = find_file("ota_package.tar", nemesis_tar_candidates)

    # 2. 채널별 패키지 후보지 설정
    if channel == "stable":
        hmgapi_candidates = [
            downloads / "stable" / "hmgapi-1.0.2-nemesis" / "packages" / "hmgapi.zip",
            downloads / "네메시스" / "hmgapi-1.0.2-nemesis" / "packages" / "hmgapi.zip",
            downloads / "hmgapi-1.0.2-nemesis" / "packages" / "hmgapi.zip",
            workspace_root / "HMG-API" / "out" / "packages" / "hmgapi.zip",
            repo_root / "sources" / "stable" / "hmgapi.zip",
        ]
        kp_candidates = [
            downloads / "stable" / "korea-projection-1.7.3-usb" / "packages" / "korea.projection.zip",
            downloads / "네메시스" / "korea-projection-1.7.3-usb" / "packages" / "korea.projection.zip",
            downloads / "korea-projection-1.7.3-usb" / "packages" / "korea.projection.zip",
            workspace_root / "korea-projection" / "nemesis-pkg" / "korea.projection.zip",
            repo_root / "sources" / "stable" / "korea.projection.zip",
        ]
        shortcut_candidates = [
            downloads / "stable" / "hmgapi-1.0.2-nemesis" / "packages" / "hmgapi.nemesis-shortcut.zip",
            downloads / "네메시스" / "hmgapi-1.0.2-nemesis" / "packages" / "hmgapi.nemesis-shortcut.zip",
            downloads / "hmgapi-1.0.2-nemesis" / "packages" / "hmgapi.nemesis-shortcut.zip",
            workspace_root / "HMG-API" / "out" / "packages" / "hmgapi.nemesis-shortcut.zip",
        ]
        adb_candidates = [
            downloads / "stable" / "hmgapi-1.0.2-nemesis" / "packages" / "hmgapi.adb.zip",
            downloads / "네메시스" / "hmgapi-1.0.2-nemesis" / "packages" / "hmgapi.adb.zip",
            downloads / "hmgapi-1.0.2-nemesis" / "packages" / "hmgapi.adb.zip",
            workspace_root / "HMG-API" / "out" / "packages" / "hmgapi.adb.zip",
        ]
        hmgapi_desc = "HMG-API v1.0.2 (Stable)"
        kp_desc = "Korea Projection v1.7.3 (Stable)"
        kp_ver = "1.7.3"
        hmg_ver = "1.0.2"
    else:  # latest (beta)
        hmgapi_candidates = [
            downloads / "네메시스" / "hmgapi-1.1.0-beta.1-nemesis" / "packages" / "hmgapi.zip",
            downloads / "hmgapi-1.1.0-beta.1-nemesis" / "packages" / "hmgapi.zip",
            workspace_root / "HMG-API" / "out" / "packages" / "hmgapi.zip",
            repo_root / "sources" / "latest" / "hmgapi.zip",
        ]
        kp_candidates = [
            downloads / "네메시스" / "korea-projection-1.7.4-usb" / "packages" / "korea.projection.zip",
            downloads / "korea-projection-1.7.4-usb" / "packages" / "korea.projection.zip",
            downloads / "네메시스" / "korea-projection-1.7.4-beta.2-usb" / "packages" / "korea.projection.zip",
            downloads / "korea-projection-1.7.4-beta.2-usb" / "packages" / "korea.projection.zip",
            workspace_root / "korea-projection" / "nemesis-pkg" / "korea.projection.zip",
            repo_root / "sources" / "latest" / "korea.projection.zip",
        ]
        shortcut_candidates = [
            downloads / "네메시스" / "hmgapi-1.1.0-beta.1-nemesis" / "packages" / "hmgapi.nemesis-shortcut.zip",
            downloads / "hmgapi-1.1.0-beta.1-nemesis" / "packages" / "hmgapi.nemesis-shortcut.zip",
            workspace_root / "HMG-API" / "out" / "packages" / "hmgapi.nemesis-shortcut.zip",
        ]
        adb_candidates = [
            downloads / "네메시스" / "hmgapi-1.1.0-beta.1-nemesis" / "packages" / "hmgapi.adb.zip",
            downloads / "hmgapi-1.1.0-beta.1-nemesis" / "packages" / "hmgapi.adb.zip",
            workspace_root / "HMG-API" / "out" / "packages" / "hmgapi.adb.zip",
        ]
        hmgapi_desc = "HMG-API v1.1.0-beta.1 (Latest)"
        kp_desc = "Korea Projection v1.7.4 (Latest)"
        kp_ver = "1.7.4"
        hmg_ver = "1.1.0-beta.1"

    # 만약 korea.projection.zip이 없고 소스 폴더가 있으면 즉석 패키징
    kp_zip = find_file("korea.projection.zip", kp_candidates)
    if not kp_zip:
        kp_src_dir = workspace_root / "korea-projection" / "nemesis-pkg" / "korea.projection"
        if kp_src_dir.is_dir():
            print(f"[*] Packaging korea.projection.zip from {kp_src_dir}...")
            temp_kp_zip = output_dir / f"temp_korea_projection_{channel}.zip"
            zip_dir(kp_src_dir, temp_kp_zip)
            kp_zip = temp_kp_zip

    hmgapi_zip = find_file("hmgapi.zip", hmgapi_candidates)
    shortcut_zip = find_file("hmgapi.nemesis-shortcut.zip", shortcut_candidates)
    adb_zip = find_file("hmgapi.adb.zip", adb_candidates)

    factory82_candidates = [
        repo_root / "sources" / "cache" / "hkmc.factory82.zip",
        repo_root / "sources" / "hkmc.factory82.zip",
        downloads / "hkmc.factory82.bootready-v4.2.1.nemesis.zip",
        downloads / "hkmc.factory82.zip",
    ]
    factory82_zip = find_file("hkmc.factory82.zip", factory82_candidates)
    if not factory82_zip:
        factory82_bootready = find_file("hkmc.factory82.bootready-v4.2.1.nemesis.zip", factory82_candidates)
        if factory82_bootready:
            factory82_zip = factory82_bootready

    # 3. 로컬에서 누락된 필수 파일이 있을 경우 GitHub 공식 릴리스에서 자동 다운로드 (범용 지원)
    cache_dir = repo_root / "sources" / "cache"
    if not ota_tar:
        cached_ota = cache_dir / "ota_package.tar"
        if not cached_ota.is_file():
            download_file(OFFICIAL_URLS["ota_package.tar"], cached_ota)
        if cached_ota.is_file():
            ota_tar = cached_ota

    if not hmgapi_zip:
        url_key = f"{channel}_hmgapi"
        cached_zip = cache_dir / f"{channel}_hmgapi.zip"
        cached_extract = cache_dir / f"{channel}_hmgapi"
        if not (cached_extract / "packages" / "hmgapi.zip").is_file() and not (cached_extract / "HMGAPI" / "install" / "hmgapi.zip").is_file():
            if not cached_zip.is_file():
                download_file(OFFICIAL_URLS[url_key], cached_zip)
            if cached_zip.is_file():
                extract_zip_if_needed(cached_zip, cached_extract)
        hmgapi_zip = find_file("hmgapi.zip", [cached_extract / "packages" / "hmgapi.zip", cached_extract / "HMGAPI" / "install" / "hmgapi.zip", cached_zip])
        if not shortcut_zip:
            shortcut_zip = find_file("hmgapi.nemesis-shortcut.zip", [
                cached_extract / "packages" / "hmgapi.nemesis-shortcut.zip",
                cached_extract / "HMGAPI" / "updates" / "nemesis-shortcut-1.1.0.zip",
            ])
        if not adb_zip:
            adb_zip = find_file("hmgapi.adb.zip", [
                cached_extract / "packages" / "hmgapi.adb.zip",
                cached_extract / "HMGAPI" / "updates" / "adb-1.0.1-rc.1.zip",
            ])

    if not kp_zip:
        url_key = f"{channel}_kp"
        cached_zip = cache_dir / f"{channel}_kp.zip"
        cached_extract = cache_dir / f"{channel}_kp"
        if not (cached_extract / "packages" / "korea.projection.zip").is_file():
            if not cached_zip.is_file():
                download_file(OFFICIAL_URLS[url_key], cached_zip)
            if cached_zip.is_file():
                extract_zip_if_needed(cached_zip, cached_extract)
        kp_zip = find_file("korea.projection.zip", [cached_extract / "packages" / "korea.projection.zip"])

    if not factory82_zip:
        cached_f82 = cache_dir / "hkmc.factory82.zip"
        if not cached_f82.is_file():
            download_file(OFFICIAL_URLS["factory82"], cached_f82)
        if cached_f82.is_file():
            factory82_zip = cached_f82

    print(f"[+] Component Resolution for [{channel}]:")
    print(f"  - ota_package.tar:     {ota_tar or 'NOT FOUND'}")
    print(f"  - hmgapi.zip:          {hmgapi_zip or 'NOT FOUND'} ({hmg_ver})")
    print(f"  - korea.projection.zip:{kp_zip or 'NOT FOUND'} ({kp_ver})")
    print(f"  - hkmc.factory82.zip:  {factory82_zip or 'Optional (Skip)'} (v4.2.1)")
    print(f"  - nemesis-shortcut.zip:{shortcut_zip or 'Optional (Skip)'}")
    print(f"  - hmgapi.adb.zip:      {adb_zip or 'Optional (Skip)'}")

    if not (ota_tar and hmgapi_zip and kp_zip):
        print(f"[!] Error: Missing required files for channel '{channel}'. Aborting.")
        return None

    # 스테이징 디렉토리 준비
    staging_dir = output_dir / f"staging_{channel}"
    if staging_dir.exists():
        shutil.rmtree(staging_dir)
    staging_packages = staging_dir / "packages"
    staging_packages.mkdir(parents=True, exist_ok=True)

    # 번들링할 패키지 목록 구성
    kp_published = "2026-11-16" if channel == "latest" else "2026-11-15"
    packages_to_bundle = [
        {
            "path": "packages/hmgapi.zip",
            "name": hmgapi_desc,
            "short-desc": "Mod manager for Gen5W head units: hooks, mods, Car Report.",
            "published": "2026-11-08",
            "src": hmgapi_zip,
            "dst": "hmgapi.zip",
        },
        {
            "path": "packages/korea.projection.zip",
            "name": kp_desc,
            "short-desc": "Wireless CarPlay and Android Auto for Korean Hyundai/Kia cars",
            "published": kp_published,
            "src": kp_zip,
            "dst": "korea.projection.zip",
        },
    ]

    if factory82_zip:
        packages_to_bundle.append({
            "path": "packages/hkmc.factory82.zip",
            "name": "HKMC Factory 82 (Startup Warning Auto-Dismiss v4.2.1)",
            "short-desc": "Automatically dismisses the infotainment startup confirmation screen",
            "published": "2026-11-02",
            "src": factory82_zip,
            "dst": "hkmc.factory82.zip",
        })

    if shortcut_zip:
        packages_to_bundle.append({
            "path": "packages/hmgapi.nemesis-shortcut.zip",
            "name": "NEMESIS in the app menu",
            "short-desc": "HMG-API mod: NEMESIS in the app menu",
            "published": "2026-11-08",
            "src": shortcut_zip,
            "dst": "hmgapi.nemesis-shortcut.zip",
        })

    if adb_zip:
        packages_to_bundle.append({
            "path": "packages/hmgapi.adb.zip",
            "name": "ADB",
            "short-desc": "HMG-API mod: ADB",
            "published": "2026-11-08",
            "src": adb_zip,
            "dst": "hmgapi.adb.zip",
        })

    # NEMESIS.data 생성 (채널 맞춤형)
    nemesis_lines = [
        "[nemesis]",
        "version=1.1",
        "type=list",
        "",
    ]
    for idx, pinfo in enumerate(packages_to_bundle):
        nemesis_lines.extend([
            f"[package.{idx}]",
            f"path={pinfo['path']}",
            f"name={pinfo['name']}",
            f"short-desc={pinfo['short-desc']}",
            f"published={pinfo['published']}",
            "",
        ])
    (staging_dir / "NEMESIS.data").write_text("\n".join(nemesis_lines), encoding="utf-8")

    # README.txt 복사
    readme_template = repo_root / "template" / "README.txt"
    if readme_template.is_file():
        shutil.copy2(readme_template, staging_dir / "README.txt")

    # 파일 복사
    shutil.copy2(ota_tar, staging_dir / "ota_package.tar")
    for pinfo in packages_to_bundle:
        shutil.copy2(pinfo["src"], staging_packages / pinfo["dst"])

    # 최종 ZIP 생성
    out_zip = output_dir / f"nemesis-korea-bundle-v{version}-{channel}-usb.zip"
    print(f"[*] Packaging {out_zip.name}...")
    zip_dir(staging_dir, out_zip)

    # 정리
    shutil.rmtree(staging_dir)
    temp_zip = output_dir / f"temp_korea_projection_{channel}.zip"
    if temp_zip.is_file():
        temp_zip.unlink()

    size_mb = out_zip.stat().st_size / (1024 * 1024)
    sha256 = calculate_sha256(out_zip)
    print(f"[SUCCESS] {channel.upper()} Bundle Ready!")
    print(f"  - File:   {out_zip.name}")
    print(f"  - Size:   {size_mb:.2f} MB")
    print(f"  - SHA256: {sha256}")
    return out_zip


def build_standalone_tools(repo_root: Path, output_dir: Path) -> list[Path]:
    tools = []
    # telematics-dumper standalone USB tool
    td_src = repo_root / "tools" / "telematics-dumper"
    if td_src.is_dir():
        td_zip = output_dir / "telematics-dumper-usb.zip"
        with zipfile.ZipFile(td_zip, "w", zipfile.ZIP_DEFLATED) as z:
            for f in ["NEMESIS.data", "NEMESIS.sh", "README.txt"]:
                fp = td_src / f
                if fp.is_file():
                    z.write(fp, arcname=f)
        tools.append(td_zip)
        print(f"[+] Packaged standalone tool: {td_zip.name} ({td_zip.stat().st_size / 1024:.1f} KB)")

    return tools


def main() -> int:
    parser = argparse.ArgumentParser(description="Build Nemesis Korea Bundle USB zip packages.")
    parser.add_argument("--version", default=VERSION, help=f"Release version (default: {VERSION})")
    parser.add_argument("--channel", choices=["stable", "latest", "all"], default="all", help="Target channel (default: all)")
    parser.add_argument("--output-dir", type=Path, default=Path("dist"), help="Output directory")
    args = parser.parse_args()

    repo_root = Path(__file__).resolve().parent.parent
    output_dir = (repo_root / args.output_dir).resolve()
    output_dir.mkdir(parents=True, exist_ok=True)

    print(f"[*] Nemesis Korea Bundle Multi-Channel Builder v{args.version}")
    print(f"[*] Repository root: {repo_root}")

    targets = ["stable", "latest"] if args.channel == "all" else [args.channel]
    bundle_results = []
    for ch in targets:
        res = build_channel(ch, args.version, repo_root, output_dir)
        if res:
            bundle_results.append(res)

    tool_results = build_standalone_tools(repo_root, output_dir)
    all_results = bundle_results + tool_results

    print("\n========================================================")
    print(f"[*] Build Summary: {len(bundle_results)}/{len(targets)} bundles + {len(tool_results)} standalone tools built.")
    for r in all_results:
        print(f"  -> {r}")
    print("========================================================")

    # Downloads 폴더로 자동 복사
    downloads = Path.home() / "Downloads"
    if downloads.is_dir():
        for r in all_results:
            dst = downloads / r.name
            shutil.copy2(r, dst)
            print(f"[+] Copied to Downloads: {dst}")

    return 0 if len(bundle_results) == len(targets) else 1


if __name__ == "__main__":
    sys.exit(main())
