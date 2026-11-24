import assert from 'node:assert/strict';
import { createHash } from 'node:crypto';
import { readFile } from 'node:fs/promises';
import path from 'node:path';

const packageRoot = process.argv[2];
if (!packageRoot) throw new Error('Pass the path to the pinned sweph package.');
const provenance = JSON.parse(await readFile(new URL('./provenance.json', import.meta.url)));
const files = new Map();
for (const [name, checksum] of Object.entries(provenance.files)) {
  const bytes = await readFile(path.join(packageRoot, name));
  assert.equal(createHash('sha256').update(bytes).digest('hex'), checksum, name);
  files.set(name, bytes);
}
const wasm = files.get('assets/sweph.wasm');
const { instance: { exports: runtime } } = await WebAssembly.instantiate(wasm, {});
const { memory, malloc, free, swe_calc_ut, swe_set_ephe_path, swe_close, write_file } = runtime;
function withBytes(bytes, fn) {
  const address = malloc(bytes.length);
  new Uint8Array(memory.buffer, address, bytes.length).set(bytes);
  try { return fn(address); } finally { free(address); }
}
function setDirectory(directory) {
  withBytes(Buffer.from(directory + '\0'), swe_set_ephe_path);
}
const values = malloc(48);
const error = malloc(256);
function calculate(id, jd) {
  const flags = swe_calc_ut(jd, id, 258, values, error);
  return { flags, longitude: new DataView(memory.buffer).getFloat64(values, true) };
}

const jd = 2460689.435416667;
setDirectory('empty');
const missing = calculate(1, jd);
assert(missing.flags < 0 || (missing.flags & 7) !== 2, 'Missing data must fail strict flags.');
swe_close();
for (const [name, contents] of files) {
  if (!name.endsWith('.se1')) continue;
  const pointer = malloc(contents.length);
  new Uint8Array(memory.buffer, pointer, contents.length).set(contents);
  const result = withBytes(Buffer.from('ephe/' + path.basename(name) + '\0'), address =>
    write_file(address, pointer, contents.length, 0));
  assert.equal(result, 1, name);
  // The module's in-memory filesystem owns the contents after write_file.
}
setDirectory('ephe');
const planets = { sun: 0, moon: 1, pluto: 9, mean_node: 10, true_node: 11, chiron: 15 };
const samples = [];
for (const [body, id] of Object.entries(planets)) {
  for (const jd of [2451545, 2460689.435416667, 2470171.5]) {
    const result = calculate(id, jd);
    assert(result.flags >= 0 && (result.flags & 7) === 2, body);
    samples.push({ body, jd_ut: jd, ...result });
  }
}
const start = performance.now();
for (let i = 0; i < 2048; i++) calculate(1, jd + i / 24);
const speed = Math.round(2048 / (performance.now() - start) * 1000);
free(values);
free(error);
process.stdout.write(JSON.stringify({
  missing_moon_flags: missing.flags,
  wasm_bytes: wasm.length,
  moon_calls_per_second: speed,
  samples,
}, null, 2) + '\n');
