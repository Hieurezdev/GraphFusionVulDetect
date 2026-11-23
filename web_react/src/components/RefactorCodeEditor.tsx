import { useEffect, useId, useRef, useState } from 'react';
import Editor, { DiffEditor } from '@monaco-editor/react';
import type { editor } from 'monaco-editor';
import { monaco } from '@/lib/solidity-editor';
import { CompilerDiagnostic } from '@/services/refactorbot';
import { translate, useT } from '@/i18n';

export type EditorFile = 'original' | 'proposal' | 'tests' | 'diff';
export interface EditorSelection { file: EditorFile; startLine: number; endLine: number; text: string }
export interface EditorJump { file: EditorFile; line: number; column: number; sequence: number }

interface Props {
  file: EditorFile; source: string; draft: string; tests: string; readOnly: boolean;
  scope: { start: number; end: number } | null; diagnostics: CompilerDiagnostic[]; jump: EditorJump | null;
  onDraftChange: (value: string) => void; onTestsChange: (value: string) => void;
  onSelection: (value: EditorSelection | null) => void; onSave: () => void; onCompile: () => void;
}

export default function RefactorCodeEditor(props: Props) {
  const t = useT();
  const modelId = useId().replace(/:/g, '');
  const callbacks = useRef(props);
  callbacks.current = props;
  const [instance, setInstance] = useState<editor.IStandaloneCodeEditor | null>(null);
  const [position, setPosition] = useState({ lineNumber: 1, column: 1 });
  const { file, source, draft, tests, scope, diagnostics, jump } = props;

  useEffect(() => {
    if (!instance) return;
    const selection = instance.onDidChangeCursorSelection(event => {
      setPosition(instance.getPosition() || { lineNumber: 1, column: 1 });
      const range = event.selection;
      callbacks.current.onSelection(range.isEmpty() ? null : { file, startLine: range.startLineNumber, endLine: range.endColumn === 1 && range.endLineNumber > range.startLineNumber ? range.endLineNumber - 1 : range.endLineNumber, text: instance.getModel()?.getValueInRange(range) || '' });
    });
    const change = file === 'diff' ? instance.onDidChangeModelContent(() => callbacks.current.onDraftChange(instance.getValue())) : null;
    const save = instance.addAction({ id: 'graphfusion.save', label: translate('Save proposal'), keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.KeyS], run: () => callbacks.current.onSave() });
    const compile = instance.addAction({ id: 'graphfusion.compile', label: translate('Compile locally'), keybindings: [monaco.KeyMod.CtrlCmd | monaco.KeyCode.Enter], run: () => callbacks.current.onCompile() });
    return () => { selection.dispose(); change?.dispose(); save.dispose(); compile.dispose(); };
  }, [instance, file, t.language]);

  useEffect(() => {
    const model = instance?.getModel();
    if (!model) return;
    const markers: editor.IMarkerData[] = diagnostics.filter(item => item.start_line && (file === 'tests' ? item.source_file === 'Tests.sol' : item.source_file === 'Contract.sol')).map(item => ({
      message: item.message, severity: item.severity === 'error' ? monaco.MarkerSeverity.Error : item.severity === 'warning' ? monaco.MarkerSeverity.Warning : monaco.MarkerSeverity.Info,
      startLineNumber: item.start_line!, startColumn: item.start_column || 1, endLineNumber: item.end_line || item.start_line!, endColumn: item.end_column || (item.start_column || 1) + 1,
    }));
    if (file === 'original' && scope) markers.push({ severity: monaco.MarkerSeverity.Warning, message: translate('Unconfirmed model hypothesis. Review these lines; the score is not a security verdict.'), startLineNumber: scope.start, startColumn: 1, endLineNumber: scope.end, endColumn: model.getLineMaxColumn(Math.min(scope.end, model.getLineCount())) });
    monaco.editor.setModelMarkers(model, 'graphfusion', markers);
    const decoration = instance.createDecorationsCollection(file === 'original' && scope ? [{ range: new monaco.Range(scope.start, 1, scope.end, 1), options: { isWholeLine: true, className: 'refactor-evidence-line', linesDecorationsClassName: 'refactor-evidence-gutter' } }] : []);
    return () => { decoration.clear(); if (!model.isDisposed()) monaco.editor.setModelMarkers(model, 'graphfusion', []); };
  }, [instance, file, scope, diagnostics, t.language]);

  useEffect(() => {
    if (!instance || !jump || jump.file !== file) return;
    const lineNumber = Math.max(1, Math.min(jump.line, instance.getModel()?.getLineCount() || 1));
    const column = Math.min(jump.column, instance.getModel()?.getLineMaxColumn(lineNumber) || 1);
    instance.setPosition({ lineNumber, column }); instance.revealLineInCenter(lineNumber); instance.focus();
  }, [instance, jump, file]);

  const options: editor.IStandaloneEditorConstructionOptions = { automaticLayout: true, fontFamily: '"JetBrains Mono", monospace', fontSize: 13, lineHeight: 22, padding: { top: 16, bottom: 16 }, minimap: { enabled: false }, scrollBeyondLastLine: false, readOnly: file === 'original' || props.readOnly, glyphMargin: true, lineNumbers: 'on', folding: true, tabSize: 4, wordWrap: 'off', ariaLabel: file === 'original' ? 'Original.sol' : file === 'tests' ? 'Tests.sol' : 'Proposal.sol' };
  const loading = <div className="grid h-full place-items-center text-sm text-muted-foreground">{t('Loading local editor…')}</div>;
  return <div className="flex h-full min-h-0 flex-col" data-testid="refactor-code-editor">
    <div className="min-h-0 flex-1">
      {file === 'diff' ? <DiffEditor original={source} modified={draft} language="solidity" theme="graphfusion" originalModelPath={`inmemory://refactor/${modelId}/before.sol`} modifiedModelPath={`inmemory://refactor/${modelId}/after.sol`} options={{ ...options, readOnly: props.readOnly, originalEditable: false, renderSideBySide: true, useInlineViewWhenSpaceIsLimited: true }} loading={loading} onMount={value => setInstance(value.getModifiedEditor())} />
        : <Editor value={file === 'original' ? source : file === 'tests' ? tests : draft} language="solidity" theme="graphfusion" options={options} loading={loading} onMount={setInstance} onChange={value => { if (file === 'tests') props.onTestsChange(value || ''); else if (file === 'proposal') props.onDraftChange(value || ''); }} />}
    </div>
    <div className="code-text flex justify-between gap-3 border-t border-rule bg-paper-3 px-3 py-1 text-[11px] text-muted-foreground"><span>Solidity · UTF-8 · {file === 'original' ? t('Read only') : t('Editable draft')}</span><span>{t('Line {line}, column {column}', { line: position.lineNumber, column: position.column })}</span></div>
  </div>;
}
