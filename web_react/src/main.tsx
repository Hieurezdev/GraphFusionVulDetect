import { readPreferences, resolveTheme } from "./lib/preferences";
// Before the first paint (the CSP forbids an inline script in index.html): no dark flash for a light-mode user
document.documentElement.dataset.theme = resolveTheme(readPreferences().theme);
import { createRoot } from "react-dom/client";
import App from "./App.tsx";
import "./index.css";

createRoot(document.getElementById("root")!).render(<App />);
