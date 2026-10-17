import { redirect } from 'next/navigation';
import AdminLayoutClient from './AdminLayoutClient';
import { requireAdmin } from '@/utils/auth';

export const dynamic = 'force-dynamic';

export default async function AdminLayout({ children }: { children: React.ReactNode }) {
  const { errorResponse } = await requireAdmin();
  
  if (errorResponse) {
    // Si ce n'est pas un admin, on le redirige
    redirect(errorResponse.status === 401 ? '/auth/login' : '/student');
  }

  return <AdminLayoutClient>{children}</AdminLayoutClient>;
}
