#!/usr/bin/env node
// Regenerates Packages/PickerCore/Sources/PickerCore/Resources/emoji.json from emojibase-data.
// Usage: node Scripts/generate-emoji-data.mjs [emojibase-data version]
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const version = process.argv[2] ?? "latest";
const base = `https://cdn.jsdelivr.net/npm/emojibase-data@${version}`;
const shortcodePresets = ["emojibase", "github", "iamcal"];
const componentGroup = 2;

const fetchJSON = async (path) => {
  const res = await fetch(`${base}/${path}`);
  if (!res.ok) throw new Error(`${res.status} fetching ${path}`);
  return res.json();
};

const [pkg, data, ...presets] = await Promise.all([
  fetchJSON("package.json"),
  fetchJSON("en/data.json"),
  ...shortcodePresets.map((p) => fetchJSON(`en/shortcodes/${p}.json`)),
]);

const shortcodesFor = (hexcode) => {
  const out = [];
  for (const preset of presets) {
    const value = preset[hexcode];
    for (const code of Array.isArray(value) ? value : value ? [value] : []) {
      if (!out.includes(code)) out.push(code);
    }
  }
  return out;
};

const emoji = data
  .filter((e) => e.group !== undefined && e.group !== componentGroup)
  .sort((a, b) => a.order - b.order)
  .map((e) => {
    const entry = {
      h: e.hexcode,
      e: e.emoji,
      n: e.label,
      g: e.group,
      o: e.order,
      v: e.version,
      k: e.tags ?? [],
      s: shortcodesFor(e.hexcode),
    };
    if (e.emoticon) entry.m = Array.isArray(e.emoticon) ? e.emoticon : [e.emoticon];
    const tones = (e.skins ?? []).filter((s) => typeof s.tone === "number");
    if (tones.length === 5) entry.t = tones.sort((a, b) => a.tone - b.tone).map((s) => s.emoji);
    return entry;
  });

const outPath = join(
  dirname(fileURLToPath(import.meta.url)),
  "..",
  "Packages/PickerCore/Sources/PickerCore/Resources/emoji.json",
);
writeFileSync(outPath, JSON.stringify({ source: `emojibase-data@${pkg.version}`, emoji }));
console.log(`Wrote ${emoji.length} emoji from emojibase-data@${pkg.version} to ${outPath}`);
