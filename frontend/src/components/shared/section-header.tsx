import { ChevronRight } from 'lucide-react';
import Link from 'next/link';

export default function SectionHeader({
  title, href, actionLabel = 'Tout voir',
}: {
  title: string; href?: string; actionLabel?: string;
}) {
  return (
    <div className="flex items-center justify-between px-1 mb-3.5">
      <h2 className="font-bold text-brand-text-primary text-base">{title}</h2>
      {href && (
        <Link href={href}
          className="flex items-center gap-0.5 text-xs font-medium text-brand-text-tertiary hover:text-brand-primary transition-colors">
          {actionLabel} <ChevronRight size={12} />
        </Link>
      )}
    </div>
  );
}
