#!/usr/bin/env python3
"""Vampire OS signed update metadata client; downloads only, never applies updates."""
import argparse, hashlib, json, os, pathlib, re, shutil, subprocess, sys, tempfile
import urllib.error, urllib.parse, urllib.request
CONFIG=pathlib.Path(os.environ.get("VAMPIRE_UPDATE_CONFIG","/etc/vampire/update.json"))
CACHE=pathlib.Path(os.environ.get("VAMPIRE_UPDATE_CACHE","/var/cache/vampire/updates"))
MAX_MANIFEST=1024*1024
MAX_SIGNATURE=64*1024
MAX_ARTIFACT=4*1024*1024*1024

def fail(message):
    print("vupdate: error:",message,file=sys.stderr); raise SystemExit(1)

def is_https_url(value):
    parsed=urllib.parse.urlparse(value if isinstance(value,str) else "")
    return parsed.scheme=="https" and bool(parsed.netloc) and not parsed.username and not parsed.password

def validate_manifest(data,channel="stable",architecture="x86_64"):
    if not isinstance(data,dict) or data.get("format")!=1: raise ValueError("unsupported update manifest format")
    if data.get("channel")!=channel: raise ValueError("manifest channel mismatch")
    if data.get("architecture")!=architecture: raise ValueError("manifest architecture mismatch")
    version=data.get("version")
    if not isinstance(version,str) or not re.fullmatch(r"[0-9A-Za-z][0-9A-Za-z.+~-]{0,63}",version): raise ValueError("invalid release version")
    artifact=data.get("artifact")
    if not isinstance(artifact,dict): raise ValueError("missing artifact metadata")
    if not is_https_url(artifact.get("url")): raise ValueError("artifact URL must use HTTPS")
    digest=artifact.get("sha256")
    if not isinstance(digest,str) or not re.fullmatch(r"[0-9a-fA-F]{64}",digest): raise ValueError("invalid artifact SHA-256")
    size=artifact.get("size")
    if not isinstance(size,int) or isinstance(size,bool) or size<1 or size>MAX_ARTIFACT: raise ValueError("invalid artifact size")
    return data

def read_config():
    try: cfg=json.loads(CONFIG.read_text(encoding="utf-8"))
    except FileNotFoundError: fail("configuration not found: "+str(CONFIG))
    except (OSError,json.JSONDecodeError) as exc: fail("cannot read configuration: "+str(exc))
    if not isinstance(cfg,dict): fail("configuration must be a JSON object")
    if not is_https_url(cfg.get("manifest_url")): fail("configure an HTTPS manifest_url in "+str(CONFIG))
    if not is_https_url(cfg.get("signature_url")): fail("configure an HTTPS signature_url in "+str(CONFIG))
    if not isinstance(cfg.get("minisign_public_key"),str) or not cfg["minisign_public_key"].strip(): fail("configure a trusted Minisign public key")
    if cfg.get("channel","stable") not in ("stable","testing"): fail("channel must be stable or testing")
    return cfg

def fetch_bytes(url,limit):
    if not is_https_url(url): fail("all update URLs must use HTTPS")
    req=urllib.request.Request(url,headers={"User-Agent":"vupdate/0.1"})
    try:
        with urllib.request.urlopen(req,timeout=30) as response:
            if response.status!=200: fail("server returned HTTP "+str(response.status))
            data=response.read(limit+1)
    except (OSError,urllib.error.URLError) as exc: fail("download failed: "+str(exc))
    if len(data)>limit: fail("download exceeds size limit")
    return data

def verified_manifest():
    cfg=read_config()
    if not shutil.which("minisign"): fail("minisign is required to verify update metadata")
    manifest_bytes=fetch_bytes(cfg["manifest_url"],MAX_MANIFEST)
    signature_bytes=fetch_bytes(cfg["signature_url"],MAX_SIGNATURE)
    CACHE.mkdir(parents=True,exist_ok=True)
    with tempfile.TemporaryDirectory(prefix=".vupdate-",dir=CACHE) as tmp:
        manifest_path=pathlib.Path(tmp)/"manifest.json"
        signature_path=pathlib.Path(tmp)/"manifest.minisig"
        manifest_path.write_bytes(manifest_bytes); signature_path.write_bytes(signature_bytes)
        result=subprocess.run(["minisign","-Vm",str(manifest_path),"-x",str(signature_path),"-P",cfg["minisign_public_key"]],stdout=subprocess.DEVNULL,stderr=subprocess.PIPE,text=True)
        if result.returncode: fail("update manifest signature verification failed")
    try:
        data=json.loads(manifest_bytes.decode("utf-8"))
        return validate_manifest(data,cfg.get("channel","stable"))
    except (UnicodeDecodeError,json.JSONDecodeError,ValueError) as exc: fail("invalid signed update manifest: "+str(exc))

def command_check(_args):
    m=verified_manifest()
    print("VAMPIRE OS SIGNED UPDATE")
    print("Available version: "+m["version"])
    print("Channel: "+m["channel"])
    print("Architecture: "+m["architecture"])
    print("Artifact size: "+str(m["artifact"]["size"])+" bytes")
    print("Signature and manifest format verified.")
    print("This command does not install or apply the update.")

def command_download(_args):
    m=verified_manifest(); a=m["artifact"]; CACHE.mkdir(parents=True,exist_ok=True)
    final=CACHE/("vampire-os-"+m["version"]+"-x86_64.img")
    fd,tmp=tempfile.mkstemp(prefix=".download-",dir=CACHE); digest=hashlib.sha256(); total=0
    try:
        with os.fdopen(fd,"wb") as out:
            req=urllib.request.Request(a["url"],headers={"User-Agent":"vupdate/0.1"})
            with urllib.request.urlopen(req,timeout=60) as response:
                if response.status!=200: fail("artifact server returned HTTP "+str(response.status))
                while True:
                    block=response.read(1024*1024)
                    if not block: break
                    total+=len(block)
                    if total>a["size"] or total>MAX_ARTIFACT: fail("artifact exceeded declared size")
                    digest.update(block); out.write(block)
            out.flush(); os.fsync(out.fileno())
        if total!=a["size"]: fail("artifact size does not match signed manifest")
        if digest.hexdigest().lower()!=a["sha256"].lower(): fail("artifact SHA-256 mismatch")
        os.chmod(tmp,0o600); os.replace(tmp,final)
    except Exception:
        try: os.unlink(tmp)
        except FileNotFoundError: pass
        raise
    print("Verified update downloaded to: "+str(final))
    print("No system files were changed. Applying updates is not implemented.")

def command_status(_args):
    print("Vampire OS update cache: "+str(CACHE))
    items=sorted(p.name for p in CACHE.glob("vampire-os-*") if p.is_file()) if CACHE.is_dir() else []
    print("\n".join(items) if items else "No downloaded updates.")

def main():
    parser=argparse.ArgumentParser(prog="vupdate",description="Verify and stage signed Vampire OS updates")
    sub=parser.add_subparsers(dest="command",required=True)
    for name,help_text,func in [("check","verify signed release metadata",command_check),("download","download and hash-verify a release image",command_download),("status","list staged update images",command_status)]:
        p=sub.add_parser(name,help=help_text); p.set_defaults(func=func)
    args=parser.parse_args(); args.func(args)

if __name__=="__main__": main()
