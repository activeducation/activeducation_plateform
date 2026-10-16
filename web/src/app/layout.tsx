import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "ActivEducation - Orientation & Insertion Professionnelle",
  description: "Plateforme d'orientation scolaire et professionnelle panafricaine.",
  icons: {
    icon: [
      { url: "/icon.png", type: "image/png" },
      { url: "/favicon.ico", type: "image/x-icon" },
    ],
    apple: [
      { url: "/apple-icon.png", sizes: "180x180", type: "image/png" },
    ],
  },
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
