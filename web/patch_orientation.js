const fs = require('fs');

const file = 'src/app/api/orientation/generate/route.ts';
let content = fs.readFileSync(file, 'utf8');

const regex = /if \(user && user\.id\) \{[\s\S]*?return NextResponse\.json\(sanitizedResult\);/m;

const replacement = `if (user && user.id) {
      try {
        const existing = await db.select().from(orientationResults).where(eq(orientationResults.userId, user.id)).limit(1);
        const isFirstTime = existing.length === 0;

        await db.insert(orientationResults).values({
          userId: user.id,
          inputs: answers,
          results: sanitizedResult,
        });

        if (isFirstTime) {
          const userProfile = await db.select().from(users).where(eq(users.id, user.id)).limit(1);
          if (userProfile.length > 0) {
            const currentXp = userProfile[0].xpPoints || 0;
            const newXp = currentXp + 200;
            const currentLevel = userProfile[0].level || 1;
            const newLevel = Math.max(currentLevel, Math.floor(newXp / 1000) + 1);
            
            await db.update(users)
              .set({ xpPoints: newXp, level: newLevel })
              .where(eq(users.id, user.id));
          }
        }
      } catch (dbError) {
        console.warn('Database save warning in /api/orientation/generate (non-blocking):', dbError);
      }
    }

    return NextResponse.json(sanitizedResult);`;

content = content.replace(regex, replacement);
fs.writeFileSync(file, content);
console.log("Patched route.ts");
