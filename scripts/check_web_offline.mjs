import assert from 'node:assert/strict';
import {spawn, execFileSync} from 'node:child_process';
import fs from 'node:fs/promises';
import http from 'node:http';
import os from 'node:os';
import path from 'node:path';

// Run after scripts/build_web.sh --base-href /astro/.
const chromeExecutable = process.env.CHROME_EXECUTABLE
  ?? (process.platform === 'darwin'
    ? '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
    : 'google-chrome');

const sleep = ms => new Promise(resolve => setTimeout(resolve, ms));
async function until(check, label = "browser condition", timeout = 20000) {
  const deadline = Date.now() + timeout;
  while (Date.now() < deadline) {
    const result = await check();
    if (result) return result;
    await sleep(125);
  }
  throw new Error(`Timed out waiting for ${label}`);
}
const work = await fs.mkdtemp(path.join(os.tmpdir(), 'astro-pwa-'));
const a = path.join(work, 'a');
const b = path.join(work, 'b');
await fs.cp('build/web', a, {recursive:true});
await fs.cp(a, b, {recursive:true});
for (const [folder, label] of [[a,'a'], [b,'b']]) {
  const filename = path.join(folder, 'index.html');
  await fs.writeFile(filename, (await fs.readFile(filename, 'utf8')).replace('<head>', '<head><meta name="astro-build" content="'+label+'">'));
  execFileSync('python3', ['scripts/package_web.py', folder]);
}
let build = a;
let offline = false;
const mime = {'.html':'text/html','.js':'text/javascript','.wasm':'application/wasm','.json':'application/json','.png':'image/png'};
const server = http.createServer(async (req,res) => {
  if (offline) { res.writeHead(503).end(); return; }
  const pathname = new URL(req.url, 'http://localhost').pathname;
  if (!pathname.startsWith('/astro/')) { res.writeHead(404).end(); return; }
  const relative = decodeURIComponent(pathname.slice('/astro/'.length) || 'index.html');
  const filename = path.resolve(build, relative);
  if (!filename.startsWith(build + path.sep)) { res.writeHead(404).end(); return; }
  try {
    const bytes = await fs.readFile(filename);
    res.writeHead(200, {'Content-Type':mime[path.extname(relative)] || 'application/octet-stream','Cache-Control':'no-store'}).end(bytes);
  } catch { res.writeHead(404).end(); }
});
await new Promise(resolve => server.listen(0,'127.0.0.1', resolve));
const url = 'http://127.0.0.1:'+server.address().port+'/astro/';
const chrome = spawn(chromeExecutable,
  ['--headless','--remote-debugging-port=0','--disable-background-networking','--disable-dev-shm-usage','--disable-extensions','--no-first-run','--user-data-dir='+work+'/chrome','about:blank'],
  {stdio:['ignore', 'ignore', 'pipe']});
let ws;
let launchError;
let chromeOutput = '';
chrome.stderr.setEncoding('utf8');
chrome.stderr.on('data', chunk => { chromeOutput = (chromeOutput + chunk).slice(-3000); });
chrome.on('error', error => { launchError = error; });
chrome.on('exit', (status, signal) => {
  launchError ??= new Error(`Chrome exited (${status ?? signal}): ${chromeOutput}`);
});
try {
  const port = await until(async () => {
    if (launchError) throw launchError;
    try { return (await fs.readFile(work+'/chrome/DevToolsActivePort','utf8')).split('\n')[0]; } catch { return null; }
  }, 'Chrome DevTools startup', 40000);
  const tabs = await (await fetch(`http://127.0.0.1:${port}/json/list`)).json();
  ws = new WebSocket(tabs.find(tab => tab.type === 'page').webSocketDebuggerUrl);
  await new Promise(resolve => ws.addEventListener('open', resolve, {once:true}));
  const pending = new Map();
  let id = 0;
  ws.addEventListener('message', ({data}) => {
    const message = JSON.parse(data);
    pending.get(message.id)?.(message);
    pending.delete(message.id);
  });
  const cdp = (method, params) => new Promise((resolve,reject) => {
    const messageId = ++id;
    pending.set(messageId, response => response.error ? reject(Error(response.error.message)) : resolve(response.result));
    ws.send(JSON.stringify({id:messageId,method,params}));
  });
  const evaluate = async expression => {
    const result = await cdp('Runtime.evaluate', {expression, awaitPromise:true, returnByValue:true});
    if (result.exceptionDetails) throw Error(result.exceptionDetails.exception?.description || result.exceptionDetails.text);
    return result.result.value;
  };
  const open = async (label) => {
    const start = performance.now();
    await cdp('Page.navigate', {url});
    await until(() => evaluate(`document.querySelector('meta[name=astro-build]')?.content === '${label}' && !!document.querySelector('flutter-view') && !!navigator.serviceWorker.controller`).catch(() => false));
    return Math.round(performance.now()-start);
  };
  console.log('Initial controlled app render:', await open('a'), 'ms');
  const errors = await cdp('Page.getInstallabilityErrors');
  assert.deepEqual(errors.installabilityErrors, []);
  console.log('Chromium reported no installability errors');
  offline = true;
  await cdp('Page.navigate', {url:'about:blank'});
  console.log('Cold render with server offline:', await open('a'), 'ms');
  offline = false;
  for (const [next, label] of [[b,'b'],[a,'a']]) {
    build = next;
    await evaluate('navigator.serviceWorker.getRegistration().then(r => r.update()).then(() => true)');
    await until(() => evaluate('navigator.serviceWorker.getRegistration().then(r => !!r.waiting)'));
    await cdp('Page.navigate', {url:'about:blank'});
    await until(() => evaluate('location.href === "about:blank"'));
    await sleep(300);
    await open(label);
    console.log('Activated build '+label+' and rendered its app shell');
  }
} finally {
  ws?.close();
  chrome.kill();
  server.close();
  await sleep(500);
  await fs.rm(work,{recursive:true,force:true});
}
