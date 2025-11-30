import type { NextConfig } from 'next';

// Backend base URL for proxying API requests in dev/prod.
// Prefer NEXT_PUBLIC_API_BASE_URL if provided; fallback to local Spring Boot port.
const backendBase = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8086';

const nextConfig: NextConfig = {
  // For Next 15+ static export behavior: ensure the build produces a full static
  // export (out/) when desired. This mirrors older `next export` functionality.
  // Configure carefully — when you enable this the app should be fully static
  // compatible (no runtime server-only features on exported pages).
  output: 'export',
  /* config options here */
  
  // Hot Module Replacement (HMR) configuration for rapid development
  webpack: (config, { dev, isServer }) => {
    if (dev && !isServer) {
      // Enable HMR with fast refresh for sub-3s hot-reload
      config.watchOptions = {
        poll: 300, // Poll every 300ms for file changes (Docker volume compatibility)
        aggregateTimeout: 200, // Wait 200ms after change before rebuilding
      };
    }
    return config;
  },
  
  // Enable experimental features for faster development
  experimental: {
    // Turbopack support for faster builds (Next.js 14+)
    // turbo: {
    //   enabled: true,
    // },
  },
  
  typescript: {
    ignoreBuildErrors: true,
  },
  eslint: {
    ignoreDuringBuilds: true,
  },
  images: {
    remotePatterns: [
      {
        protocol: 'https',
        hostname: 'placehold.co',
        port: '',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'images.unsplash.com',
        port: '',
        pathname: '/**',
      },
      {
        protocol: 'https',
        hostname: 'picsum.photos',
        port: '',
        pathname: '/**',
      },
    ],
  },
  async rewrites() {
    // Proxy auth and API requests to the backend to avoid cross-origin cookies/CORS.
    return [
      {
        source: '/auth/:path*',
        destination: `${backendBase}/auth/:path*`,
      },
      {
        source: '/api/:path*',
        destination: `${backendBase}/api/:path*`,
      },
      {
        source: '/actuator/:path*',
        destination: `${backendBase}/actuator/:path*`,
      },
    ];
  },
};

export default nextConfig;
