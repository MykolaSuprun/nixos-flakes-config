{
  perSystem = {pkgs, ...}: let
    # opencode-lmstudio-sync — regenerate the LM Studio `models` map in
    # nixconf-private/opencode/opencode.jsonc from the live LM Studio API.
    #
    # Why this exists: opencode 2 custom providers need a STATIC `models`
    # map whose ids must match LM Studio's serving ids exactly (no runtime
    # autodiscovery upstream), so the map silently drifts whenever models
    # are installed/removed/quants change in LM Studio. This tool makes the
    # model list a one-command sync instead of a hand edit.
    #
    # Modifies ONLY the region between the `// opencode-lmstudio-sync
    # BEGIN` and `// opencode-lmstudio-sync END` markers in the JSONC —
    # everything else (options, MCP blocks, comments) is preserved
    # byte-for-byte, and the file is comment-stripped + JSON re-parsed +
    # atomically replaced only when the result validates.
    opencodeLmstudioSync = pkgs.writers.writePython3Bin "opencode-lmstudio-sync" {
      flakeIgnore = ["E501" "E302" "W503"]; # literal-heavy one-off tool
    } ''
      # opencode-lmstudio-sync — regenerate the LM Studio `models` map in
      # nixconf-private/opencode/opencode.jsonc (the static provider map
      # opencode 2 requires) from the live LM Studio API.
      #
      # Sources (single source of truth = the machine running LM Studio):
      #   GET {base}/v1/models     OpenAI-compat serving ids (what opencode refs)
      #   GET {base}/api/v1/models native: display names, max context, capabilities
      # Auth: OPENCODE_LM_STUDIO_API_KEY (or --api-key), Bearer.
      #
      # Usage: opencode-lmstudio-sync [--config PATH] [--base-url URL]
      #                                [--api-key KEY] [--check]

      import argparse
      import json
      import os
      import re
      import sys
      import urllib.request
      from pathlib import Path

      BEGIN = "// opencode-lmstudio-sync BEGIN"
      END = "// opencode-lmstudio-sync END"
      REGION_RE = re.compile(
          re.escape(BEGIN) + r"[^\n]*\n(?P<inner>.*?)\n\s*" + re.escape(END),
          re.DOTALL,
      )

      def fail(msg):
          print(f"opencode-lmstudio-sync: {msg}", file=sys.stderr)
          raise SystemExit(1)

      def fetch_json(url, api_key):
          req = urllib.request.Request(url)
          if api_key:
              req.add_header("Authorization", f"Bearer {api_key}")
          req.add_header("Accept", "application/json")
          try:
              with urllib.request.urlopen(req, timeout=15) as resp:
                  return json.loads(resp.read().decode())
          except urllib.error.HTTPError as e:
              if e.code == 401:
                  fail(
                      f"401 from {url} — LM Studio server auth is on; export "
                      "OPENCODE_LM_STUDIO_API_KEY (or pass --api-key)."
                  )
              fail(f"HTTP {e.code} from {url}")
          except urllib.error.URLError as e:
              fail(f"cannot reach {url} ({e.reason}) — is the LM Studio server running?")

      def native_spellings(m):
          # Plausible /v1 id spellings for a native model entry: the native key
          # plus its quant variants, each optionally with/without the publisher
          # prefix (LM Studio strips the prefix in /v1 ids for some repos but
          # keeps it for publisher-mirrored repos).
          key = (m.get("key") or "").strip()
          pub = m.get("publisher")
          out = set()
          if not key:
              return out
          out.add(key)
          if pub and key.startswith(pub + "/"):
              out.add(key[len(pub) + 1:])
          for v in m.get("variants") or []:
              if not (isinstance(v, str) and v):
                  continue
              out.add(v)
              base, _, quant = v.partition("@")
              if pub and base.startswith(pub + "/"):
                  out.add(base[len(pub) + 1:] + ("@" + quant if quant else ""))
          return {s for s in out if s}

      def entry_for(mid, native_model):
          dl = native_model.get("display_name")
          name = dl.strip() if isinstance(dl, str) and dl.strip() else mid
          ctx = native_model.get("max_context_length")
          if not isinstance(ctx, int) or ctx <= 0:
              ctx = 8192 if "embedding" in mid else 32768
          if "embedding" in mid:
              return {
                  "name": name,
                  "tool_call": False,
                  "limit": {"context": ctx, "output": 1},
              }
          cap = native_model.get("capabilities") or {}
          entry = {
              "name": name,
              "tool_call": bool(cap.get("trained_for_tool_use", True)),
          }
          entry["limit"] = {"context": ctx, "output": 65536}
          if cap.get("reasoning"):
              entry["reasoning"] = True
          return entry

      def render_region(entries):
          d = json.dumps(entries, indent=2, ensure_ascii=False)
          if d == "{}":
              return "      \"models\": {}"
          inner = d.splitlines()[1:-1]  # drop the outer braces of dumps
          inner = "\n".join(("        " + ln if ln else ln) for ln in inner)
          return f'      "models": {{\n{inner}\n      }}'

      def strip_jsonc(text):
          # Comments (// and /* */) outside strings → spaces. The file also has
          # {env:...} strings — handled by normal string state, not substitution.
          out = []
          i, n, in_str = 0, len(text), False
          while i < n:
              c = text[i]
              if in_str:
                  out.append(c)
                  if c == "\\" and i + 1 < n:
                      out.append(text[i + 1])
                      i += 2
                      continue
                  if c == '"':
                      in_str = False
                  i += 1
                  continue
              if c == '"':
                  in_str = True
                  out.append(c)
                  i += 1
                  continue
              if text.startswith("//", i):
                  j = text.find("\n", i)
                  if j == -1:
                      break
                  out.append("  ")
                  i = j
                  continue
              if text.startswith("/*", i):
                  j = text.find("*/", i + 2)
                  if j == -1:
                      fail("unterminated block comment in config")
                  out.append(" ")
                  i = j + 2
                  continue
              out.append(c)
              i += 1
          return "".join(out)

      def main():
          p = argparse.ArgumentParser(description="sync the lmstudio models map in opencode.jsonc")
          p.add_argument("--config", type=Path, default=None)
          p.add_argument("--base-url", default="http://localhost:1234")
          p.add_argument("--api-key", default=None)
          p.add_argument("--check", action="store_true", help="report the diff, write nothing")
          args = p.parse_args()

          api_key = args.api_key or os.environ.get("OPENCODE_LM_STUDIO_API_KEY")
          conf_path = None
          if args.config:
              conf_path = args.config
          else:
              conf_dir = os.environ.get("NIXOS_CONF_DIR", str(Path.home() / "workspaces/src/nixconf"))
              conf_path = Path(conf_dir).resolve().parent / "nixconf-private/opencode/opencode.jsonc"
          conf_path = conf_path.resolve()
          if not conf_path.is_file():
              fail(f"config not found: {conf_path}")
          text = conf_path.read_text(encoding="utf-8")

          region = REGION_RE.search(text)
          if not region:
              fail(f"no {BEGIN!r} markers in {conf_path} — seed them once by hand")
          try:
              # inner is a `"models": {…}` member, not a JSON document
              parsed = json.loads("{" + region.group("inner").strip() + "}")
              old_entries = parsed.get("models") if isinstance(parsed, dict) else None
          except json.JSONDecodeError:
              old_entries = None
          if not isinstance(old_entries, dict):
              print("note: previous models block has comments/hand-edits; diff skipped", file=sys.stderr)
              old_entries = None

          served = [m["id"] for m in fetch_json(f"{args.base_url}/v1/models", api_key).get("data", []) if isinstance(m.get("id"), str)]
          native = fetch_json(f"{args.base_url}/api/v1/models", api_key)
          native_list = native.get("models") if isinstance(native, dict) else []
          if not served or not isinstance(native_list, list):
              fail(f"unexpected shape from {args.base_url} API — refusing to touch the config")

          spelling_map = {}
          for m in native_list:
              if not isinstance(m, dict):
                  continue
              for spelling in native_spellings(m):
                  spelling_map.setdefault(spelling, m)

          entries = {}
          unmatched = []
          for mid in sorted(served):
              m = spelling_map.get(mid)
              if m is not None:
                  entries[mid] = entry_for(mid, m)
              else:
                  unmatched.append(mid)

          if unmatched:
              print("note: served ids with no native metadata (skipped): " + ", ".join(unmatched), file=sys.stderr)

          if old_entries is not None:
              added = sorted(set(entries) - set(old_entries))
              removed = sorted(set(old_entries) - set(entries))
              for label, ids in (("added", added), ("removed", removed)):
                  for _id in ids:
                      print(f"  {label}: {_id}")
              if not added and not removed and old_entries != entries:
                  print("  (ids unchanged; refreshing name/context/tool_call metadata)")

          if args.check:
              print(f"check: {len(entries)} models; config untouched ({conf_path})")
              return
          if old_entries == entries:
              print(f"already in sync: {len(entries)} models ({conf_path})")
              return

          new_region = (
              BEGIN
              + " — generated by `opencode-lmstudio-sync`; do NOT hand-edit the models below\n"
              + render_region(entries)
              + "\n      "
              + END
          )
          new_text = text[:region.start()] + new_region + text[region.end():]

          draft_text = strip_jsonc(new_text)
          # The file deliberately carries JSONC-style trailing commas in the
          # hand-written blocks (see the cline provider); tolerate those for
          # validation only — the region we write itself never has one.
          draft_text = re.sub(r",(\s*[}\]])", r"\1", draft_text)
          draft = json.loads(draft_text)  # full-file validity
          if not (isinstance(draft, dict) and draft.get("provider", {}).get("lmstudio", {}).get("models")):
              fail("post-splice validation failed — refusing to write")

          tmp = conf_path.with_suffix(conf_path.suffix + ".sync.tmp")
          tmp.write_text(new_text, encoding="utf-8")
          os.replace(tmp, conf_path)  # atomic
          print(f"wrote {conf_path}: {len(entries)} models (LM Studio at {args.base_url})")


      main()
    '';
  in {
    packages."opencode-lmstudio-sync" = opencodeLmstudioSync;
  };
}
