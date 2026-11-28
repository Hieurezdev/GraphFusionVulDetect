// API Base Configuration
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'http://localhost:8000';

interface ApiConfig {
  baseURL: string;
  timeout: number;
  headers: {
    'Content-Type': string;
  };
}

const apiConfig: ApiConfig = {
  baseURL: API_BASE_URL,
  timeout: 30000, // 30 seconds
  headers: {
    'Content-Type': 'application/json',
  },
};

// Step 2.5: the session lives in an httpOnly cookie the browser sends itself (credentials: 'include'); JavaScript never
// sees the token. Requests that change something carry X-Requested-With, which the backend requires for cookie sessions.
export const CSRF_HEADERS: Record<string, string> = { 'X-Requested-With': 'ScanGuard' };

const createAuthHeaders = (): Record<string, string> => ({ ...apiConfig.headers, ...CSRF_HEADERS });

// Base fetch wrapper with error handling
interface FetchOptions {
  method?: string;
  headers?: Record<string, string>;
  body?: any;
  requireAuth?: boolean;
  /** false for the session probe at start-up: a visitor without a session stays on the public page */
  redirectOn401?: boolean;
}

const apiFetch = async <T>(endpoint: string, options: FetchOptions = {}): Promise<T> => {
  const {
    method = 'GET',
    headers = {},
    body,
    requireAuth = false,
    redirectOn401 = true,
  } = options;

  const url = `${apiConfig.baseURL}${endpoint}`;
  
  const requestHeaders = {
    ...(requireAuth ? createAuthHeaders() : apiConfig.headers),
    ...headers,
  };

  const fetchOptions: RequestInit = {
    method,
    headers: requestHeaders,
    credentials: 'include',  // send / receive the httpOnly session cookie
  };

  if (body && method !== 'GET') {
    fetchOptions.body = JSON.stringify(body);
  }

  try {
    const response = await fetch(url, fetchOptions);
    
    // Handle 401 Unauthorized
    if (response.status === 401) {
      // Clear local auth data (no token is stored any more; old copies are removed too)
      localStorage.removeItem('auth_token');
      localStorage.removeItem('auth_user');
      localStorage.removeItem('auth_expires_at');
      // Redirect to login if needed
      if (redirectOn401 && window.location.pathname !== '/login') {
        window.location.href = '/login';
      }
      throw new Error('Unauthorized');
    }

    // Handle other HTTP errors
    if (!response.ok) {
      const errorData = await response.json().catch(() => ({}));
      throw new Error(errorData.detail || `HTTP ${response.status}: ${response.statusText}`);
    }

    // Handle successful response
    const contentType = response.headers.get('content-type');
    if (contentType && contentType.includes('application/json')) {
      return await response.json();
    } else {
      return await response.text() as T;
    }
  } catch (error) {
    console.error('API Error:', error);
    throw error;
  }
};

export { apiFetch, createAuthHeaders, apiConfig };
export type { ApiConfig, FetchOptions };
