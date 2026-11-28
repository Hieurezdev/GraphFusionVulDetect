import { readPreferences, usePreferences } from "@/lib/preferences";
import { vi } from "./vi";
import { plain } from "./plain";

type Vars = Record<string, string | number>;

const fill = (text: string, vars?: Vars) =>
  vars ? text.replace(/\{(\w+)\}/g, (_, k) => (k in vars ? String(vars[k]) : `{${k}}`)) : text;

const lookup = (language: string, text: string, vars?: Vars, simple = false) => {
  const p = simple ? plain[text] : undefined;  // everyday wording for a non-technical member
  if (p) return fill(language === "vi" ? p.vi : p.en, vars);
  return fill(language === "vi" ? vi[text] ?? text : text, vars);
};

export const translate = (text: string, vars?: Vars) => {
  const { language, plainLanguage } = readPreferences();
  return lookup(language, text, vars, plainLanguage);
};

export const localeOf = (language: string) => (language === "vi" ? "vi-VN" : "en-GB");

export const useT = () => {
  const { language, plainLanguage } = usePreferences();
  const t = (text: string, vars?: Vars) => lookup(language, text, vars, plainLanguage);
  return Object.assign(t, { language, locale: localeOf(language) });
};
