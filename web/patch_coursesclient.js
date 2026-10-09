const fs = require('fs');

const file = 'src/app/student/cours/CoursesClient.tsx';
let content = fs.readFileSync(file, 'utf8');

const regex = /const completeActiveLesson = async \(\) => \{[\s\S]*?setShowCelebration\(true\);\s*setTimeout\(\(\) => \{\s*setShowCelebration\(false\);\s*\}, 2500\);\s*\}/;

const replacement = `const completeActiveLesson = async () => {
    if (activeLesson !== null) {
      const course = courses.find(c => c.id === selectedCourseId);
      const lesson = course?.levels.find((l: any) => l.id === activeLesson);
      
      if (!lesson) return;
      const alreadyDone = lesson.status === "done";

      if (!alreadyDone) {
        try {
          const res = await fetch('/api/student/courses/complete-lesson', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ courseId: selectedCourseId, lessonId: activeLesson })
          });
          
          if (!res.ok) {
            console.error("Failed to complete lesson");
            return; // Arrêter si l'API échoue
          }
          
          const data = await res.json();
          if (data.newXp) setCrystals(data.newXp);
          if (data.newLevel) setStreak(data.newLevel);
          
        } catch (err) {
          console.error(err);
          return; // Arrêter si réseau coupé
        }
      }

      // Si le serveur a validé ou si c'était déjà fait, on met à jour l'UI
      playSound('celebration');
      setCourses(prevCourses => {
        const newCourses = [...prevCourses];
        const courseIndex = newCourses.findIndex(c => c.id === selectedCourseId);
        
        if (courseIndex !== -1) {
          const levels = [...newCourses[courseIndex].levels];
          const lessonIndex = levels.findIndex(l => l.id === activeLesson);
          
          if (lessonIndex !== -1) {
            levels[lessonIndex].status = "done";
            levels[lessonIndex].stars = 3;
            
            if (lessonIndex + 1 < levels.length && levels[lessonIndex + 1].status === "locked") {
              levels[lessonIndex + 1].status = "current";
            }
            
            const doneCount = levels.filter(l => l.status === "done").length;
            newCourses[courseIndex].progress = Math.round((doneCount / levels.length) * 100);
            newCourses[courseIndex].levels = levels;
          }
        }
        return newCourses;
      });

      setShowCelebration(true);
      setTimeout(() => {
        setShowCelebration(false);
      }, 2500);
    }
  };`;

content = content.replace(regex, replacement);
fs.writeFileSync(file, content);
console.log("Patched CoursesClient.tsx");
