import { apiFetch } from './api';

// Types matching backend schemas
export interface UserRegister {
  username: string;
  email: string;
  password: string;
  full_name?: string;
  /** personal: a guest workspace for one person; business: an organisation whose admin adds members */
  account_type?: AccountType;
  organization_name?: string;
}

export type AccountType = "personal" | "business";

export interface UserLogin {
  username: string;
  password: string;
}

export interface Token {
  access_token: string;
  token_type: string;
  expires_in: number;
}

export interface UserProfile {
  user_id?: string;
  username?: string;
  email?: string;
  full_name?: string;
  bio?: string;
  created_at?: string;
  last_login?: string;
  role?: Role;
  organization_id?: string | null;
  organization_name?: string | null;
  personal_workspace?: boolean;
  permissions?: Permission[];
  policy?: DataPolicy;
  llm_external?: boolean;
  consents_required?: string[];
}

export type Role = "admin" | "developer" | "non_tech" | "expert";
export type Permission = "upload" | "view_source" | "fix_tools" | "request_review" | "delete_own_session"
  | "delete_any_session" | "delete_project" | "review" | "manage_organization";

export interface DataPolicy {
  retention_days: number;
  external_llm: boolean;
  training_data: boolean;
  platform_experts: boolean;
}

export interface LegalDocument {
  key: string;
  title: string;
  version: string;
  required: boolean;
  content: string;
}

export interface AuthResponse {
  token: Token;
  user: UserProfile;
}

// Auth Service Class
export class AuthService {
  private static readonly AUTH_ENDPOINTS = {
    LOGIN: '/api/v1/auth/login',
    REGISTER: '/api/v1/auth/register',
    LOGOUT: '/api/v1/auth/logout',
    ME: '/api/v1/auth/me',
    PROFILE: '/api/v1/auth/profile',
    CHANGE_PASSWORD: '/api/v1/auth/change-password',
    LOGOUT_ALL: '/api/v1/auth/logout-all',
    LEGAL: '/api/v1/auth/legal',
    CONSENTS: '/api/v1/auth/consents',
    ACCOUNT: '/api/v1/auth/account',
  };

  /** The terms, privacy policy, upload commitment and training-data text (public). */
  static legal(lang: string): Promise<LegalDocument[]> {
    return apiFetch<LegalDocument[]>(`${this.AUTH_ENDPOINTS.LEGAL}?lang=${lang}`);
  }

  /** Accept the required texts; a workspace admin also answers training_data. Returns the updated profile. */
  static submitConsents(body: { terms: boolean; privacy: boolean; upload_rights: boolean; training_data?: boolean }): Promise<UserProfile> {
    return apiFetch<UserProfile>(this.AUTH_ENDPOINTS.CONSENTS, { method: 'POST', body, requireAuth: true });
  }

  /** Delete the account (and, alone in a workspace, everything in it). */
  static async deleteAccount(password: string): Promise<void> {
    await apiFetch(this.AUTH_ENDPOINTS.ACCOUNT, { method: 'DELETE', body: { password }, requireAuth: true });
    AuthService.clearAuth();
  }

  /**
   * Register a new user
   */
  static async register(userData: UserRegister): Promise<UserProfile> {
    try {
      const user = await apiFetch<UserProfile>(this.AUTH_ENDPOINTS.REGISTER, {
        method: 'POST',
        body: userData,
      });
      
      return user;
    } catch (error) {
      console.error('Registration error:', error);
      throw error;
    }
  }

  /**
   * Login user and get access token
   */
  static async login(credentials: UserLogin): Promise<Token> {
    try {
      const tokenData = await apiFetch<Token>(this.AUTH_ENDPOINTS.LOGIN, {
        method: 'POST',
        body: credentials,
      });

 // Step 2.5: the token stays in the httpOnly cookie set by the server; only its expiry is kept, for display.
      localStorage.removeItem('auth_token');
      localStorage.setItem('auth_expires_at', String(Date.now() + tokenData.expires_in * 1000));
      
      return tokenData;
    } catch (error) {
      console.error('Login error:', error);
      throw error;
    }
  }

  /**
   * Get current user profile
   */
  static async getCurrentUser(): Promise<UserProfile> {
    try {
      const user = await apiFetch<UserProfile>(this.AUTH_ENDPOINTS.ME, {
        method: 'GET',
        requireAuth: true,
        redirectOn401: false,
      });
      
      return user;
    } catch (error) {
      console.error('Get current user error:', error);
      throw error;
    }
  }

  /**
   * Logout user
   */
  static async logout(): Promise<void> {
    try {
      await apiFetch(this.AUTH_ENDPOINTS.LOGOUT, {
        method: 'POST',
        requireAuth: true,
      });
    } catch (error) {
      console.error('Logout error:', error);
      // Don't throw error for logout - always clear local storage
    } finally {
      // Always clear local storage
      AuthService.clearAuth();
    }
  }

  /**
   * Update user profile
   */
  static async updateProfile(profileData: Partial<UserProfile>): Promise<UserProfile> {
    try {
      const updatedUser = await apiFetch<UserProfile>(this.AUTH_ENDPOINTS.PROFILE, {
        method: 'PUT',
        body: profileData,
        requireAuth: true,
      });
      
      return updatedUser;
    } catch (error) {
      console.error('Update profile error:', error);
      throw error;
    }
  }

  /**
   * Change password; the server signs out every other session and returns a fresh token
   */
  static async changePassword(currentPassword: string, newPassword: string): Promise<void> {
    const tokenData = await apiFetch<Token>(this.AUTH_ENDPOINTS.CHANGE_PASSWORD, {
      method: 'POST',
      body: { current_password: currentPassword, new_password: newPassword },
      requireAuth: true,
    });
    localStorage.setItem('auth_expires_at', String(Date.now() + tokenData.expires_in * 1000));
  }

  /**
   * Sign out on every device, this one included
   */
  static async logoutAll(): Promise<void> {
    try {
      await apiFetch(this.AUTH_ENDPOINTS.LOGOUT_ALL, { method: 'POST', requireAuth: true });
    } finally {
      AuthService.clearAuth();
    }
  }

  /**
   * Check if user is authenticated
   */
  static isAuthenticated(): boolean {
    return !!AuthService.getStoredUser();  // a hint only: the server decides, through the cookie
  }

  /**
   * Get stored token
   */
  static getToken(): string | null {
    return null;  // the token lives in an httpOnly cookie that JavaScript cannot read (step 2.5)
  }

  /** When the current session expires (ms since epoch), or null when unknown. */
  static getExpiry(): number | null {
    const v = Number(localStorage.getItem('auth_expires_at'));
    return Number.isFinite(v) && v > 0 ? v : null;
  }

  /**
   * Clear authentication data
   */
  static clearAuth(): void {
    localStorage.removeItem('auth_token');
    localStorage.removeItem('auth_user');
    localStorage.removeItem('auth_expires_at');
  }

  /**
   * Store user data in localStorage
   */
  static storeUser(user: UserProfile): void {
    localStorage.setItem('auth_user', JSON.stringify(user));
  }

  /**
   * Get stored user data
   */
  static getStoredUser(): UserProfile | null {
    try {
      const userData = localStorage.getItem('auth_user');
      return userData ? JSON.parse(userData) : null;
    } catch (error) {
      console.error('Error parsing stored user data:', error);
      return null;
    }
  }
}

export default AuthService;
