# Service Integration Contracts: Frontend ↔ Backend

**Date**: November 6, 2024  
**Service**: Cross-Service Communication  
**Implementation**: Next.js Frontend + Spring Boot Backend

## Frontend Service Configuration

### Environment-Based API Configuration

#### Development Environment
```typescript
// .env.local (development)
NEXT_PUBLIC_API_BASE_URL=http://localhost:8081
NEXT_PUBLIC_API_TIMEOUT=10000
NEXT_PUBLIC_SESSION_DURATION=86400000  // 24 hours in ms
```

#### Container Environment  
```typescript
// .env.production (container)
NEXT_PUBLIC_API_BASE_URL=http://backend:8081
NEXT_PUBLIC_API_TIMEOUT=15000
NEXT_PUBLIC_SESSION_DURATION=86400000
```

### API Client Service Layer

#### Centralized API Service (NEW)
```typescript
// lib/api-client.ts
interface APIConfig {
  baseURL: string;
  timeout: number;
  retryAttempts: number;
}

class PAWS360ApiClient {
  private config: APIConfig;
  private authToken: string | null = null;

  constructor(config: APIConfig) {
    this.config = config;
    this.loadAuthToken();
  }

  private loadAuthToken(): void {
    if (typeof window !== 'undefined') {
      this.authToken = localStorage.getItem('authToken');
    }
  }

  private getHeaders(): Record<string, string> {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    
    if (this.authToken) {
      headers['Authorization'] = `Bearer ${this.authToken}`;
    }
    
    return headers;
  }

  async login(credentials: LoginRequest): Promise<LoginResponse> {
    const response = await fetch(`${this.config.baseURL}/login`, {
      method: 'POST',
      headers: this.getHeaders(),
      body: JSON.stringify(credentials),
      credentials: 'include',
    });

    if (!response.ok) {
      throw new APIError(response.status, await response.json());
    }

    const data = await response.json();
    
    if (data.session_token) {
      this.authToken = data.session_token;
      localStorage.setItem('authToken', data.session_token);
      localStorage.setItem('userEmail', data.email);
      localStorage.setItem('userFirstName', data.firstname);
    }
    
    return data;
  }

  async getCurrentUser(): Promise<UserResponse> {
    const response = await fetch(`${this.config.baseURL}/users/profile`, {
      method: 'GET', 
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      if (response.status === 401) {
        this.clearAuth();
        throw new AuthenticationError('Session expired');
      }
      throw new APIError(response.status, await response.json());
    }

    return response.json();
  }

  async getDomainValues(domain: string): Promise<any[]> {
    const response = await fetch(`${this.config.baseURL}/domains/${domain}`, {
      method: 'GET',
      headers: this.getHeaders(),
    });

    if (!response.ok) {
      throw new APIError(response.status, await response.json());
    }

    return response.json();
  }

  private clearAuth(): void {
    this.authToken = null;
    localStorage.removeItem('authToken');
    localStorage.removeItem('userEmail');
    localStorage.removeName('userFirstName');
  }

  logout(): void {
    this.clearAuth();
    // Optional: Call backend logout endpoint
  }
}

// Error classes
class APIError extends Error {
  constructor(public status: number, public response: any) {
    super(`API Error ${status}: ${response.message || 'Unknown error'}`);
  }
}

class AuthenticationError extends Error {
  constructor(message: string) {
    super(message);
  }
}
```

#### API Service Initialization
```typescript  
// lib/api.ts
import { PAWS360ApiClient } from './api-client';

const apiConfig = {
  baseURL: process.env.NEXT_PUBLIC_API_BASE_URL || 'http://localhost:8081',
  timeout: parseInt(process.env.NEXT_PUBLIC_API_TIMEOUT || '10000'),
  retryAttempts: 3,
};

export const apiClient = new PAWS360ApiClient(apiConfig);
```

## Authentication Integration

### Enhanced Login Form (Modification)
```typescript
// components/LoginForm/login.tsx (Enhanced)
export default function LoginForm() {
  // ... existing form setup

  async function onSubmit(values: z.infer<typeof formSchema>) {
    setIsLoading(true);
    try {
      const response = await apiClient.login(values);
      
      toast({
        title: "Login Successful",
        description: `Welcome ${response.firstname}! Redirecting...`,
        duration: 1500,
      });

      setTimeout(() => {
        router.push("/homepage");
      }, 1500);
      
    } catch (error) {
      if (error instanceof APIError) {
        toast({
          variant: "destructive", 
          title: "Login Failed",
          description: error.response.message || "Authentication failed",
        });
      } else {
        toast({
          variant: "destructive",
          title: "Error", 
          description: "Unable to connect to server",
        });
      }
      form.reset({ ...values, password: "" });
    } finally {
      setIsLoading(false);
    }
  }

  // ... rest of component
}
```

### Authentication Hook (NEW)
```typescript
// hooks/useAuth.tsx (Enhancement)
import { useRouter } from 'next/navigation';
import { apiClient } from '@/lib/api';

interface AuthContext {
  user: UserResponse | null;
  login: (credentials: LoginRequest) => Promise<void>;
  logout: () => void;
  isAuthenticated: boolean;
  isLoading: boolean;
}

export const useAuth = (): AuthContext => {
  const [user, setUser] = useState<UserResponse | null>(null);
  const [isLoading, setIsLoading] = useState(true);
  const router = useRouter();

  useEffect(() => {
    validateSession();
  }, []);

  const validateSession = async () => {
    try {
      if (typeof window !== 'undefined' && localStorage.getItem('authToken')) {
        const userData = await apiClient.getCurrentUser();
        setUser(userData);
      }
    } catch (error) {
      // Session invalid, clear local storage
      logout();
    } finally {
      setIsLoading(false);
    }
  };

  const login = async (credentials: LoginRequest) => {
    const response = await apiClient.login(credentials);
    setUser(response);
  };

  const logout = () => {
    apiClient.logout();
    setUser(null);
    router.push('/login');
  };

  return {
    user,
    login,
    logout,
    isAuthenticated: !!user,
    isLoading,
  };
};
```

## Backend Service Coordination

### Health Check Implementation (NEW)
```java
// Controller: HealthController.java (To Be Created)
@RestController
@RequestMapping("/health")
public class HealthController {

    @Autowired
    private DataSource dataSource;

    @GetMapping
    public ResponseEntity<Map<String, Object>> health() {
        Map<String, Object> health = new HashMap<>();
        Map<String, String> checks = new HashMap<>();
        
        // Database connectivity check
        try {
            dataSource.getConnection().isValid(5);
            checks.put("database", "UP");
        } catch (Exception e) {
            checks.put("database", "DOWN");
        }
        
        // Authentication service check (basic)
        checks.put("authentication", "UP");
        
        // Overall status
        boolean allUp = checks.values().stream().allMatch(status -> "UP".equals(status));
        health.put("status", allUp ? "UP" : "DOWN");
        health.put("checks", checks);
        health.put("timestamp", Instant.now());
        
        return ResponseEntity.ok(health);
    }
}
```

### CORS Configuration (Enhancement)
```java
// Configuration: WebConfig.java (Enhancement Needed)
@Configuration
@EnableWebMvc
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins(
                    "http://localhost:3000",     // Development
                    "http://frontend:3000"       // Container
                )
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true)
                .maxAge(3600);
    }
}
```

### Application Configuration Profiles (Enhancement)
```yaml
# src/main/resources/application-container.yml (NEW)
spring:
  profiles:
    active: container
  datasource:
    url: jdbc:postgresql://database:5432/paws360
    username: ${DB_USER:paws360_app}
    password: ${DB_PASSWORD:secure_password}
    driver-class-name: org.postgresql.Driver
  jpa:
    hibernate:
      ddl-auto: validate
    show-sql: false
    properties:
      hibernate:
        dialect: org.hibernate.dialect.PostgreSQLDialect

server:
  port: 8081
  servlet:
    context-path: /

logging:
  level:
    com.uwm.paws360: INFO
    org.springframework.security: INFO

# CORS origins for container environment
app:
  cors:
    allowed-origins: 
      - http://frontend:3000
      - http://localhost:3000
```

## Container Networking

### Docker Compose Service Configuration
```yaml
# docker-compose.yml (Enhancement)
version: '3.8'

networks:
  paws360-network:
    driver: bridge

services:
  database:
    image: postgres:15
    container_name: paws360-database
    environment:
      POSTGRES_DB: paws360
      POSTGRES_USER: paws360_app
      POSTGRES_PASSWORD: secure_password
    ports:
      - "5432:5432"
    volumes:
      - ./database/paws360_database_ddl.sql:/docker-entrypoint-initdb.d/01-schema.sql
      - ./database/paws360_seed_data.sql:/docker-entrypoint-initdb.d/02-seed.sql
    networks:
      - paws360-network
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U paws360_app -d paws360"]
      interval: 10s
      timeout: 5s
      retries: 5

  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    container_name: paws360-backend
    environment:
      SPRING_PROFILES_ACTIVE: container
      DB_USER: paws360_app
      DB_PASSWORD: secure_password
    ports:
      - "8081:8081"
    depends_on:
      database:
        condition: service_healthy
    networks:
      - paws360-network
    healthcheck:
      test: ["CMD-SHELL", "curl -f http://localhost:8081/health || exit 1"]
      interval: 30s
      timeout: 10s
      retries: 3

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend  
    container_name: paws360-frontend
    environment:
      NEXT_PUBLIC_API_BASE_URL: http://backend:8081
    ports:
      - "3000:3000"
    depends_on:
      backend:
        condition: service_healthy
    networks:
      - paws360-network
```

## Service Discovery & Communication

### Internal Service Communication
```typescript
// Frontend service discovery
const getApiBaseUrl = (): string => {
  // Check if running in container
  if (process.env.NODE_ENV === 'production') {
    return process.env.NEXT_PUBLIC_API_BASE_URL || 'http://backend:8081';
  }
  return 'http://localhost:8081';
};
```

### External Service Access
```bash
# External access points (host machine)
Frontend: http://localhost:3000
Backend API: http://localhost:8081  
Database: localhost:5432 (direct access)

# Internal container communication
frontend -> backend: http://backend:8081
backend -> database: jdbc:postgresql://database:5432/paws360
```

## Error Handling & Resilience

### Network Error Handling
```typescript
// Enhanced API client with retry logic
class PAWS360ApiClient {
  async makeRequest<T>(
    url: string, 
    options: RequestInit,
    retries: number = this.config.retryAttempts
  ): Promise<T> {
    try {
      const response = await fetch(url, {
        ...options,
        signal: AbortSignal.timeout(this.config.timeout),
      });

      if (!response.ok) {
        throw new APIError(response.status, await response.json());
      }

      return response.json();
    } catch (error) {
      if (retries > 0 && this.shouldRetry(error)) {
        await this.delay(1000);
        return this.makeRequest(url, options, retries - 1);
      }
      throw error;
    }
  }

  private shouldRetry(error: any): boolean {
    // Retry on network errors, timeouts, and 5xx responses
    return error instanceof TypeError || // Network error
           error.name === 'TimeoutError' ||
           (error instanceof APIError && error.status >= 500);
  }

  private delay(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }
}
```

### Circuit Breaker Pattern (Future Enhancement)
```typescript
// Circuit breaker for service resilience
class CircuitBreaker {
  private failures = 0;
  private isOpen = false;
  private lastFailureTime = 0;
  
  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.isOpen && Date.now() - this.lastFailureTime < 60000) {
      throw new Error('Circuit breaker is open');
    }
    
    try {
      const result = await fn();
      this.reset();
      return result;
    } catch (error) {
      this.recordFailure();
      throw error;
    }
  }

  private recordFailure(): void {
    this.failures++;
    this.lastFailureTime = Date.now();
    if (this.failures >= 5) {
      this.isOpen = true;
    }
  }

  private reset(): void {
    this.failures = 0;
    this.isOpen = false;
    this.lastFailureTime = 0;
  }
}
```

## Integration Testing

### End-to-End Service Integration
```typescript
describe('Frontend-Backend Integration', () => {
  test('Complete authentication flow', async () => {
    // Test login flow
    const loginResponse = await apiClient.login(validCredentials);
    expect(loginResponse.session_token).toBeDefined();
    
    // Test authenticated request
    const userResponse = await apiClient.getCurrentUser();
    expect(userResponse.email).toBe(validCredentials.email);
    
    // Test logout
    apiClient.logout();
    expect(localStorage.getItem('authToken')).toBeNull();
  });

  test('Network resilience', async () => {
    // Test timeout handling
    jest.setTimeout(15000);
    
    // Test retry mechanism
    const mockNetworkError = () => Promise.reject(new TypeError('Network error'));
    const result = await apiClient.makeRequest('/health', {}, 2);
    
    // Should succeed after retries
    expect(result.status).toBe('UP');
  });
});
```

## Implementation Status

✅ **Existing**: Login form, localStorage session management  
🔧 **Enhancement Needed**: Centralized API client, health check endpoint, CORS configuration  
📋 **Implementation Required**: Docker networking, service discovery, error resilience  
🚀 **Future**: Circuit breaker, advanced monitoring, service mesh integration

**Next Implementation Priority**: Health check endpoint and Docker compose networking configuration