const CACHE="vampire-mobile-v4";
const CORE=["./","./index.html","./experience.html","./styles.css","./app.js","./manifest.webmanifest","./icon.svg"];
const ASSETS=new Set(CORE.map(path=>new URL(path,self.location.href).pathname));

async function cacheResponse(request,response){
  if(response.ok&&response.type==="basic"){
    const cache=await caches.open(CACHE);
    await cache.put(request,response.clone());
  }
  return response;
}

self.addEventListener("install",event=>{
  event.waitUntil(caches.open(CACHE).then(cache=>cache.addAll(CORE)).then(()=>self.skipWaiting()));
});

self.addEventListener("activate",event=>{
  event.waitUntil(
    caches.keys()
      .then(keys=>Promise.all(keys.filter(key=>key.startsWith("vampire-mobile-")&&key!==CACHE).map(key=>caches.delete(key))))
      .then(()=>self.clients.claim())
  );
});

self.addEventListener("fetch",event=>{
  const request=event.request;
  if(request.method!=="GET")return;
  const url=new URL(request.url);
  if(url.origin!==self.location.origin||url.search||!ASSETS.has(url.pathname))return;

  if(request.mode==="navigate"){
    event.respondWith(
      fetch(request)
        .then(response=>cacheResponse(request,response))
        .catch(()=>caches.match(request).then(cached=>cached||caches.match("./index.html")))
    );
    return;
  }

  event.respondWith(
    caches.match(request).then(cached=>cached||fetch(request).then(response=>cacheResponse(request,response)))
  );
});
