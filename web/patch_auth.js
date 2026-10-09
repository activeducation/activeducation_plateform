const fs = require('fs');
const path = require('path');

function walk(dir) {
    let results = [];
    const list = fs.readdirSync(dir);
    list.forEach(function(file) {
        file = path.join(dir, file);
        const stat = fs.statSync(file);
        if (stat && stat.isDirectory()) { 
            results = results.concat(walk(file));
        } else { 
            if (file.endsWith('.ts')) results.push(file);
        }
    });
    return results;
}

const files = walk('src/app/api/admin');
console.log(`Found ${files.length} admin routes`);

for (const file of files) {
  let content = fs.readFileSync(file, 'utf8');
  
  // We remove the old requireAdmin imports manually because we tried to inject them earlier
  content = content.replace(/import \{ requireAdmin \} from '@\/utils\/auth';\r?\n/g, "");
  // We remove the previous botched attempts
  content = content.replace(/\s*const \{ errorResponse \} = await requireAdmin\(\);\r?\n\s*if \(errorResponse\) return errorResponse;/g, "");
  
  let modified = false;
  const methodRegex = /export\s+async\s+function\s+(GET|POST|PUT|DELETE)\s*\([^)]*\)\s*\{/g;
  
  content = content.replace(methodRegex, (match) => {
    modified = true;
    return match + '\n  const { errorResponse } = await requireAdmin();\n  if (errorResponse) return errorResponse;';
  });
  
  if (modified) {
    content = "import { requireAdmin } from '@/utils/auth';\n" + content;
    fs.writeFileSync(file, content);
    console.log(`Patched ${file}`);
  }
}
