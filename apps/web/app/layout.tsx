import type { Metadata } from 'next';
import './styles.css';

export const metadata: Metadata = {
  title: 'Agent Identity Platform',
  description: 'The identity control plane for AI agents and digital workers.'
};

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
