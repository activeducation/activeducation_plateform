const fs = require('fs');

let content = fs.readFileSync('src/app/student/explorer/ExplorerClient.tsx', 'utf8');

// Update signature
content = content.replace(
  /export default function ExplorerPage\(\) \{/,
  `export default function ExplorerClient({ 
  initialCareers, 
  initialPrograms, 
  initialSchools, 
  initialDomains 
}: { 
  initialCareers: any[], 
  initialPrograms: any[], 
  initialSchools: any[], 
  initialDomains: any[] 
}) {`
);

// We need to replace the massive hardcoded arrays inside the activeTab conditions.
// Let's just use string replacement on the entire `content`.
// This might be tricky because of the JSX structure. Let's write a script that replaces the entire `CONTENT GRID` div.

const newContentGrid = `
      {/* CONTENT GRID */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        
        {activeTab === "metiers" && (
          <>
            {initialCareers.length > 0 ? initialCareers.map((item) => (
              <a href={\`/student/explorer/metier/\${item.slug}\`} key={item.id} className="group block outline-none">
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-40 relative overflow-hidden bg-surface-alt">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1550751827-4bd374c3f58b?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.title} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                    <div className="absolute top-3 left-3 bg-white/90 backdrop-blur-sm px-2 py-1 rounded text-[10px] font-bold text-primary uppercase shadow-sm">
                      Métier
                    </div>
                  </div>
                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-bold text-lg text-text-primary mb-2 group-hover:text-primary transition-colors">{item.title}</h3>
                    <p className="text-sm text-text-secondary line-clamp-3 mb-4">{item.description}</p>
                    <div className="mt-auto flex items-center justify-between text-sm font-bold text-primary group-hover:underline">
                      Découvrir <ArrowRight className="w-4 h-4" />
                    </div>
                  </div>
                </Card>
              </a>
            )) : <p className="text-text-secondary col-span-full">Aucun métier trouvé.</p>}
          </>
        )}

        {activeTab === "formations" && (
          <>
            {initialPrograms.length > 0 ? initialPrograms.map((item) => (
              <a href={\`/student/explorer/formation/\${item.slug}\`} key={item.id} className="group block outline-none">
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-40 relative overflow-hidden bg-surface-alt">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1541339907198-e08756dedf3f?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.title} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                    <div className="absolute top-3 left-3 bg-white/90 backdrop-blur-sm px-2 py-1 rounded text-[10px] font-bold text-primary uppercase shadow-sm">
                      Formation
                    </div>
                  </div>
                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-bold text-lg text-text-primary mb-1 group-hover:text-primary transition-colors">{item.title}</h3>
                    <p className="text-xs font-bold text-text-tertiary mb-3">{item.level || 'Non précisé'}</p>
                    <p className="text-sm text-text-secondary line-clamp-3 mb-4">{item.description}</p>
                    <div className="mt-auto flex items-center justify-between text-sm font-bold text-primary group-hover:underline">
                      Voir programme <ArrowRight className="w-4 h-4" />
                    </div>
                  </div>
                </Card>
              </a>
            )) : <p className="text-text-secondary col-span-full">Aucune formation trouvée.</p>}
          </>
        )}

        {activeTab === "etablissements" && (
          <>
            {initialSchools.length > 0 ? initialSchools.map((item) => (
              <a href={\`/student/explorer/etablissement/\${item.slug}\`} key={item.id} className="group block outline-none">
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-40 relative overflow-hidden bg-surface-alt">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1562774053-701939374585?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.name} 
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-500" 
                    />
                    <div className="absolute top-3 left-3 bg-white/90 backdrop-blur-sm px-2 py-1 rounded text-[10px] font-bold text-primary uppercase shadow-sm flex items-center gap-1">
                      <Building2 className="w-3 h-3" /> École
                    </div>
                  </div>
                  <div className="p-5 flex flex-col flex-1">
                    <h3 className="font-bold text-lg text-text-primary mb-1 group-hover:text-primary transition-colors">{item.name}</h3>
                    <p className="text-xs text-text-tertiary mb-3 flex items-center gap-1"><MapPin className="w-3 h-3" /> {item.city || "Localisation inconnue"}</p>
                    <p className="text-sm text-text-secondary line-clamp-3 mb-4">{item.description}</p>
                    <div className="mt-auto flex items-center justify-between text-sm font-bold text-primary group-hover:underline">
                      Visiter le campus <ArrowRight className="w-4 h-4" />
                    </div>
                  </div>
                </Card>
              </a>
            )) : <p className="text-text-secondary col-span-full">Aucun établissement trouvé.</p>}
          </>
        )}

        {activeTab === "domaines" && (
          <>
            {initialDomains.length > 0 ? initialDomains.map((item) => (
              <a href={\`/student/explorer/domaine/\${item.slug}\`} key={item.id} className="group block outline-none">
                <Card variant="interactive" className="h-full overflow-hidden flex flex-col p-0">
                  <div className="h-40 relative overflow-hidden bg-black">
                    <img 
                      src={item.bannerImage || "https://images.unsplash.com/photo-1518770660439-4636190af475?auto=format&fit=crop&w=600&q=80"} 
                      alt={item.title} 
                      className="w-full h-full object-cover opacity-60 group-hover:scale-105 group-hover:opacity-80 transition-all duration-500" 
                    />
                    <div className="absolute bottom-4 left-4 right-4">
                      <span className="text-[10px] font-bold text-white/90 uppercase mb-1 block drop-shadow-md">Secteur</span>
                      <h3 className="font-bold text-xl text-white drop-shadow-md">{item.title}</h3>
                    </div>
                  </div>
                </Card>
              </a>
            )) : <p className="text-text-secondary col-span-full">Aucun domaine trouvé.</p>}
          </>
        )}
      </div>
    </div>
  );
}
`;

content = content.replace(/\{\/\* CONTENT GRID \*\/\}.*/s, newContentGrid);

fs.writeFileSync('src/app/student/explorer/ExplorerClient.tsx', content);
