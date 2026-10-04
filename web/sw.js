// Service worker de Sensor UV: permite instalar la app y abrirla sin internet.
// Estrategia "primero la red": siempre intenta la version mas nueva y,
// si no hay conexion, usa la copia guardada.

const CACHE = 'sensor-uv-v1';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (evento) => {
  evento.waitUntil(
    caches.keys()
      .then((nombres) => Promise.all(
        nombres.filter((n) => n !== CACHE).map((n) => caches.delete(n))))
      .then(() => self.clients.claim()),
  );
});

self.addEventListener('fetch', (evento) => {
  const peticion = evento.request;
  if (peticion.method !== 'GET' || !peticion.url.startsWith(self.location.origin)) return;

  evento.respondWith(
    fetch(peticion)
      .then((respuesta) => {
        if (respuesta.ok) {
          const copia = respuesta.clone();
          caches.open(CACHE).then((cache) => cache.put(peticion, copia));
        }
        return respuesta;
      })
      .catch(() => caches.match(peticion).then((guardada) =>
        guardada || (peticion.mode === 'navigate' ? caches.match('./') : undefined))),
  );
});
