import React from 'react';
import { Navigate, useLocation } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import { Loader2 } from 'lucide-react';
import { useT } from "@/i18n";

interface ProtectedRouteProps {
  children: React.ReactNode;
}

const ProtectedRoute: React.FC<ProtectedRouteProps> = ({ children }) => {
  const { isAuthenticated, isLoading, user } = useAuth();
  const t = useT();
  const location = useLocation();

  if (isLoading) {
    return (
      <div className="flex min-h-dvh items-center justify-center bg-background" role="status">
        <p className="flex items-center gap-3 text-muted-foreground">
          <Loader2 className="keep-motion h-4 w-4 animate-spin text-signal" aria-hidden="true" />
          {t("Checking your session…")}
        </p>
      </div>
    );
  }

  if (!isAuthenticated) {
    // Redirect to login page with return url
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  // The server refuses every request until the current legal texts are accepted: go there first
  if (user?.consents_required.length && location.pathname !== '/consent') {
    return <Navigate to="/consent" state={{ from: location }} replace />;
  }

  return <>{children}</>;
};

export default ProtectedRoute;
