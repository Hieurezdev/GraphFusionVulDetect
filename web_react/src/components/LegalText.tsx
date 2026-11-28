import ReactMarkdown from "react-markdown";
import remarkGfm from "remark-gfm";

/** A legal text (src/legal/*.md) inside a panel: its own title is already shown, and headings stay at body size. */
export const LegalText = ({ content }: { content: string }) => (
  <div className="space-y-2 text-sm text-ink-2 [&_li]:ml-5 [&_li]:list-disc [&_table]:w-full [&_td]:border [&_td]:border-rule [&_td]:p-1 [&_th]:border [&_th]:border-rule [&_th]:p-1 [&_th]:text-left">
    <ReactMarkdown remarkPlugins={[remarkGfm]} components={{
      h1: () => null,
      h2: ({ children }) => <h4 className="mt-3 text-sm text-ink">{children}</h4>,
      h3: ({ children }) => <h5 className="mt-2 text-sm text-ink">{children}</h5>,
    }}>{content}</ReactMarkdown>
  </div>
);
