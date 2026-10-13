import { z } from 'zod';
import { lessonStepSchema } from './learning';

const optionalText = z.string().max(20_000).nullable().optional();
const optionalUrl = z.union([z.literal(''), z.url({ protocol: /^https?$/ })]).nullable().optional();
export const courseSchema = z.object({
  title: z.string().trim().min(3).max(255), description: optionalText,
  category: z.string().trim().min(1).max(100), difficulty: z.enum(['Débutant', 'Intermédiaire', 'Avancé']).default('Débutant'),
  image: optionalUrl, icon: z.string().max(50).nullable().optional(), color: z.string().max(100).regex(/^[a-z0-9\- /]+$/).nullable().optional(),
  isPublished: z.boolean().default(false),
});
export const lessonSchema = z.object({
  title: z.string().trim().min(1).max(255), description: optionalText,
  content: z.array(lessonStepSchema).max(100).default([]),
  orderIndex: z.number().int().min(0).max(10_000).default(0),
  rewardXp: z.number().int().min(0).max(10_000).default(50),
});
const optionalDate = z.preprocess(value => value === '' || value == null ? null : value, z.coerce.date().nullable());
export const opportunitySchema = z.object({
  type: z.enum(['bourse', 'stage', 'evenement']), title: z.string().trim().min(1).max(255),
  provider: z.string().max(255).nullable().optional(), description: optionalText,
  location: z.string().max(255).nullable().optional(), amountOrSalary: z.string().max(255).nullable().optional(),
  deadline: optionalDate, eventDate: optionalDate,
  criteria: z.array(z.string().max(2000)).max(100).default([]), documents: z.array(z.string().max(2000)).max(100).default([]),
  link: optionalUrl, image: optionalUrl, isRecommended: z.boolean().default(false), isPublished: z.boolean().default(false),
});
