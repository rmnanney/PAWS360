// T061: Frontend Performance Monitoring Service
// Constitutional Compliance: Article VIIa (Monitoring Discovery and Integration)
//
// Comprehensive client-side monitoring for PAWS360 Next.js application
// Includes Web Vitals, performance metrics, error tracking, and user analytics

import { onCLS, onINP, onFCP, onLCP, onTTFB, Metric } from 'web-vitals';

// Types for custom monitoring
interface PerformanceMetric {
  name: string;
  value: number;
  timestamp: number;
  url: string;
  userId?: string;
  sessionId: string;
}

interface ErrorMetric {
  type: 'javascript' | 'network' | 'authentication' | 'navigation';
  message: string;
  stack?: string;
  url: string;
  timestamp: number;
  userId?: string;
  sessionId: string;
  userAgent: string;
}

interface UserInteractionMetric {
  action: 'login' | 'logout' | 'navigation' | 'form_submit' | 'api_call';
  element?: string;
  duration?: number;
  success: boolean;
  timestamp: number;
  url: string;
  userId?: string;
  sessionId: string;
}

interface NavigationMetric {
  from: string;
  to: string;
  duration: number;
  timestamp: number;
  userId?: string;
  sessionId: string;
}

class PAWS360MonitoringService {
  private sessionId: string;
  private userId?: string;
  private metricsEndpoint: string;
  private isEnabled: boolean;
  private metricsBuffer: PerformanceMetric[] = [];
  private errorBuffer: ErrorMetric[] = [];
  private interactionBuffer: UserInteractionMetric[] = [];
  private navigationBuffer: NavigationMetric[] = [];
  private flushInterval: number = 30000; // 30 seconds
  private maxBufferSize: number = 100;

  constructor() {
    this.sessionId = this.generateSessionId();
    this.metricsEndpoint = this.getMetricsEndpoint();
    this.isEnabled = this.isMonitoringEnabled();
    
    if (this.isEnabled) {
      this.initializeMonitoring();
    }
  }

  // Initialize all monitoring capabilities
  private initializeMonitoring(): void {
    this.setupWebVitalsMonitoring();
    this.setupErrorMonitoring();
    this.setupNavigationMonitoring();
    this.setupPerformanceObserver();
    this.setupUserInteractionMonitoring();
    this.setupPeriodicFlush();
    
    // Send initial page load metric
    this.recordPageLoad();
    
    console.log('🔍 PAWS360 Frontend Monitoring initialized', {
      sessionId: this.sessionId,
      endpoint: this.metricsEndpoint,
      constitutional: 'Article VIIa'
    });
  }

  // Generate unique session ID
  private generateSessionId(): string {
    return `paws360_${Date.now()}_${Math.random().toString(36).substring(2, 15)}`;
  }

  // Get metrics endpoint URL
  private getMetricsEndpoint(): string {
    const baseUrl = process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8080';
    return `${baseUrl}/api/monitoring/frontend-metrics`;
  }

  // Check if monitoring is enabled
  private isMonitoringEnabled(): boolean {
    return process.env.NEXT_PUBLIC_MONITORING_ENABLED !== 'false';
  }

  // Set user ID for authenticated sessions
  public setUserId(userId: string): void {
    this.userId = userId;
    this.recordUserInteraction('login', '', 0, true);
  }

  // Clear user ID on logout
  public clearUserId(): void {
    if (this.userId) {
      this.recordUserInteraction('logout', '', 0, true);
    }
    this.userId = undefined;
  }

  // Setup Web Vitals monitoring (browser only)
  private setupWebVitalsMonitoring(): void {
    // Only run on client side
    if (typeof window === 'undefined' || typeof document === 'undefined') {
      return;
    }

    // Track Web Vitals using web-vitals library
    import('web-vitals').then(({ onCLS, onINP, onFCP, onLCP, onTTFB }) => {
      onCLS((metric) => {
        this.recordPerformanceMetric('vitals_cls', metric.value);
      });

      onINP((metric) => {
        this.recordPerformanceMetric('vitals_inp', metric.value);
      });

      onFCP((metric) => {
        this.recordPerformanceMetric('vitals_fcp', metric.value);
      });

      onLCP((metric) => {
        this.recordPerformanceMetric('vitals_lcp', metric.value);
      });

      onTTFB((metric) => {
        this.recordPerformanceMetric('vitals_ttfb', metric.value);
      });
    }).catch((error) => {
      console.warn('Failed to import web-vitals:', error);
    });
  }  // Check if vital is above critical threshold
  private isVitalCritical(metric: Metric): boolean {
    const thresholds: Record<string, number> = {
      'CLS': 0.25,     // Cumulative Layout Shift
      'INP': 300,      // Interaction to Next Paint (ms) - replaces FID
      'FCP': 3000,     // First Contentful Paint (ms)
      'LCP': 4000,     // Largest Contentful Paint (ms)
      'TTFB': 1500     // Time to First Byte (ms)
    };
    
    return metric.value > (thresholds[metric.name] || Infinity);
  }

  // Get vital threshold for warning
  private getVitalThreshold(vitalName: string): number {
    const thresholds: Record<string, number> = {
      'CLS': 0.25,
      'INP': 300,
      'FCP': 3000,
      'LCP': 4000,
      'TTFB': 1500
    };
    
    return thresholds[vitalName] || 0;
  }

  // Setup error monitoring
  private setupErrorMonitoring(): void {
    // Only run on client side
    if (typeof window === 'undefined') {
      return;
    }

    // JavaScript errors
    window.addEventListener('error', (event) => {
      this.recordError('javascript', event.message, event.error?.stack);
    });

    // Promise rejections
    window.addEventListener('unhandledrejection', (event) => {
      this.recordError('javascript', `Unhandled Promise Rejection: ${event.reason}`);
    });

    // Resource loading errors
    window.addEventListener('error', (event) => {
      if (event.target !== window) {
        const target = event.target as HTMLElement;
        this.recordError('network', `Resource failed to load: ${target.tagName}`);
      }
    }, true);
  }

  // Setup navigation monitoring (browser only)
  private setupNavigationMonitoring(): void {
    // Only run on client side
    if (typeof window === 'undefined') {
      return;
    }

    let lastUrl = window.location.href;
    let navigationStart = performance.now();

    // Monitor route changes in Next.js
    const observer = new MutationObserver(() => {
      const currentUrl = window.location.href;
      if (currentUrl !== lastUrl) {
        const navigationEnd = performance.now();
        const duration = navigationEnd - navigationStart;
        
        this.recordNavigation(lastUrl, currentUrl, duration);
        
        lastUrl = currentUrl;
        navigationStart = navigationEnd;
      }
    });

    observer.observe(document.body, {
      childList: true,
      subtree: true
    });

    // Monitor page visibility changes
    document.addEventListener('visibilitychange', () => {
      if (document.hidden) {
        this.recordUserInteraction('navigation', 'page_hidden', 0, true);
      } else {
        this.recordUserInteraction('navigation', 'page_visible', 0, true);
      }
    });
  }

  // Setup Performance Observer for detailed metrics
  private setupPerformanceObserver(): void {
    // Only run on client side
    if (typeof window === 'undefined' || !('PerformanceObserver' in window)) {
      return;
    }

    // Long Tasks Observer
    try {
      const longTaskObserver = new PerformanceObserver((list) => {
        list.getEntries().forEach((entry) => {
          this.recordPerformanceMetric('long_task_duration', entry.duration);
          
          if (entry.duration > 100) {
            console.warn('🐌 Long task detected:', {
              duration: entry.duration,
              constitutional: 'Article VIIa'
            });
          }
        });
      });
      longTaskObserver.observe({ entryTypes: ['longtask'] });
    } catch (e) {
      console.log('Long task observer not supported');
    }

    // Navigation Observer
    try {
      const navigationObserver = new PerformanceObserver((list) => {
        list.getEntries().forEach((entry) => {
          const navEntry = entry as PerformanceNavigationTiming;
          this.recordPerformanceMetric('navigation_load_time', navEntry.loadEventEnd - navEntry.fetchStart);
          this.recordPerformanceMetric('dom_content_loaded', navEntry.domContentLoadedEventEnd - navEntry.fetchStart);
          this.recordPerformanceMetric('dom_interactive', navEntry.domInteractive - navEntry.fetchStart);
        });
      });
      navigationObserver.observe({ entryTypes: ['navigation'] });
    } catch (e) {
      console.log('Navigation observer not supported');
    }
  }

  // Setup user interaction monitoring (browser only)
  private setupUserInteractionMonitoring(): void {
    // Only run on client side
    if (typeof window === 'undefined' || typeof document === 'undefined') {
      return;
    }

    // Monitor form submissions
    document.addEventListener('submit', (event) => {
      const form = event.target as HTMLFormElement;
      const formName = form.name || form.id || 'unknown';
      
      this.recordUserInteraction('form_submit', formName, 0, true);
    });

    // Monitor authentication-related interactions
    document.addEventListener('click', (event) => {
      const target = event.target as HTMLElement;
      const buttonText = target.textContent?.toLowerCase() || '';
      
      if (buttonText.includes('login') || buttonText.includes('sign in')) {
        this.recordUserInteraction('login', target.tagName, 0, true);
      } else if (buttonText.includes('logout') || buttonText.includes('sign out')) {
        this.recordUserInteraction('logout', target.tagName, 0, true);
      }
    });
  }

  // Record performance metric
  public recordPerformanceMetric(name: string, value: number): void {
    if (!this.isEnabled) return;

    const metric: PerformanceMetric = {
      name: `paws360_frontend_${name}`,
      value,
      timestamp: Date.now(),
      url: window.location.href,
      userId: this.userId,
      sessionId: this.sessionId
    };

    this.metricsBuffer.push(metric);
    this.checkBufferSize();
  }

  // Record error
  public recordError(type: ErrorMetric['type'], message: string, stack?: string): void {
    if (!this.isEnabled) return;

    const error: ErrorMetric = {
      type,
      message,
      stack,
      url: window.location.href,
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId,
      userAgent: navigator.userAgent
    };

    this.errorBuffer.push(error);
    this.checkBufferSize();

    // Log critical errors immediately
    if (type === 'authentication' || type === 'javascript') {
      console.error('🚨 PAWS360 Frontend Error:', error);
    }
  }

  // Record user interaction
  public recordUserInteraction(action: UserInteractionMetric['action'], element?: string, duration?: number, success: boolean = true): void {
    if (!this.isEnabled) return;

    const interaction: UserInteractionMetric = {
      action,
      element,
      duration,
      success,
      timestamp: Date.now(),
      url: window.location.href,
      userId: this.userId,
      sessionId: this.sessionId
    };

    this.interactionBuffer.push(interaction);
    this.checkBufferSize();
  }

  // Record navigation
  private recordNavigation(from: string, to: string, duration: number): void {
    if (!this.isEnabled) return;

    const navigation: NavigationMetric = {
      from,
      to,
      duration,
      timestamp: Date.now(),
      userId: this.userId,
      sessionId: this.sessionId
    };

    this.navigationBuffer.push(navigation);
    this.checkBufferSize();
  }

  // Record page load
  private recordPageLoad(): void {
    if (typeof window !== 'undefined' && window.performance) {
      const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      
      if (navigation) {
        this.recordPerformanceMetric('page_load_time', navigation.loadEventEnd - navigation.fetchStart);
        this.recordPerformanceMetric('dom_ready_time', navigation.domContentLoadedEventEnd - navigation.fetchStart);
        this.recordPerformanceMetric('first_byte_time', navigation.responseStart - navigation.requestStart);
      }
    }
  }

  // Check buffer sizes and flush if needed
  private checkBufferSize(): void {
    if (this.metricsBuffer.length >= this.maxBufferSize ||
        this.errorBuffer.length >= this.maxBufferSize ||
        this.interactionBuffer.length >= this.maxBufferSize ||
        this.navigationBuffer.length >= this.maxBufferSize) {
      this.flushMetrics();
    }
  }

  // Setup periodic flush
  private setupPeriodicFlush(): void {
    // Only run on client side
    if (typeof window === 'undefined') {
      return;
    }

    setInterval(() => {
      this.flushMetrics();
    }, this.flushInterval);

    // Flush on page unload
    window.addEventListener('beforeunload', () => {
      this.flushMetrics();
    });
  }

  // Flush all metrics to backend
  private async flushMetrics(): Promise<void> {
    if (!this.isEnabled) return;

    const hasData = this.metricsBuffer.length > 0 || 
                   this.errorBuffer.length > 0 || 
                   this.interactionBuffer.length > 0 || 
                   this.navigationBuffer.length > 0;

    if (!hasData) return;

    const payload = {
      sessionId: this.sessionId,
      userId: this.userId,
      timestamp: Date.now(),
      metrics: [...this.metricsBuffer],
      errors: [...this.errorBuffer],
      interactions: [...this.interactionBuffer],
      navigations: [...this.navigationBuffer],
      metadata: {
        url: window.location.href,
        userAgent: navigator.userAgent,
        screen: {
          width: screen.width,
          height: screen.height
        },
        constitutional: 'Article VIIa'
      }
    };

    try {
      // Send to backend endpoint
      const response = await fetch(this.metricsEndpoint, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify(payload),
        keepalive: true // Ensure delivery on page unload
      });

      if (response.ok) {
        // Clear buffers on successful send
        this.metricsBuffer = [];
        this.errorBuffer = [];
        this.interactionBuffer = [];
        this.navigationBuffer = [];
      } else {
        console.warn('Failed to send metrics to backend:', response.status);
      }
    } catch (error) {
      console.warn('Error sending metrics:', error);
      // Keep metrics in buffer for retry
    }
  }

  // Public method to record API call performance
  public recordApiCall(endpoint: string, method: string, duration: number, success: boolean, statusCode?: number): void {
    this.recordPerformanceMetric(`api_call_${method.toLowerCase()}_duration`, duration);
    this.recordUserInteraction('api_call', `${method} ${endpoint}`, duration, success);
    
    if (!success) {
      this.recordError('network', `API call failed: ${method} ${endpoint} (${statusCode || 'unknown'})`);
    }
  }

  // Public method to record authentication events
  public recordAuthenticationEvent(event: 'success' | 'failure' | 'timeout', duration?: number): void {
    this.recordUserInteraction('login', `auth_${event}`, duration, event === 'success');
    
    if (event === 'failure' || event === 'timeout') {
      this.recordError('authentication', `Authentication ${event}${duration ? ` after ${duration}ms` : ''}`);
    }
  }

  // Get current session metrics summary
  public getSessionSummary(): object {
    return {
      sessionId: this.sessionId,
      userId: this.userId,
      metricsCount: this.metricsBuffer.length,
      errorsCount: this.errorBuffer.length,
      interactionsCount: this.interactionBuffer.length,
      navigationsCount: this.navigationBuffer.length,
      constitutional: 'Article VIIa'
    };
  }
}

// Create singleton instance
const monitoringService = new PAWS360MonitoringService();

export default monitoringService;
export type { PerformanceMetric, ErrorMetric, UserInteractionMetric, NavigationMetric };