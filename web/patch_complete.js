const fs = require('fs');

const file = 'src/app/api/student/courses/complete-lesson/route.ts';
let content = fs.readFileSync(file, 'utf8');

// Replace the query block
const regex1 = /const courseData = await db\.query\.courses\.findFirst\(\{\s*where: eq\(courses\.id, courseId\),\s*with: \{ lessons: true \}\s*\}\);/;
content = content.replace(regex1, `const courseData = await db.select().from(courses).where(eq(courses.id, courseId)).limit(1);`);

// Replace if (!courseData)
content = content.replace(/if \(\!courseData\) \{/, `if (!courseData || courseData.length === 0) {`);

// Replace lesson find
const regex2 = /const lesson = courseData\.lessons\.find\(\(l: any\) => l\.id === lessonId\);/;
content = content.replace(regex2, `const { lessons } = require('@/db/schema');\n    const lessonsData = await db.select().from(lessons).where(eq(lessons.courseId, courseId));\n    const lesson = lessonsData.find((l: any) => l.id === lessonId);`);

// Replace allLessonIds
const regex3 = /const allLessonIds = courseData\.lessons\.filter\(\(l: any\) => l\.isPublished\)\.map\(\(l: any\) => l\.id\);/;
content = content.replace(regex3, `const allLessonIds = lessonsData.filter((l: any) => l.isPublished).map((l: any) => l.id);`);

fs.writeFileSync(file, content);
console.log("Patched complete-lesson");
