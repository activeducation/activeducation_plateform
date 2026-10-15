const fs = require('fs');

let content = fs.readFileSync('src/db/schema.ts', 'utf8');

// Replace the orientation tables to have explorer_ prefix
content = content.replace(/export const domains = pgTable\('domains'/g, "export const explorerDomains = pgTable('explorer_domains'");
content = content.replace(/export const schools = pgTable\('schools'/g, "export const explorerSchools = pgTable('explorer_schools'");
content = content.replace(/export const programs = pgTable\('programs'/g, "export const explorerPrograms = pgTable('explorer_programs'");
content = content.replace(/export const careers = pgTable\('careers'/g, "export const explorerCareers = pgTable('explorer_careers'");
content = content.replace(/export const careerPrograms = pgTable\('career_programs'/g, "export const explorerCareerPrograms = pgTable('explorer_career_programs'");

// Fix foreign keys
content = content.replace(/references\(\(\) => schools\.id/g, "references(() => explorerSchools.id");
content = content.replace(/references\(\(\) => domains\.id/g, "references(() => explorerDomains.id");
content = content.replace(/references\(\(\) => careers\.id/g, "references(() => explorerCareers.id");
content = content.replace(/references\(\(\) => programs\.id/g, "references(() => explorerPrograms.id");

fs.writeFileSync('src/db/schema.ts', content);
