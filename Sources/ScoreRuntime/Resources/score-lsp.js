/**
 * Score LSP — Language intelligence for [data-component="editor"]
 *
 * Provides autocomplete, diagnostics, hover, and go-to-definition
 * via per-language adapters:
 *   - TypeScript: TS compiler API (loaded on demand)
 *   - C: clangd WASM (loaded on demand, requires crossOriginIsolated)
 *   - Swift: TreeSitter-based symbol extraction + scope-aware completions
 *   - Shell: bash-language-server (loaded on demand)
 */
(function () {
  "use strict";

  const SCORE_PATH = "/_score/";
  const adapters = {};

  // ── LanguageAdapter interface ──
  // Each adapter must implement:
  //   init(): Promise<void>
  //   getCompletions(source, line, col): CompletionItem[]
  //   getDiagnostics(source): Diagnostic[]
  //   getDefinition(source, line, col): Location | null
  //   getHover(source, line, col): string | null
  //   dispose(): void

  // ── SwiftAdapter (TreeSitter-based) ──
  const SwiftAdapter = {
    _parser: null,

    async init() {
      if (!globalThis.ScoreEditor) return;
      this._parser = await globalThis.ScoreEditor.getParser("swift");
    },

    getCompletions(source, line, col) {
      if (!this._parser) return [];
      const tree = this._parser.parse(source);
      const symbols = this._extractSymbols(tree.rootNode, source);

      // Get the partial word at cursor
      const lines = source.split("\n");
      const currentLine = lines[line] || "";
      const before = currentLine.slice(0, col);
      const match = before.match(/[a-zA-Z_]\w*$/);
      const prefix = match ? match[0].toLowerCase() : "";

      if (!prefix) return [];

      const seen = new Set();
      const results = [];
      for (const sym of symbols) {
        const lower = sym.name.toLowerCase();
        if (lower.startsWith(prefix) && !seen.has(sym.name)) {
          seen.add(sym.name);
          results.push({
            label: sym.name,
            kind: sym.kind,
            detail: sym.detail || "",
          });
        }
      }
      return results.slice(0, 20);
    },

    getDiagnostics(source) {
      if (!this._parser) return [];
      const tree = this._parser.parse(source);
      const diags = [];

      // Check for ERROR nodes in the AST
      function walkErrors(node) {
        if (node.type === "ERROR" || node.isMissing) {
          const start = node.startPosition;
          diags.push({
            line: start.row,
            col: start.column,
            endLine: node.endPosition.row,
            endCol: node.endPosition.column,
            message: node.isMissing
              ? `Missing ${node.type}`
              : "Syntax error",
            severity: "error",
          });
        }
        for (let i = 0; i < node.childCount; i++) {
          walkErrors(node.child(i));
        }
      }
      walkErrors(tree.rootNode);
      return diags;
    },

    getDefinition(source, line, col) {
      if (!this._parser) return null;
      const tree = this._parser.parse(source);
      const point = { row: line, column: col };
      const node = tree.rootNode.descendantForPosition(point);
      if (!node) return null;

      const name = source.slice(node.startIndex, node.endIndex);
      const symbols = this._extractSymbols(tree.rootNode, source);
      const def = symbols.find(
        (s) => s.name === name && (s.kind === "function" || s.kind === "type" || s.kind === "variable")
      );
      if (def) {
        return { line: def.line, col: def.col };
      }
      return null;
    },

    getHover(source, line, col) {
      if (!this._parser) return null;
      const tree = this._parser.parse(source);
      const point = { row: line, column: col };
      const node = tree.rootNode.descendantForPosition(point);
      if (!node) return null;

      const parent = node.parent;
      if (!parent) return null;

      // Show parent context for identifiers
      if (
        parent.type === "function_declaration" ||
        parent.type === "property_declaration" ||
        parent.type === "class_declaration" ||
        parent.type === "struct_declaration"
      ) {
        const lines = source.split("\n");
        return lines[parent.startPosition.row]?.trim() || null;
      }
      return null;
    },

    _extractSymbols(rootNode, source) {
      const symbols = [];
      function walk(node) {
        const t = node.type;
        if (
          t === "function_declaration" || t === "simple_identifier" &&
          node.parent?.type === "function_declaration"
        ) {
          if (t === "function_declaration") {
            const nameNode = node.childForFieldName("name");
            if (nameNode) {
              symbols.push({
                name: source.slice(nameNode.startIndex, nameNode.endIndex),
                kind: "function",
                line: nameNode.startPosition.row,
                col: nameNode.startPosition.column,
                detail: "func",
              });
            }
          }
        }
        if (
          t === "class_declaration" || t === "struct_declaration" ||
          t === "enum_declaration" || t === "protocol_declaration"
        ) {
          const nameNode = node.childForFieldName("name");
          if (nameNode) {
            symbols.push({
              name: source.slice(nameNode.startIndex, nameNode.endIndex),
              kind: "type",
              line: nameNode.startPosition.row,
              col: nameNode.startPosition.column,
              detail: t.replace("_declaration", ""),
            });
          }
        }
        if (t === "property_declaration" || t === "constant_declaration") {
          const patternNode = node.childForFieldName("pattern") || node.childForFieldName("name");
          if (patternNode) {
            symbols.push({
              name: source.slice(patternNode.startIndex, patternNode.endIndex),
              kind: "variable",
              line: patternNode.startPosition.row,
              col: patternNode.startPosition.column,
              detail: t === "property_declaration" ? "var" : "let",
            });
          }
        }
        for (let i = 0; i < node.childCount; i++) {
          walk(node.child(i));
        }
      }
      walk(rootNode);
      return symbols;
    },

    dispose() {
      this._parser = null;
    },
  };

  // ── TypeScriptAdapter ──
  const TypeScriptAdapter = {
    _ts: null,
    _service: null,
    _files: {},

    async init() {
      // Load TypeScript compiler API
      try {
        await loadScript(SCORE_PATH + "typescript.js");
        this._ts = globalThis.ts;
      } catch (e) {
        console.warn("[ScoreLSP] TypeScript compiler not available:", e);
      }
    },

    getCompletions(source, line, col) {
      if (!this._ts) return [];
      this._updateFile("input.ts", source);
      try {
        const pos = this._getOffset(source, line, col);
        const result = this._getService().getCompletionsAtPosition(
          "input.ts", pos, {}
        );
        if (!result) return [];
        return result.entries.slice(0, 20).map((e) => ({
          label: e.name,
          kind: e.kind,
          detail: e.kind,
        }));
      } catch {
        return [];
      }
    },

    getDiagnostics(source) {
      if (!this._ts) return [];
      this._updateFile("input.ts", source);
      try {
        const service = this._getService();
        const syntactic = service.getSyntacticDiagnostics("input.ts");
        const semantic = service.getSemanticDiagnostics("input.ts");
        return [...syntactic, ...semantic].slice(0, 50).map((d) => {
          const start = this._getLineCol(source, d.start || 0);
          const end = this._getLineCol(source, (d.start || 0) + (d.length || 0));
          return {
            line: start.line,
            col: start.col,
            endLine: end.line,
            endCol: end.col,
            message: this._ts.flattenDiagnosticMessageText(d.messageText, "\n"),
            severity: d.category === 1 ? "error" : "warning",
          };
        });
      } catch {
        return [];
      }
    },

    getDefinition(source, line, col) {
      if (!this._ts) return null;
      this._updateFile("input.ts", source);
      try {
        const pos = this._getOffset(source, line, col);
        const defs = this._getService().getDefinitionAtPosition("input.ts", pos);
        if (defs && defs.length > 0) {
          const loc = this._getLineCol(source, defs[0].textSpan.start);
          return { line: loc.line, col: loc.col };
        }
      } catch {}
      return null;
    },

    getHover(source, line, col) {
      if (!this._ts) return null;
      this._updateFile("input.ts", source);
      try {
        const pos = this._getOffset(source, line, col);
        const info = this._getService().getQuickInfoAtPosition("input.ts", pos);
        if (info) {
          return this._ts.displayPartsToString(info.displayParts);
        }
      } catch {}
      return null;
    },

    _updateFile(name, content) {
      this._files[name] = { content, version: (this._files[name]?.version || 0) + 1 };
      this._service = null; // Force recreation
    },

    _getService() {
      if (this._service) return this._service;
      const ts = this._ts;
      const files = this._files;
      const host = {
        getScriptFileNames: () => Object.keys(files),
        getScriptVersion: (f) => String(files[f]?.version || 0),
        getScriptSnapshot: (f) => {
          const file = files[f];
          if (!file) return undefined;
          return ts.ScriptSnapshot.fromString(file.content);
        },
        getCurrentDirectory: () => "/",
        getCompilationSettings: () => ({
          target: ts.ScriptTarget.ESNext,
          module: ts.ModuleKind.ESNext,
          strict: true,
          noEmit: true,
        }),
        getDefaultLibFileName: () => "lib.d.ts",
        fileExists: (f) => f in files,
        readFile: (f) => files[f]?.content,
      };
      this._service = ts.createLanguageService(host, ts.createDocumentRegistry());
      return this._service;
    },

    _getOffset(source, line, col) {
      const lines = source.split("\n");
      let offset = 0;
      for (let i = 0; i < line && i < lines.length; i++) {
        offset += lines[i].length + 1;
      }
      return offset + col;
    },

    _getLineCol(source, offset) {
      const before = source.slice(0, offset);
      const lines = before.split("\n");
      return { line: lines.length - 1, col: lines[lines.length - 1].length };
    },

    dispose() {
      if (this._service) this._service.dispose();
      this._service = null;
      this._files = {};
    },
  };

  // ── ClangdAdapter (placeholder — requires clangd WASM) ──
  const ClangdAdapter = {
    _ready: false,

    async init() {
      if (!globalThis.crossOriginIsolated) {
        console.warn("[ScoreLSP] clangd requires crossOriginIsolated (SharedArrayBuffer)");
        return;
      }
      // clangd WASM loading would go here
      // For now, fall back to TreeSitter-based intelligence for C
      console.info("[ScoreLSP] clangd WASM adapter — using TreeSitter fallback for C");
    },

    getCompletions(source, line, col) {
      // Delegate to TreeSitter-based completion for C
      return TreeSitterFallback.getCompletions(source, line, col, "c");
    },

    getDiagnostics(source) {
      return TreeSitterFallback.getDiagnostics(source, "c");
    },

    getDefinition(source, line, col) {
      return TreeSitterFallback.getDefinition(source, line, col, "c");
    },

    getHover() { return null; },

    dispose() {
      this._ready = false;
    },
  };

  // ── BashAdapter (placeholder — requires bash-language-server bundle) ──
  const BashAdapter = {
    async init() {
      // bash-language-server would be loaded here
      console.info("[ScoreLSP] Bash adapter — using TreeSitter fallback for Shell");
    },

    getCompletions(source, line, col) {
      return TreeSitterFallback.getCompletions(source, line, col, "shell");
    },

    getDiagnostics(source) {
      return TreeSitterFallback.getDiagnostics(source, "shell");
    },

    getDefinition(source, line, col) {
      return TreeSitterFallback.getDefinition(source, line, col, "shell");
    },

    getHover() { return null; },
    dispose() {},
  };

  // ── TreeSitter Fallback (for C and Shell until native LSPs are loaded) ──
  const TreeSitterFallback = {
    getCompletions(source, line, col, lang) {
      if (!globalThis.ScoreEditor) return [];
      const parser = globalThis.ScoreEditor.getParser(lang);
      if (!parser || !parser.then) return []; // getParser is async
      // Sync fallback: return empty for now, completions arrive after init
      return [];
    },

    getDiagnostics(source, lang) {
      // Use SwiftAdapter's error-node walking approach
      try {
        const SE = globalThis.ScoreEditor;
        if (!SE) return [];
        // Parsers are cached, access synchronously if already loaded
        const langKey = lang === "shell" ? "bash" : lang;
        const cachedParser = SE._parsers?.[langKey];
        if (!cachedParser) return [];
        const tree = cachedParser.parse(source);
        const diags = [];
        function walkErrors(node) {
          if (node.type === "ERROR" || node.isMissing) {
            diags.push({
              line: node.startPosition.row,
              col: node.startPosition.column,
              endLine: node.endPosition.row,
              endCol: node.endPosition.column,
              message: "Syntax error",
              severity: "error",
            });
          }
          for (let i = 0; i < node.childCount; i++) {
            walkErrors(node.child(i));
          }
        }
        walkErrors(tree.rootNode);
        return diags;
      } catch {
        return [];
      }
    },

    getDefinition() { return null; },
  };

  // Register adapters
  adapters.swift = SwiftAdapter;
  adapters.typescript = TypeScriptAdapter;
  adapters.c = ClangdAdapter;
  adapters.shell = BashAdapter;

  // ── UI Controller ──
  function loadScript(src) {
    return new Promise((resolve, reject) => {
      if (document.querySelector(`script[src="${src}"]`)) {
        resolve();
        return;
      }
      const s = document.createElement("script");
      s.src = src;
      s.onload = resolve;
      s.onerror = reject;
      document.head.appendChild(s);
    });
  }

  async function initEditorLSP(editor) {
    const lang = editor.getAttribute("data-language") || "swift";
    const lspEnabled = editor.getAttribute("data-lsp") !== "false";
    if (!lspEnabled) return;

    const adapter = adapters[lang];
    if (!adapter) return;

    try {
      await adapter.init();
    } catch (e) {
      console.warn(`[ScoreLSP] Failed to init ${lang} adapter:`, e);
      return;
    }

    const textarea = editor.querySelector('[data-part="input"]');
    const autocompleteEl = editor.querySelector('[data-part="autocomplete"]');
    const diagnosticsEl = editor.querySelector('[data-part="diagnostics"]');
    const hoverEl = editor.querySelector('[data-part="hover"]');

    if (!textarea) return;

    let completionItems = [];
    let selectedIndex = -1;
    let debounceTimer = null;

    // Diagnostics on change (debounced)
    function updateDiagnostics() {
      const source = textarea.value || "";
      const diags = adapter.getDiagnostics(source);

      if (diagnosticsEl && diags.length > 0) {
        // For now, store diagnostics as data attributes for CSS styling
        editor.setAttribute("data-diagnostics", JSON.stringify(diags.slice(0, 10)));
      } else if (diagnosticsEl) {
        editor.removeAttribute("data-diagnostics");
      }
    }

    // Autocomplete
    function showCompletions() {
      const source = textarea.value || "";
      const pos = textarea.selectionStart;
      const before = source.slice(0, pos);
      const lines = before.split("\n");
      const line = lines.length - 1;
      const col = lines[lines.length - 1].length;

      completionItems = adapter.getCompletions(source, line, col);
      selectedIndex = completionItems.length > 0 ? 0 : -1;

      if (autocompleteEl && completionItems.length > 0) {
        autocompleteEl.innerHTML = completionItems
          .map((item, i) => {
            const selected = i === selectedIndex ? ' data-state="selected"' : "";
            return `<div data-part="option"${selected}>${esc(item.label)}<span style="opacity:0.5;margin-left:0.5rem">${esc(item.detail || "")}</span></div>`;
          })
          .join("");
        autocompleteEl.setAttribute("data-state", "open");

        // Position near cursor
        const lineHeight = parseFloat(getComputedStyle(textarea).lineHeight) || 20;
        autocompleteEl.style.top = `${(line + 1) * lineHeight + 4}px`;
        autocompleteEl.style.left = `${col * 8}px`; // Approximate character width
      } else if (autocompleteEl) {
        autocompleteEl.setAttribute("data-state", "closed");
      }
    }

    function hideCompletions() {
      if (autocompleteEl) {
        autocompleteEl.setAttribute("data-state", "closed");
      }
      completionItems = [];
      selectedIndex = -1;
    }

    function acceptCompletion() {
      if (selectedIndex < 0 || selectedIndex >= completionItems.length) return;
      const item = completionItems[selectedIndex];
      const source = textarea.value || "";
      const pos = textarea.selectionStart;
      const before = source.slice(0, pos);
      const match = before.match(/[a-zA-Z_]\w*$/);
      const prefixLen = match ? match[0].length : 0;

      textarea.value =
        source.slice(0, pos - prefixLen) + item.label + source.slice(pos);
      textarea.selectionStart = textarea.selectionEnd = pos - prefixLen + item.label.length;
      hideCompletions();

      // Trigger highlight update
      textarea.dispatchEvent(new Event("input", { bubbles: true }));
    }

    function esc(text) {
      return text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
    }

    // Keyboard handling for autocomplete
    textarea.addEventListener("keydown", (e) => {
      if (autocompleteEl?.getAttribute("data-state") === "open") {
        if (e.key === "ArrowDown") {
          e.preventDefault();
          selectedIndex = Math.min(selectedIndex + 1, completionItems.length - 1);
          updateAutocompleteSelection();
        } else if (e.key === "ArrowUp") {
          e.preventDefault();
          selectedIndex = Math.max(selectedIndex - 1, 0);
          updateAutocompleteSelection();
        } else if (e.key === "Enter" || e.key === "Tab") {
          if (selectedIndex >= 0) {
            e.preventDefault();
            acceptCompletion();
          }
        } else if (e.key === "Escape") {
          e.preventDefault();
          hideCompletions();
        }
      }

      // Ctrl+Space to trigger completions
      if ((e.ctrlKey || e.metaKey) && e.key === " ") {
        e.preventDefault();
        showCompletions();
      }
    });

    function updateAutocompleteSelection() {
      if (!autocompleteEl) return;
      const options = autocompleteEl.querySelectorAll('[data-part="option"]');
      options.forEach((opt, i) => {
        opt.setAttribute("data-state", i === selectedIndex ? "selected" : "");
      });
    }

    // Input handler: debounced diagnostics + completions
    textarea.addEventListener("input", () => {
      clearTimeout(debounceTimer);
      debounceTimer = setTimeout(() => {
        updateDiagnostics();
      }, 500);

      // Show completions on typing
      const source = textarea.value || "";
      const pos = textarea.selectionStart;
      const charBefore = source[pos - 1];
      if (charBefore && /[a-zA-Z_.]/.test(charBefore)) {
        showCompletions();
      } else {
        hideCompletions();
      }
    });

    // Hover on Ctrl/Cmd + mousemove
    if (hoverEl) {
      editor.addEventListener("mousemove", (e) => {
        if (!e.ctrlKey && !e.metaKey) {
          hoverEl.setAttribute("data-state", "closed");
          return;
        }
        // Approximate position from mouse coordinates
        const rect = textarea.getBoundingClientRect();
        const lineHeight = parseFloat(getComputedStyle(textarea).lineHeight) || 20;
        const charWidth = 8; // Approximate
        const line = Math.floor((e.clientY - rect.top + textarea.scrollTop) / lineHeight);
        const col = Math.floor((e.clientX - rect.left + textarea.scrollLeft) / charWidth);

        const info = adapter.getHover(textarea.value || "", line, col);
        if (info) {
          hoverEl.textContent = info;
          hoverEl.style.top = `${e.clientY - rect.top + 16}px`;
          hoverEl.style.left = `${e.clientX - rect.left}px`;
          hoverEl.setAttribute("data-state", "open");
        } else {
          hoverEl.setAttribute("data-state", "closed");
        }
      });
    }

    // Go-to-definition on Ctrl/Cmd + click
    textarea.addEventListener("click", (e) => {
      if (!e.ctrlKey && !e.metaKey) return;
      const source = textarea.value || "";
      const pos = textarea.selectionStart;
      const before = source.slice(0, pos);
      const lines = before.split("\n");
      const line = lines.length - 1;
      const col = lines[lines.length - 1].length;

      const def = adapter.getDefinition(source, line, col);
      if (def) {
        // Scroll to definition line
        const allLines = source.split("\n");
        let offset = 0;
        for (let i = 0; i < def.line && i < allLines.length; i++) {
          offset += allLines[i].length + 1;
        }
        offset += def.col;
        textarea.selectionStart = textarea.selectionEnd = offset;
        textarea.focus();

        // Scroll into view
        const lineHeight = parseFloat(getComputedStyle(textarea).lineHeight) || 20;
        textarea.scrollTop = def.line * lineHeight - textarea.clientHeight / 2;
      }
    });

    // Initial diagnostics
    updateDiagnostics();

    editor._scoreLSP = { adapter, lang };
  }

  // Initialize all editors
  function initAll() {
    const editors = document.querySelectorAll('[data-component="editor"]');
    editors.forEach((editor) => {
      if (!editor._scoreLSP) {
        initEditorLSP(editor);
      }
    });
  }

  // Auto-init after score-editor.js has run
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", () => {
      // Small delay to let score-editor.js initialize first
      setTimeout(initAll, 100);
    });
  } else {
    setTimeout(initAll, 100);
  }

  // Expose API
  globalThis.ScoreLSP = {
    init: initAll,
    initEditor: initEditorLSP,
    adapters,
  };
})();
