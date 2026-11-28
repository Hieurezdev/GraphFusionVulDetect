import { defineConfig, loadEnv } from "vite";
import react from "@vitejs/plugin-react-swc";
import path from "path";
import { componentTagger } from "lovable-tagger";

// https://vitejs.dev/config/
export default defineConfig(({ mode }) => {
  // Where the dev server forwards /api: the backend on :8000 unless VITE_PROXY_TARGET (e.g. in .env.local) says otherwise,
  // for a machine where port 8000 is taken by something else.
  const env = loadEnv(mode, process.cwd(), "");
  return {
    server: {
      host: "::",
      port: 8080,
      proxy: {
        '/api': {
          target: env.VITE_PROXY_TARGET || 'http://0.0.0.0:8000',
          changeOrigin: true,
          secure: false,
        }
      }
    },
    plugins: [react(), mode === "development" && componentTagger()].filter(Boolean),
    resolve: {
      alias: {
        "@": path.resolve(__dirname, "./src"),
      },
    },
  };
});
