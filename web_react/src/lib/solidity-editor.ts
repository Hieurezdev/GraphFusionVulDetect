import { loader } from '@monaco-editor/react';
import * as monaco from 'monaco-editor/editor/editor.api';
import EditorWorker from 'monaco-editor/editor/editor.worker?worker';
import 'monaco-editor/editor/contrib/find/browser/findController';
import 'monaco-editor/editor/contrib/folding/browser/folding';
import 'monaco-editor/editor/contrib/bracketMatching/browser/bracketMatching';
import 'monaco-editor/editor/contrib/hover/browser/hoverContribution';
import 'monaco-editor/editor/contrib/suggest/browser/suggestController';
import 'monaco-editor/editor/contrib/snippet/browser/snippetController2';
import 'monaco-editor/editor/contrib/contextmenu/browser/contextmenu';
import 'monaco-editor/editor/contrib/clipboard/browser/clipboard';
import 'monaco-editor/editor/contrib/multicursor/browser/multicursor';
import 'monaco-editor/editor/contrib/linesOperations/browser/linesOperations';

// Bundle the editor and worker locally; never use the loader's default CDN.
self.MonacoEnvironment = { getWorker: () => new EditorWorker() };
loader.config({ monaco });

const keywords = ['pragma', 'solidity', 'import', 'contract', 'interface', 'library', 'function', 'constructor', 'modifier', 'event', 'error', 'struct', 'enum', 'mapping', 'address', 'bool', 'string', 'bytes', 'uint256', 'int256', 'public', 'private', 'internal', 'external', 'view', 'pure', 'payable', 'memory', 'storage', 'calldata', 'returns', 'return', 'require', 'assert', 'revert', 'emit', 'if', 'else', 'for', 'while', 'new', 'delete', 'virtual', 'override', 'immutable', 'constant', 'unchecked', 'assembly', 'try', 'catch', 'is'];

monaco.languages.register({ id: 'solidity', extensions: ['.sol'] });
monaco.languages.setMonarchTokensProvider('solidity', {
  keywords,
  tokenizer: {
    root: [
      [/\/\*/, 'comment', '@comment'], [/\/\/.*$/, 'comment'],
      [/"([^"\\]|\\.)*"|'([^'\\]|\\.)*'/, 'string'],
      [/\b0x[\da-fA-F]+\b|\b\d+(?:\.\d+)?\b/, 'number'],
      [/[a-zA-Z_$][\w$]*/, { cases: { '@keywords': 'keyword', '@default': 'identifier' } }],
      [/[{}()[\]]/, '@brackets'], [/[;,.]/, 'delimiter'], [/[=><!~?:&|+\-*/%^]+/, 'operator'],
    ],
    comment: [[/[^/*]+/, 'comment'], [/\*\//, 'comment', '@pop'], [/[/*]/, 'comment']],
  },
});
monaco.languages.setLanguageConfiguration('solidity', {
  comments: { lineComment: '//', blockComment: ['/*', '*/'] },
  brackets: [['{', '}'], ['[', ']'], ['(', ')']],
  autoClosingPairs: [{ open: '{', close: '}' }, { open: '[', close: ']' }, { open: '(', close: ')' }, { open: '"', close: '"', notIn: ['string'] }],
});
monaco.languages.registerCompletionItemProvider('solidity', {
  provideCompletionItems(model, position) {
    const word = model.getWordUntilPosition(position);
    const range = new monaco.Range(position.lineNumber, word.startColumn, position.lineNumber, word.endColumn);
    return { suggestions: keywords.map(label => ({ label, kind: monaco.languages.CompletionItemKind.Keyword, insertText: label, range })) };
  },
});
monaco.editor.defineTheme('graphfusion', {
  base: 'vs-dark', inherit: true,
  rules: [{ token: 'keyword', foreground: 'C1DF7A' }, { token: 'comment', foreground: '77848C' }, { token: 'string', foreground: '91C9B0' }, { token: 'number', foreground: '9AB9D0' }],
  colors: { 'editor.background': '#131B20', 'editor.foreground': '#D8E0E4', 'editorLineNumber.foreground': '#6D7C86', 'editorLineNumber.activeForeground': '#C1DF7A', 'editor.selectionBackground': '#344B53', 'editor.lineHighlightBackground': '#1A242B', 'editorCursor.foreground': '#C1DF7A' },
});

export { monaco };
