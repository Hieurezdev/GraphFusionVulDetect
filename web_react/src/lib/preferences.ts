import { useEffect, useState } from "react";

export type Preferences = {
  animateScans: boolean;
  collapseFinishedSteps: boolean;
  startPage: "/analysis" | "/project";
  language: "en" | "vi";
  /** Uploader agrees that their contracts and the expert verdicts on them may be used to retrain the models. Off by default. */
  trainingConsent: boolean;
};

const KEY = "gf_preferences";
const EVENT = "gf-preferences";
const DEFAULTS: Preferences = { animateScans: true, collapseFinishedSteps: false, startPage: "/analysis", language: "en", trainingConsent: false };

export const readPreferences = (): Preferences => {
  try {
    return { ...DEFAULTS, ...JSON.parse(localStorage.getItem(KEY) || "{}") };
  } catch {
    return DEFAULTS;
  }
};

export const writePreferences = (next: Partial<Preferences>) => {
  const merged = { ...readPreferences(), ...next };
  try {
    localStorage.setItem(KEY, JSON.stringify(merged));
  } catch {
    return;
  }
  window.dispatchEvent(new Event(EVENT));
};

export const usePreferences = (): Preferences => {
  const [prefs, setPrefs] = useState(readPreferences);
  useEffect(() => {
    const sync = () => setPrefs(readPreferences());
    window.addEventListener(EVENT, sync);
    window.addEventListener("storage", sync);
    return () => {
      window.removeEventListener(EVENT, sync);
      window.removeEventListener("storage", sync);
    };
  }, []);
  return prefs;
};
