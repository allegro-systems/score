/**
 * Score Editor — TreeSitter-powered syntax highlighting for [data-component="editor"]
 *
 * Initializes web-tree-sitter, loads language grammar WASMs on demand,
 * and renders highlighted tokens into the overlay <pre><code> element.
 * Syncs scroll position between the transparent <textarea> and the overlay.
 */
(function () {
  "use strict";

  const SCORE_PATH = "/_score/";

  // TreeSitter node type → CSS class mapping per language
  const HIGHLIGHT_MAP = {
    // Common across languages
    comment: "ts-comment",
    line_comment: "ts-comment",
    block_comment: "ts-comment",
    string_literal: "ts-string",
    string: "ts-string",
    template_string: "ts-string",
    string_content: "ts-string",
    number: "ts-number",
    integer_literal: "ts-number",
    float_literal: "ts-number",
    true: "ts-number",
    false: "ts-number",
    boolean: "ts-number",
    nil: "ts-number",
    null: "ts-number",
    type_identifier: "ts-type",
    primitive_type: "ts-type",
    predefined_type: "ts-type",
    property_identifier: "ts-property",
    field_identifier: "ts-property",
    simple_identifier: "ts-variable",
    identifier: "ts-variable",

    // Keywords
    // (Matched by checking against keyword sets per language)
  };

  // Language-specific keyword sets
  const KEYWORDS = {
    swift: new Set([
      "import", "func", "var", "let", "if", "else", "guard", "return",
      "struct", "class", "enum", "protocol", "extension", "for", "while",
      "switch", "case", "default", "break", "continue", "throw", "throws",
      "try", "catch", "async", "await", "public", "private", "internal",
      "open", "fileprivate", "static", "override", "init", "deinit",
      "self", "Self", "super", "where", "in", "is", "as", "typealias",
      "associatedtype", "some", "any", "true", "false", "nil",
    ]),
    typescript: new Set([
      "import", "export", "from", "function", "const", "let", "var",
      "if", "else", "return", "class", "interface", "type", "enum",
      "extends", "implements", "for", "while", "do", "switch", "case",
      "default", "break", "continue", "throw", "try", "catch", "finally",
      "async", "await", "new", "this", "super", "typeof", "instanceof",
      "void", "null", "undefined", "true", "false", "in", "of", "as",
      "readonly", "private", "public", "protected", "static", "abstract",
      "declare", "namespace", "module",
    ]),
    c: new Set([
      "auto", "break", "case", "char", "const", "continue", "default",
      "do", "double", "else", "enum", "extern", "float", "for", "goto",
      "if", "inline", "int", "long", "register", "restrict", "return",
      "short", "signed", "sizeof", "static", "struct", "switch",
      "typedef", "union", "unsigned", "void", "volatile", "while",
      "#include", "#define", "#ifdef", "#ifndef", "#endif", "#if",
      "#else", "#elif", "#pragma", "NULL",
    ]),
    shell: new Set([
      "if", "then", "else", "elif", "fi", "for", "while", "do", "done",
      "case", "esac", "in", "function", "return", "exit", "export",
      "local", "readonly", "declare", "typeset", "unset", "shift",
      "set", "source", "eval", "exec", "trap", "true", "false",
    ]),
  };

  let Parser = null;
  const parsers = {}; // lang -> Parser instance
  const trees = {};   // editorId -> Tree instance

  async function initTreeSitter() {
    if (Parser) return;
    // web-tree-sitter exposes TreeSitter on globalThis after loading
    if (!globalThis.TreeSitter) {
      // Load the web-tree-sitter JS
      await loadScript(SCORE_PATH + "web-tree-sitter.js");
    }
    const TS = globalThis.TreeSitter;
    await TS.init({
      locateFile: (file) => SCORE_PATH + file,
    });
    Parser = TS;
  }

  async function getParser(lang) {
    if (parsers[lang]) return parsers[lang];
    await initTreeSitter();
    const parser = new Parser();
    const wasmFile = lang === "shell" ? "tree-sitter-bash.wasm" : `tree-sitter-${lang}.wasm`;
    const langGrammar = await Parser.Language.load(SCORE_PATH + wasmFile);
    parser.setLanguage(langGrammar);
    parsers[lang] = parser;
    return parser;
  }

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

  // Escape HTML entities
  function esc(text) {
    return text
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;");
  }

  // Walk the AST and produce highlighted HTML
  function highlightTree(tree, source, lang) {
    const root = tree.rootNode;
    const keywords = KEYWORDS[lang] || new Set();
    let html = "";
    let lastIndex = 0;

    function visit(node) {
      // Leaf nodes get highlighted
      if (node.childCount === 0) {
        const start = node.startIndex;
        const end = node.endIndex;

        // Emit any text before this node (whitespace, etc.)
        if (start > lastIndex) {
          html += esc(source.slice(lastIndex, start));
        }

        const text = source.slice(start, end);
        const type = node.type;

        let cls = HIGHLIGHT_MAP[type] || null;

        // Check if it's a keyword
        if (!cls && keywords.has(text)) {
          cls = "ts-keyword";
        }

        // Function/method call detection
        if (!cls && type === "identifier" || type === "simple_identifier") {
          const parent = node.parent;
          if (parent) {
            const pt = parent.type;
            if (pt === "call_expression" || pt === "function_declaration" ||
                pt === "method_declaration" || pt === "function" ||
                pt === "function_definition" || pt === "command_name") {
              cls = "ts-function";
            }
          }
        }

        if (cls) {
          html += `<span class="${cls}">${esc(text)}</span>`;
        } else {
          html += esc(text);
        }

        lastIndex = end;
      } else {
        // Check for comment/string parent nodes
        const type = node.type;
        if (type === "comment" || type === "line_comment" || type === "block_comment") {
          const start = node.startIndex;
          const end = node.endIndex;
          if (start > lastIndex) {
            html += esc(source.slice(lastIndex, start));
          }
          html += `<span class="ts-comment">${esc(source.slice(start, end))}</span>`;
          lastIndex = end;
          return;
        }
        if (type === "string_literal" || type === "string" || type === "template_string" ||
            type === "raw_string_literal" || type === "interpolated_string_expression") {
          const start = node.startIndex;
          const end = node.endIndex;
          if (start > lastIndex) {
            html += esc(source.slice(lastIndex, start));
          }
          html += `<span class="ts-string">${esc(source.slice(start, end))}</span>`;
          lastIndex = end;
          return;
        }

        for (let i = 0; i < node.childCount; i++) {
          visit(node.child(i));
        }
      }
    }

    visit(root);

    // Remaining text after last node
    if (lastIndex < source.length) {
      html += esc(source.slice(lastIndex));
    }

    return html;
  }

  // Update line numbers
  function updateGutter(editor, lineCount) {
    const gutter = editor.querySelector('[data-part="gutter"]');
    if (!gutter) return;
    const nums = [];
    for (let i = 1; i <= lineCount; i++) {
      nums.push(i);
    }
    gutter.textContent = nums.join("\n");
  }

  // Sync scroll between textarea and highlight overlay
  function syncScroll(textarea, highlight, gutter) {
    if (highlight) {
      highlight.scrollTop = textarea.scrollTop;
      highlight.scrollLeft = textarea.scrollLeft;
    }
    if (gutter) {
      gutter.scrollTop = textarea.scrollTop;
    }
  }

  // Initialize a single editor element
  async function initEditor(editor) {
    const lang = editor.getAttribute("data-language") || "swift";
    const textarea = editor.querySelector('[data-part="input"]');
    const highlightEl = editor.querySelector('[data-part="highlight"]');
    const gutter = editor.querySelector('[data-part="gutter"]');

    if (!textarea || !highlightEl) return;

    const codeEl = highlightEl.querySelector("code") || highlightEl;
    const editorId = textarea.id || `editor-${Math.random().toString(36).slice(2)}`;

    let parser;
    try {
      parser = await getParser(lang);
    } catch (e) {
      console.warn(`[ScoreEditor] Failed to load parser for ${lang}:`, e);
      return;
    }

    function update() {
      const source = textarea.value || "";
      const tree = parser.parse(source, trees[editorId] || null);
      trees[editorId] = tree;

      const highlighted = highlightTree(tree, source, lang);
      // Add trailing newline to keep heights in sync
      codeEl.innerHTML = highlighted + "\n";

      const lineCount = (source.match(/\n/g) || []).length + 1;
      updateGutter(editor, lineCount);
    }

    // Initial render
    update();

    // Listen for input
    textarea.addEventListener("input", update);

    // Sync scrolling
    textarea.addEventListener("scroll", () => {
      syncScroll(textarea, highlightEl, gutter);
    });

    // Tab key support (insert spaces instead of changing focus)
    textarea.addEventListener("keydown", (e) => {
      if (e.key === "Tab") {
        e.preventDefault();
        const start = textarea.selectionStart;
        const end = textarea.selectionEnd;
        const spaces = "  ";
        textarea.value = textarea.value.substring(0, start) + spaces + textarea.value.substring(end);
        textarea.selectionStart = textarea.selectionEnd = start + spaces.length;
        update();
      }
    });

    editor._scoreEditor = { parser, update, lang, editorId };
  }

  // Initialize all editors on the page
  function initAll() {
    const editors = document.querySelectorAll('[data-component="editor"]');
    editors.forEach((editor) => {
      if (!editor._scoreEditor) {
        initEditor(editor);
      }
    });
  }

  // Auto-init on DOM ready
  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", initAll);
  } else {
    initAll();
  }

  // Expose API for programmatic use
  globalThis.ScoreEditor = {
    init: initAll,
    initEditor,
    getParser,
  };
})();
