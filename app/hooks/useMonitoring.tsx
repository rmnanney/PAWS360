// T061: React Hook for Frontend Monitoring Integration
// Constitutional Compliance: Article VIIa (Monitoring Discovery and Integration)
//
// React hook for easy integration of PAWS360 monitoring service
// with Next.js components and authentication flows

'use client';

import { useEffect, useCallback, useRef } from 'react';
import monitoringService from '../lib/monitoring';

interface UseMonitoringOptions {
  trackPageViews?: boolean;
  trackUserInteractions?: boolean;
  trackAuthEvents?: boolean;
  trackApiCalls?: boolean;
}

interface UseMonitoringReturn {
  recordAuthEvent: (event: 'success' | 'failure' | 'timeout', duration?: number) => void;
  recordApiCall: (endpoint: string, method: string, duration: number, success: boolean, statusCode?: number) => void;
  recordUserInteraction: (action: string, element?: string, duration?: number, success?: boolean) => void;
  recordPageView: (pageName: string) => void;
  recordFormSubmission: (formName: string, success: boolean, duration?: number) => void;
  recordError: (error: Error | string, context?: string) => void;
  setUserId: (userId: string) => void;
  clearUserId: () => void;
  getSessionSummary: () => object;
}

export function useMonitoring(options: UseMonitoringOptions = {}): UseMonitoringReturn {
  const {
    trackPageViews = true,
    trackUserInteractions = true,
    trackAuthEvents = true,
    trackApiCalls = true
  } = options;

  const lastPageRef = useRef<string>('');
  const pageStartTimeRef = useRef<number>(0);

  // Track page views automatically
  useEffect(() => {
    if (trackPageViews && typeof window !== 'undefined') {
      const currentPage = window.location.pathname;
      
      // Record previous page view duration if exists
      if (lastPageRef.current && pageStartTimeRef.current) {
        const duration = performance.now() - pageStartTimeRef.current;
        monitoringService.recordPerformanceMetric('page_view_duration', duration);
      }

      // Record new page view
      monitoringService.recordUserInteraction('navigation', currentPage, 0, true);
      lastPageRef.current = currentPage;
      pageStartTimeRef.current = performance.now();
    }
  }, [trackPageViews]);

  // Record authentication events
  const recordAuthEvent = useCallback((event: 'success' | 'failure' | 'timeout', duration?: number) => {
    if (trackAuthEvents) {
      monitoringService.recordAuthenticationEvent(event, duration);
      
      // Track authentication timing
      if (duration) {
        monitoringService.recordPerformanceMetric('auth_duration', duration);
      }
    }
  }, [trackAuthEvents]);

  // Record API call performance
  const recordApiCall = useCallback((endpoint: string, method: string, duration: number, success: boolean, statusCode?: number) => {
    if (trackApiCalls) {
      monitoringService.recordApiCall(endpoint, method, duration, success, statusCode);
      
      // Track API performance patterns
      const normalizedEndpoint = endpoint.replace(/\/\d+/g, '/:id'); // Normalize ID parameters
      monitoringService.recordPerformanceMetric(`api_${normalizedEndpoint.replace(/\//g, '_')}_duration`, duration);
    }
  }, [trackApiCalls]);

  // Record user interactions
  const recordUserInteraction = useCallback((action: string, element?: string, duration?: number, success: boolean = true) => {
    if (trackUserInteractions) {
      monitoringService.recordUserInteraction(
        action as any, // Cast to the specific type expected by monitoring service
        element,
        duration,
        success
      );
    }
  }, [trackUserInteractions]);

  // Record page views manually
  const recordPageView = useCallback((pageName: string) => {
    monitoringService.recordUserInteraction('navigation', pageName, 0, true);
    
    // Track page load performance
    if (typeof window !== 'undefined' && window.performance) {
      const navigation = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming;
      if (navigation) {
        const loadTime = navigation.loadEventEnd - navigation.fetchStart;
        monitoringService.recordPerformanceMetric(`page_${pageName.replace(/\//g, '_')}_load_time`, loadTime);
      }
    }
  }, []);

  // Record form submissions
  const recordFormSubmission = useCallback((formName: string, success: boolean, duration?: number) => {
    monitoringService.recordUserInteraction('form_submit', formName, duration, success);
    
    if (!success) {
      monitoringService.recordError('javascript', `Form submission failed: ${formName}`);
    }
  }, []);

  // Record errors
  const recordError = useCallback((error: Error | string, context?: string) => {
    const errorMessage = typeof error === 'string' ? error : error.message;
    const errorStack = typeof error === 'object' ? error.stack : undefined;
    
    monitoringService.recordError(
      'javascript',
      context ? `${context}: ${errorMessage}` : errorMessage,
      errorStack
    );
  }, []);

  // Set user ID for authenticated tracking
  const setUserId = useCallback((userId: string) => {
    monitoringService.setUserId(userId);
  }, []);

  // Clear user ID on logout
  const clearUserId = useCallback(() => {
    monitoringService.clearUserId();
  }, []);

  // Get session summary
  const getSessionSummary = useCallback(() => {
    return monitoringService.getSessionSummary();
  }, []);

  return {
    recordAuthEvent,
    recordApiCall,
    recordUserInteraction,
    recordPageView,
    recordFormSubmission,
    recordError,
    setUserId,
    clearUserId,
    getSessionSummary
  };
}

// Higher-order component for automatic monitoring
export function withMonitoring<T extends object>(
  WrappedComponent: React.ComponentType<T>,
  options: UseMonitoringOptions = {}
) {
  const MonitoredComponent = (props: T) => {
    const monitoring = useMonitoring(options);

    // Add monitoring to component props
    const enhancedProps = {
      ...props,
      monitoring
    } as T & { monitoring: UseMonitoringReturn };

    return <WrappedComponent {...enhancedProps} />;
  };

  MonitoredComponent.displayName = `withMonitoring(${WrappedComponent.displayName || WrappedComponent.name})`;

  return MonitoredComponent;
}

// Hook for API call monitoring
export function useApiMonitoring() {
  const { recordApiCall } = useMonitoring({ trackApiCalls: true });

  const monitoredFetch = useCallback(async (
    input: RequestInfo | URL,
    init?: RequestInit
  ): Promise<Response> => {
    const startTime = performance.now();
    const url = typeof input === 'string' ? input : input.toString();
    const method = init?.method || 'GET';

    try {
      const response = await fetch(input, init);
      const endTime = performance.now();
      const duration = endTime - startTime;

      recordApiCall(url, method, duration, response.ok, response.status);

      return response;
    } catch (error) {
      const endTime = performance.now();
      const duration = endTime - startTime;

      recordApiCall(url, method, duration, false);
      throw error;
    }
  }, [recordApiCall]);

  return { monitoredFetch, recordApiCall };
}

// Hook for authentication monitoring
export function useAuthMonitoring() {
  const { recordAuthEvent, setUserId, clearUserId } = useMonitoring({ trackAuthEvents: true });

  const monitorLogin = useCallback(async (
    loginFunction: () => Promise<any>,
    userId?: string
  ) => {
    const startTime = performance.now();

    try {
      const result = await loginFunction();
      const endTime = performance.now();
      const duration = endTime - startTime;

      recordAuthEvent('success', duration);
      
      if (userId) {
        setUserId(userId);
      }

      return result;
    } catch (error) {
      const endTime = performance.now();
      const duration = endTime - startTime;

      recordAuthEvent('failure', duration);
      throw error;
    }
  }, [recordAuthEvent, setUserId]);

  const monitorLogout = useCallback(async (logoutFunction: () => Promise<any>) => {
    try {
      const result = await logoutFunction();
      clearUserId();
      return result;
    } catch (error) {
      // Still clear user ID even if logout fails
      clearUserId();
      throw error;
    }
  }, [clearUserId]);

  return { monitorLogin, monitorLogout, recordAuthEvent, setUserId, clearUserId };
}

// Hook for performance monitoring
export function usePerformanceMonitoring() {
  const startTimes = useRef<Map<string, number>>(new Map());

  const startTiming = useCallback((name: string) => {
    startTimes.current.set(name, performance.now());
  }, []);

  const endTiming = useCallback((name: string) => {
    const startTime = startTimes.current.get(name);
    if (startTime) {
      const duration = performance.now() - startTime;
      monitoringService.recordPerformanceMetric(name, duration);
      startTimes.current.delete(name);
      return duration;
    }
    return null;
  }, []);

  const measureAsync = useCallback(async (
    name: string,
    asyncFunction: () => Promise<any>
  ): Promise<any> => {
    startTiming(name);
    try {
      const result = await asyncFunction();
      endTiming(name);
      return result;
    } catch (error) {
      endTiming(name);
      throw error;
    }
  }, [startTiming, endTiming]);

  return { startTiming, endTiming, measureAsync };
}

export default useMonitoring;