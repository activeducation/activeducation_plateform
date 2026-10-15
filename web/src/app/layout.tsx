import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ActivEducation",
  description: "Plateforme d'orientation scolaire et professionnelle panafricaine.",
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="fr">
      <body className="antialiased flex flex-col font-sans">
        {children}
      </body>
    </html>
  );
}
