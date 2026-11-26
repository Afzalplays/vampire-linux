const CACHE="vampire-mobile-v2";
const CORE=["./","./index.html","./styles.css","./app.js","./manifest.webmanifest","./icon.svg"];
const ASSETS=new Set(CORE.map(path=>new URL(path,self.location.href).pathname));
self.addEventListener("install",event=>event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(CORE)).then(()=>self.skipWaiting())));
self.addEventListener("activate",event=>event.waitUntil(caches.keys().then(keys=>Promise.all(keys.filter(key=>key!==CACHE).map(key=>caches.delete(key)))).then(()=>self.clients.claim())));
self.addEventListener("fetch",event=>{
  const request=event.request;
  if(request.method!=="GET")return;
  const url=new URL(request.url);
  if(url.origin!==self.location.origin||url.search||!ASSETS.has(url.pathname))return;
  event.respondWith(caches.match(request).then(cached=>cached||fetch(request).then(response=>{
    if(response.ok&&response.type==="basic")caches.open(CACHE).then(cache=>cache.put(request,response.clone()));
    return response;
  }).catch(()=>caches.match("./index.html"))));
});
