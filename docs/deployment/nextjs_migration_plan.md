# PAWS360 AdminLTE to Next.js Migration Plan

## 📋 **Migration Overview**

### **Current State Analysis**
- **Frontend**: AdminLTE v4.0.0-rc4 (static HTML/CSS/JS template)
- **Server**: Python HTTP server (simple file serving)
- **Routing**: None (static file serving)
- **Build**: NPM scripts with Rollup/SCSS compilation
- **Integration**: Manual API calls to backend services

### **Target State**
- **Frontend**: Next.js 14+ with App Router
- **Server**: Next.js development/production server
- **Routing**: Next.js App Router with nested routes
- **Build**: Next.js build system with optimized compilation
- **Integration**: Server-side rendering, API routes, data fetching

---

## 🎯 **Phase 1: Project Setup & Foundation (Week 1)**

### **1.1 Initialize Next.js Project**
```bash
# Create new Next.js project alongside existing admin-ui
npx create-next-app@latest paws360-next --typescript --tailwind --app
cd paws360-next

# Install additional dependencies
npm install @adminlte/admin-lte bootstrap @fortawesome/fontawesome-free
npm install axios swr @tanstack/react-query
npm install apexcharts react-apexcharts
npm install jsvectormap react-jsvectormap
npm install overlayscrollbars-react
```

### **1.2 Project Structure Migration**
```
paws360-next/
├── app/                          # Next.js App Router
│   ├── (dashboard)/             # Route groups
│   │   ├── layout.tsx           # Dashboard layout
│   │   ├── page.tsx             # Main dashboard
│   │   ├── widgets/             # Widget pages
│   │   └── analytics/           # Analytics pages
│   ├── auth/                    # Authentication routes
│   │   ├── login/
│   │   └── profile/
│   ├── api/                     # API routes (backend integration)
│   │   ├── auth/
│   │   ├── students/
│   │   └── courses/
│   └── globals.css              # Global styles
├── components/                   # Reusable components
│   ├── ui/                      # AdminLTE components
│   ├── charts/                  # Chart components
│   └── forms/                   # Form components
├── lib/                         # Utilities
│   ├── api.ts                   # API client
│   ├── auth.ts                  # Authentication
│   └── config.ts                # Configuration
└── public/                      # Static assets
    ├── images/
    └── fonts/
```

### **1.3 AdminLTE Asset Migration**
```bash
# Copy AdminLTE assets to Next.js public directory
cp -r ../admin-ui/dist/css/* ./public/css/
cp -r ../admin-ui/dist/js/* ./public/js/
cp -r ../admin-ui/dist/assets/* ./public/assets/

# Update CSS imports in globals.css
@import 'bootstrap/dist/css/bootstrap.min.css';
@import './css/adminlte.min.css';
@import '@fortawesome/fontawesome-free/css/all.min.css';
```

### **1.4 Landing Page Template Migration**
```bash
# Fetch the login template from AdminLTE server
curl -o login-template.html http://localhost:8080/themes/v4/examples/login.html

# Create the landing page directory structure
mkdir -p src/app/(auth)/login
mkdir -p src/components/auth
```

**Convert Login Template to Next.js Component:**
```tsx
// src/components/auth/login-form.tsx
'use client'

import { useState } from 'react'
import { useRouter } from 'next/navigation'

export function LoginForm() {
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [rememberMe, setRememberMe] = useState(false)
  const router = useRouter()

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    // TODO: Implement authentication logic
    console.log('Login attempt:', { email, password, rememberMe })
    // On success, redirect to dashboard
    router.push('/dashboard')
  }

  return (
    <div className="login-box">
      <div className="login-logo">
        <a href="/">
          <b>PAWS</b>360
        </a>
      </div>

      <div className="card">
        <div className="card-body login-card-body">
          <p className="login-box-msg">Sign in to start your session</p>

          <form onSubmit={handleSubmit}>
            <div className="input-group mb-3">
              <input
                type="email"
                className="form-control"
                placeholder="Email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                required
              />
              <div className="input-group-append">
                <div className="input-group-text">
                  <span className="fas fa-envelope"></span>
                </div>
              </div>
            </div>

            <div className="input-group mb-3">
              <input
                type="password"
                className="form-control"
                placeholder="Password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
              <div className="input-group-append">
                <div className="input-group-text">
                  <span className="fas fa-lock"></span>
                </div>
              </div>
            </div>

            <div className="row">
              <div className="col-8">
                <div className="icheck-primary">
                  <input
                    type="checkbox"
                    id="remember"
                    checked={rememberMe}
                    onChange={(e) => setRememberMe(e.target.checked)}
                  />
                  <label htmlFor="remember">Remember Me</label>
                </div>
              </div>

              <div className="col-4">
                <button type="submit" className="btn btn-primary btn-block">
                  Sign In
                </button>
              </div>
            </div>
          </form>

          <div className="social-auth-links text-center mb-3">
            <p>- OR -</p>
            <a href="#" className="btn btn-block btn-primary">
              <i className="fab fa-facebook mr-2"></i> Sign in using Facebook
            </a>
            <a href="#" className="btn btn-block btn-danger">
              <i className="fab fa-google-plus mr-2"></i> Sign in using Google+
            </a>
          </div>

          <p className="mb-1">
            <a href="/auth/forgot-password">I forgot my password</a>
          </p>
          <p className="mb-0">
            <a href="/auth/register" className="text-center">
              Register a new membership
            </a>
          </p>
        </div>
      </div>
    </div>
  )
}
```

**Create Landing Page (Root Route):**
```tsx
// src/app/page.tsx
import { LoginForm } from '@/components/auth/login-form'

export default function LandingPage() {
  return (
    <div className="hold-transition login-page">
      <div className="login-box">
        <LoginForm />
      </div>
    </div>
  )
}
```

**Update Root Layout for Landing Page:**
```tsx
// src/app/layout.tsx
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'PAWS360 - University Administration System',
  description: 'Secure login to PAWS360 administration dashboard',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={`${inter.className} hold-transition login-page`}>
        {children}
      </body>
    </html>
  )
}
```

**Add Login-Specific Styles:**
```css
/* src/app/globals.css (add to existing) */
.hold-transition {
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
}

.login-page {
  background: transparent;
}

.login-box {
  width: 360px;
  margin: 7% auto;
}

.login-logo {
  font-size: 35px;
  text-align: center;
  margin-bottom: 25px;
  font-weight: 300;
}

.login-logo a {
  color: #fff;
  text-decoration: none;
}

.login-box-msg {
  margin: 0;
  text-align: center;
  padding: 0 20px 20px 20px;
  color: #666;
}

.login-card-body {
  background: #fff;
  border-radius: 10px;
  box-shadow: 0 10px 30px rgba(0,0,0,0.1);
}
```

---

## 🎯 **Phase 2: Core Layout & Navigation (Week 2)**

### **2.1 Root Layout Migration**
```tsx
// app/layout.tsx
import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'
import { SidebarProvider } from '@/components/ui/sidebar-context'

const inter = Inter({ subsets: ['latin'] })

export const metadata: Metadata = {
  title: 'PAWS360 Admin Dashboard',
  description: 'University administration system',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className={inter.className}>
        <SidebarProvider>
          {children}
        </SidebarProvider>
      </body>
    </html>
  )
}
```

### **2.2 Dashboard Layout Component**
```tsx
// app/(dashboard)/layout.tsx
import { Sidebar } from '@/components/ui/sidebar'
import { Header } from '@/components/ui/header'
import { Footer } from '@/components/ui/footer'

export default function DashboardLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <div className="app-wrapper">
      <Sidebar />
      <div className="app-main">
        <Header />
        <main className="app-content">
          {children}
        </main>
        <Footer />
      </div>
    </div>
  )
}
```

### **2.3 Navigation System Migration**
```tsx
// components/ui/sidebar.tsx
'use client'

import Link from 'next/link'
import { usePathname } from 'next/navigation'
import { useState } from 'react'

const navigation = [
  {
    name: 'Dashboard',
    href: '/dashboard',
    icon: 'bi-speedometer',
    children: [
      { name: 'Dashboard v1', href: '/dashboard' },
      { name: 'Dashboard v2', href: '/dashboard/v2' },
      { name: 'Dashboard v3', href: '/dashboard/v3' },
    ]
  },
  {
    name: 'Students',
    href: '/students',
    icon: 'bi-people',
  },
  {
    name: 'Courses',
    href: '/courses',
    icon: 'bi-book',
  },
  {
    name: 'Analytics',
    href: '/analytics',
    icon: 'bi-graph-up',
  },
]

export function Sidebar() {
  const pathname = usePathname()
  const [expandedItems, setExpandedItems] = useState<string[]>([])

  return (
    <aside className="app-sidebar">
      <div className="sidebar-brand">
        <Link href="/dashboard" className="brand-link">
          <span className="brand-text">PAWS360</span>
        </Link>
      </div>
      <nav className="sidebar-nav">
        <ul className="nav nav-treeview">
          {navigation.map((item) => (
            <SidebarItem
              key={item.name}
              item={item}
              pathname={pathname}
              expandedItems={expandedItems}
              setExpandedItems={setExpandedItems}
            />
          ))}
        </ul>
      </nav>
    </aside>
  )
}
```

---

## 🎯 **Phase 3: Page Components Migration (Week 3)**

### **3.1 Dashboard Page Migration**
```tsx
// app/(dashboard)/page.tsx
import { Card } from '@/components/ui/card'
import { Chart } from '@/components/charts/sales-chart'
import { StatsCards } from '@/components/dashboard/stats-cards'

export default function DashboardPage() {
  return (
    <div className="container-fluid">
      <div className="row mb-4">
        <StatsCards />
      </div>

      <div className="row">
        <div className="col-lg-7">
          <Card title="Sales Value">
            <Chart />
          </Card>
        </div>

        <div className="col-lg-5">
          <Card title="World Map">
            <WorldMap />
          </Card>
        </div>
      </div>
    </div>
  )
}
```

### **3.2 Dynamic Route Migration**
```tsx
// app/students/[id]/page.tsx
import { notFound } from 'next/navigation'
import { getStudent } from '@/lib/api/students'
import { StudentDetail } from '@/components/students/student-detail'

interface PageProps {
  params: {
    id: string
  }
}

export default async function StudentDetailPage({ params }: PageProps) {
  const student = await getStudent(params.id)

  if (!student) {
    notFound()
  }

  return <StudentDetail student={student} />
}
```

### **3.3 API Routes Migration**
```tsx
// app/api/students/route.ts
import { NextRequest, NextResponse } from 'next/server'
import { getStudents, createStudent } from '@/lib/api/students'

export async function GET(request: NextRequest) {
  try {
    const students = await getStudents()
    return NextResponse.json({ data: students })
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch students' },
      { status: 500 }
    )
  }
}

export async function POST(request: NextRequest) {
  try {
    const body = await request.json()
    const student = await createStudent(body)
    return NextResponse.json(student, { status: 201 })
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to create student' },
      { status: 500 }
    )
  }
}
```

---

## 🎯 **Phase 4: Data Fetching & State Management (Week 4)**

### **4.1 API Client Setup**
```tsx
// lib/api/client.ts
import axios from 'axios'

const api = axios.create({
  baseURL: process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8082',
  timeout: 10000,
})

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('auth-token')
  if (token) {
    config.headers.Authorization = `Bearer ${token}`
  }
  return config
})

export default api
```

### **4.2 Data Fetching with SWR**
```tsx
// lib/api/students.ts
import useSWR from 'swr'
import api from './client'

export function useStudents() {
  return useSWR('/api/students', (url) =>
    api.get(url).then(res => res.data)
  )
}

export function useStudent(id: string) {
  return useSWR(`/api/students/${id}`, (url) =>
    api.get(url).then(res => res.data)
  )
}
```

### **4.3 Server Components with Data Fetching**
```tsx
// app/students/page.tsx
import { Suspense } from 'react'
import { StudentsTable } from '@/components/students/students-table'
import { StudentsSkeleton } from '@/components/students/students-skeleton'

async function getStudents() {
  const res = await fetch(`${process.env.API_URL}/api/students`, {
    cache: 'no-store'
  })

  if (!res.ok) {
    throw new Error('Failed to fetch students')
  }

  return res.json()
}

export default async function StudentsPage() {
  const students = await getStudents()

  return (
    <div className="container-fluid">
      <div className="row">
        <div className="col-12">
          <div className="card">
            <div className="card-header">
              <h3 className="card-title">Students</h3>
            </div>
            <div className="card-body">
              <Suspense fallback={<StudentsSkeleton />}>
                <StudentsTable students={students.data} />
              </Suspense>
            </div>
          </div>
        </div>
      </div>
    </div>
  )
}
```

---

## 🎯 **Phase 5: Authentication & Security (Week 5)**

### **5.1 Authentication Setup**
```tsx
// lib/auth.ts
import { NextAuthOptions } from 'next-auth'
import CredentialsProvider from 'next-auth/providers/credentials'

export const authOptions: NextAuthOptions = {
  providers: [
    CredentialsProvider({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' }
      },
      async authorize(credentials) {
        try {
          const res = await fetch(`${process.env.API_URL}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify(credentials)
          })

          const user = await res.json()

          if (res.ok && user) {
            return user
          }
          return null
        } catch (error) {
          return null
        }
      }
    })
  ],
  pages: {
    signIn: '/auth/login',
    signOut: '/auth/logout',
  },
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        token.accessToken = user.token
      }
      return token
    },
    async session({ session, token }) {
      session.accessToken = token.accessToken
      return session
    }
  }
}
```

### **5.2 Protected Routes**
```tsx
// components/auth/protected-route.tsx
'use client'

import { useSession } from 'next-auth/react'
import { useRouter } from 'next/navigation'
import { useEffect } from 'react'

export function ProtectedRoute({ children }: { children: React.ReactNode }) {
  const { data: session, status } = useSession()
  const router = useRouter()

  useEffect(() => {
    if (status === 'loading') return // Still loading

    if (!session) {
      router.push('/auth/login')
    }
  }, [session, status, router])

  if (status === 'loading') {
    return <div>Loading...</div>
  }

  if (!session) {
    return null
  }

  return <>{children}</>
}
```

---

## 🎯 **Phase 6: Build Optimization & Deployment (Week 6)**

### **6.1 Next.js Configuration**
```javascript
// next.config.js
/** @type {import('next').NextConfig} */
const nextConfig = {
  experimental: {
    appDir: true,
  },
  images: {
    domains: ['localhost'],
  },
  async rewrites() {
    return [
      {
        source: '/api/:path*',
        destination: 'http://localhost:8082/api/:path*',
      },
    ]
  },
  async headers() {
    return [
      {
        source: '/api/:path*',
        headers: [
          { key: 'Access-Control-Allow-Origin', value: '*' },
          { key: 'Access-Control-Allow-Methods', value: 'GET,POST,PUT,DELETE' },
          { key: 'Access-Control-Allow-Headers', value: 'Content-Type,Authorization' },
        ],
      },
    ]
  },
}

module.exports = nextConfig
```

### **6.2 Environment Configuration**
```bash
# .env.local
NEXT_PUBLIC_API_URL=http://localhost:8082
NEXTAUTH_URL=http://localhost:3000
NEXTAUTH_SECRET=your-secret-key

# .env.production
NEXT_PUBLIC_API_URL=https://api.paws360.edu
NEXTAUTH_URL=https://paws360.edu
NEXTAUTH_SECRET=production-secret-key
```

### **6.3 Build Scripts**
```json
// package.json scripts
{
  "scripts": {
    "dev": "next dev -p 3000",
    "build": "next build",
    "start": "next start -p 3000",
    "lint": "next lint",
    "migrate": "npm run build && npm run start"
  }
}
```

---

## 🎯 **Phase 7: Testing & Quality Assurance (Week 7)**

### **7.1 Component Testing**
```tsx
// __tests__/components/sidebar.test.tsx
import { render, screen } from '@testing-library/react'
import { Sidebar } from '@/components/ui/sidebar'

describe('Sidebar', () => {
  it('renders navigation items', () => {
    render(<Sidebar />)

    expect(screen.getByText('Dashboard')).toBeInTheDocument()
    expect(screen.getByText('Students')).toBeInTheDocument()
    expect(screen.getByText('Courses')).toBeInTheDocument()
  })

  it('highlights active navigation item', () => {
    render(<Sidebar />)

    // Test active state logic
  })
})
```

### **7.2 E2E Testing**
```typescript
// e2e/dashboard.spec.ts
import { test, expect } from '@playwright/test'

test('dashboard loads correctly', async ({ page }) => {
  await page.goto('http://localhost:3000/dashboard')

  // Check if dashboard elements are present
  await expect(page.locator('text=Dashboard')).toBeVisible()
  await expect(page.locator('.stats-cards')).toBeVisible()

  // Test navigation
  await page.click('text=Students')
  await expect(page).toHaveURL('http://localhost:3000/students')
})
```

---

## 🎯 **Phase 8: Deployment & Rollback Strategy (Week 8)**

### **8.1 Docker Integration**
```dockerfile
# Dockerfile
FROM node:18-alpine AS base

# Install dependencies only when needed
FROM base AS deps
RUN apk add --no-cache libc6-compat
WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

# Rebuild the source code only when needed
FROM base AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .

ENV NEXT_TELEMETRY_DISABLED 1
RUN npm run build

# Production image, copy all the files and run next
FROM base AS runner
WORKDIR /app

ENV NODE_ENV production
ENV NEXT_TELEMETRY_DISABLED 1

RUN addgroup --system --gid 1001 nodejs
RUN adduser --system --uid 1001 nextjs

COPY --from=builder /app/public ./public

# Set the correct permission for prerender cache
RUN mkdir .next
RUN chown nextjs:nodejs .next

# Automatically leverage output traces to reduce image size
COPY --from=builder --chown=nextjs:nodejs /app/.next/standalone ./
COPY --from=builder --chown=nextjs:nodejs /app/.next/static ./.next/static

USER nextjs

EXPOSE 3000
ENV PORT 3000

CMD ["node", "server.js"]
```

### **8.2 Deployment Scripts**
```bash
#!/bin/bash
# deploy-nextjs.sh

set -e

echo "🚀 Deploying PAWS360 Next.js Application..."

# Build the application
npm run build

# Run tests
npm run test

# Create backup of current deployment
cp -r /var/www/paws360 /var/www/paws360.backup.$(date +%Y%m%d_%H%M%S)

# Deploy new version
cp -r .next /var/www/paws360/
cp -r public /var/www/paws360/

# Restart services
sudo systemctl restart paws360-nextjs
sudo systemctl restart nginx

echo "✅ Deployment completed successfully!"
```

### **8.3 Rollback Strategy**
```bash
#!/bin/bash
# rollback-nextjs.sh

set -e

echo "🔄 Rolling back PAWS360 Next.js Application..."

# Find latest backup
LATEST_BACKUP=$(ls -t /var/www/paws360.backup.* | head -1)

if [ -z "$LATEST_BACKUP" ]; then
    echo "❌ No backup found!"
    exit 1
fi

echo "📦 Restoring from: $LATEST_BACKUP"

# Restore backup
cp -r "$LATEST_BACKUP/.next" /var/www/paws360/
cp -r "$LATEST_BACKUP/public" /var/www/paws360/

# Restart services
sudo systemctl restart paws360-nextjs
sudo systemctl restart nginx

echo "✅ Rollback completed successfully!"
```

---

## 📊 **Migration Timeline & Milestones**

| Phase | Duration | Deliverables | Risk Level |
|-------|----------|--------------|------------|
| **Phase 1**: Setup | 1 week | Next.js project, basic structure | Low |
| **Phase 2**: Layout | 1 week | Navigation, routing system | Medium |
| **Phase 3**: Pages | 1 week | Component migration, pages | Medium |
| **Phase 4**: Data | 1 week | API integration, state management | High |
| **Phase 5**: Auth | 1 week | Authentication, security | High |
| **Phase 6**: Build | 1 week | Optimization, configuration | Medium |
| **Phase 7**: Testing | 1 week | QA, E2E testing | Medium |
| **Phase 8**: Deploy | 1 week | Production deployment | High |

**Total Duration: 8 weeks**

---

## ⚠️ **Risk Assessment & Mitigation**

### **High-Risk Areas**
1. **API Integration Complexity**
   - *Risk*: Backend service compatibility issues
   - *Mitigation*: Comprehensive API testing, gradual migration

2. **Authentication Migration**
   - *Risk*: Session management and security gaps
   - *Mitigation*: Parallel authentication systems during transition

3. **Performance Impact**
   - *Risk*: Initial performance degradation
   - *Mitigation*: Performance monitoring, optimization phases

### **Rollback Strategy**
- **Database**: Keep AdminLTE version running in parallel
- **Frontend**: Blue-green deployment with instant rollback
- **Services**: Maintain both old and new service endpoints
- **Data**: Comprehensive backup strategy before migration

---

## 🎯 **Success Criteria**

### **Functional Requirements**
- ✅ All AdminLTE pages accessible via Next.js routes
- ✅ Authentication and authorization working
- ✅ API integration functional
- ✅ Responsive design maintained
- ✅ All interactive features working

### **Performance Requirements**
- ✅ Page load time < 3 seconds
- ✅ Time to interactive < 5 seconds
- ✅ Lighthouse score > 90
- ✅ Bundle size < 500KB

### **Quality Requirements**
- ✅ Test coverage > 80%
- ✅ Zero critical security vulnerabilities
- ✅ WCAG 2.1 AA accessibility compliance
- ✅ Cross-browser compatibility

---

## 📋 **Migration Checklist**

### **Pre-Migration**
- [ ] Next.js project initialized
- [ ] AdminLTE assets migrated
- [ ] Development environment configured
- [ ] Team training completed

### **Migration Execution**
- [ ] Phase-by-phase migration following timeline
- [ ] Daily testing and validation
- [ ] Performance monitoring
- [ ] User feedback collection

### **Post-Migration**
- [ ] AdminLTE codebase archived
- [ ] Documentation updated
- [ ] Team training on Next.js
- [ ] Production monitoring established

---

## 🚀 **Benefits of Next.js Migration**

### **Technical Benefits**
- **Server-Side Rendering**: Better SEO and performance
- **Static Generation**: Fast loading pages
- **API Routes**: Backend functionality in frontend
- **Type Safety**: TypeScript integration
- **Modern React**: Latest React features and hooks

### **Development Benefits**
- **Developer Experience**: Better tooling and debugging
- **Scalability**: Better code organization and maintainability
- **Performance**: Optimized builds and caching
- **Ecosystem**: Rich Next.js community and plugins

### **Business Benefits**
- **SEO Improvement**: Better search engine visibility
- **User Experience**: Faster page loads and interactions
- **Maintainability**: Easier code updates and feature additions
- **Future-Proof**: Modern technology stack

---

**Migration Plan Version**: 1.0
**Estimated Duration**: 8 weeks
**Risk Level**: Medium-High
**Success Probability**: 85%
**Team Lead**: [Assign Team Member]
**Start Date**: [Target Start Date]