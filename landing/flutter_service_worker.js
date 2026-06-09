// Service worker « auto-destructeur ».
//
// Avant cette mise en ligne, la racine activeducationhub.com servait l'app
// Flutter, qui enregistrait un service worker au scope "/". Maintenant la
// racine sert la landing statique et l'app vit sous /app/.
//
// Les navigateurs des visiteurs déjà venus possèdent encore l'ancien SW au
// scope "/", qui resservirait l'app en cache au lieu de la landing. Quand le
// navigateur revérifie /flutter_service_worker.js, il récupère CE fichier
// (différent de l'ancien) : on en profite pour vider les caches, se
// désenregistrer, puis recharger les onglets vers la vraie landing.
self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    try {
      const keys = await caches.keys();
      await Promise.all(keys.map((k) => caches.delete(k)));
    } catch (e) { /* noop */ }
    try { await self.registration.unregister(); } catch (e) { /* noop */ }
    const clients = await self.clients.matchAll({ type: 'window' });
    for (const client of clients) {
      try { client.navigate(client.url); } catch (e) { /* noop */ }
    }
  })());
});

// Ne rien intercepter : on laisse le réseau servir la landing normalement.
self.addEventListener('fetch', () => {});
