import { db } from "@/db";
import { courses, courseProgress, lessons } from "@/db/schema";
import { eq, inArray, desc } from "drizzle-orm";
import { createClient } from "@/utils/supabase/server";
import CoursesClient from "./CoursesClient";
import { redirect } from "next/navigation";

export default async function CoursesPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();

  if (!user) {
    redirect("/auth/login");
  }

  // Fetch all published courses (for the catalog)
  const allCourses = await db.select().from(courses).where(eq(courses.isPublished, true)).orderBy(desc(courses.createdAt));

  // Fetch user's enrolled courses
  const enrollments = await db.select().from(courseProgress).where(eq(courseProgress.userId, user.id));

  const enrolledCourseIds = enrollments.map(e => e.courseId);

  let myCoursesData: any[] = [];

  if (enrolledCourseIds.length > 0) {
    const enrolledCourses = allCourses.filter(c => enrolledCourseIds.includes(c.id));
    
    // Fetch lessons for these courses
    const allLessons = await db.select().from(lessons).where(inArray(lessons.courseId, enrolledCourseIds)).orderBy(lessons.orderIndex);

    myCoursesData = enrolledCourses.map(course => {
      const progressRecord = enrollments.find(e => e.courseId === course.id);
      const completedLessonIds = (progressRecord?.completedLessons as string[]) || [];
      
      const courseLessons = allLessons.filter(l => l.courseId === course.id);
      
      let progress = 0;
      if (courseLessons.length > 0) {
        progress = Math.round((completedLessonIds.length / courseLessons.length) * 100);
      }

      const levels = courseLessons.map((lesson, index) => {
        const isCompleted = completedLessonIds.includes(lesson.id);
        
        let status = "locked";
        if (isCompleted) {
          status = "done";
        } else {
          // If the previous lesson is completed, or it's the first lesson, then it's current
          const previousCompleted = index === 0 || completedLessonIds.includes(courseLessons[index - 1].id);
          if (previousCompleted) {
            status = "current";
          }
        }

        return {
          id: lesson.id,
          title: lesson.title,
          desc: lesson.description || "",
          status: status,
          stars: isCompleted ? 3 : 0,
          content: lesson.content,
          rewardXp: lesson.rewardXp
        };
      });

      return {
        id: course.id,
        title: course.title,
        iconName: course.icon || "BookOpen", // Pass string name, client maps to component
        color: course.color || "from-blue-500 to-primary",
        progress,
        levels
      };
    });
  }

  const catalogCourses = allCourses.map(c => ({
    id: c.id,
    title: c.title,
    category: c.category,
    difficulty: c.difficulty || "Débutant",
    duration: "À définir", // In a real app we might compute this from lesson count
    image: c.image || "https://images.unsplash.com/photo-1546410531-bb4caa6b424d?auto=format&fit=crop&w=600&q=80",
    downloaded: false
  }));

  return (
    <CoursesClient 
      initialMyCourses={myCoursesData} 
      initialCatalogCourses={catalogCourses} 
    />
  );
}
