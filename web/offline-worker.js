const build = /* BUILD_ID */;
const paths = /* BUILD_ASSETS */;
const scope = self.registration.scope;
const prefix = "astro-worker:" + scope;
const cacheName = prefix + build;
const urls = new Set(paths.map(path => new URL(path, scope).href));
const shell = new URL("index.html", scope).href;

self.addEventListener("install", event => {
  event.waitUntil((async () => {
    const cache = await caches.open(cacheName);
    await cache.addAll(Array.from(urls, url => new Request(url, { cache: "reload" })));
  })());
});

self.addEventListener("activate", event => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.filter(key => key.startsWith(prefix) && key !== cacheName)
      .map(key => caches.delete(key)));
    await self.clients.claim();
  })());
});

self.addEventListener("fetch", event => {
  const request = event.request;
  if (request.method !== "GET") return;
  const url = request.mode === "navigate" && request.url.startsWith(scope)
    ? shell
    : request.url;
  if (!urls.has(url)) return;

  event.respondWith((async () => {
    const cache = await caches.open(cacheName);
    return (await cache.match(url)) || fetch(request);
  })());
});
