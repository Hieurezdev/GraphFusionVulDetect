import { Link } from 'react-router-dom';
import { useAuth } from '@/contexts/AuthContext';
import UserProfile from '@/components/UserProfile';
import { NavLink } from '@/components/NavLink';
import { Wordmark } from '@/components/Wordmark';
import { useT } from "@/i18n";
import { Moon, Sun } from 'lucide-react';
import { useResolvedTheme, writePreferences } from '@/lib/preferences';

const navLink = "relative inline-flex h-10 items-center whitespace-nowrap text-sm text-muted-foreground transition-colors duration-200 hover:text-ink";
const navActive = "text-ink after:absolute after:inset-x-0 after:-bottom-px after:h-px after:bg-signal";

const Header = () => {
  const { isAuthenticated, user, can } = useAuth();
  const t = useT();
  const theme = useResolvedTheme();

  if (!isAuthenticated) {
    return null;
  }

  return (
    <header className="sticky top-0 z-50 w-full border-b border-rule bg-paper">
      <div className="shell flex h-16 items-center gap-4 sm:gap-6">
        <Link to="/" className="flex items-baseline gap-3 rounded-sm" aria-label={t("GraphFusion home")}>
          <Wordmark />
          <span className="hidden text-xs text-muted-foreground lg:inline">{t("Vulnerability Detector")}</span>
        </Link>

        <nav className="flex min-w-0 items-center gap-4 overflow-x-auto sm:ml-6 sm:gap-5" aria-label={t("Main")}>
          {can("upload") && (
            <NavLink to="/analysis" end className={navLink} activeClassName={navActive}>
              {t("New Analysis")}
            </NavLink>
          )}
          <NavLink to="/project" className={navLink} activeClassName={navActive}>
            {t("Projects")}
          </NavLink>
          {can("review") && (
            <NavLink to="/review" className={navLink} activeClassName={navActive}>
              {t("Expert review")}
            </NavLink>
          )}
          {can("manage_organization") && (
            <NavLink to="/admin" className={navLink} activeClassName={navActive}>
              {user?.personal_workspace ? t("Data settings") : t("Workspace admin")}
            </NavLink>
          )}
        </nav>

        <div className="ml-auto flex items-center gap-2">
          <button
            type="button"
            onClick={() => writePreferences({ theme: theme === "light" ? "dark" : "light" })}
            className="grid h-10 w-10 place-items-center rounded-full text-muted-foreground transition-colors duration-200 hover:bg-paper-3 hover:text-ink active:translate-y-px"
            aria-label={theme === "light" ? t("Switch to dark mode") : t("Switch to light mode")}
            title={theme === "light" ? t("Switch to dark mode") : t("Switch to light mode")}
          >
            {theme === "light" ? <Moon className="h-4 w-4" aria-hidden="true" /> : <Sun className="h-4 w-4" aria-hidden="true" />}
          </button>
          <UserProfile />
        </div>
      </div>
    </header>
  );
};

export default Header;
