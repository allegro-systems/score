/**
 * Score Dev Tools Panel
 *
 * A self-contained floating panel injected in development mode only.
 * Renders inside a Shadow DOM to avoid style conflicts with the page.
 * Colours follow the Allegro handbook design system using OKLCH values.
 *
 * Features:
 * - Collapsed: small "S" badge in the bottom-right corner
 * - Expanded: two tabs — State (live signal values) and Components (source links)
 */
;(function () {
  "use strict";

  // ── Host element + Shadow DOM ──────────────────────────────────────
  var host = document.createElement("div");
  host.id = "score-devtools-host";
  host.style.cssText = "position:fixed;bottom:16px;right:16px;z-index:2147483647;font-family:ui-sans-serif,system-ui,-apple-system,BlinkMacSystemFont,sans-serif;font-size:13px;";
  document.body.appendChild(host);

  var shadow = host.attachShadow({ mode: "open" });

  // ── Styles ─────────────────────────────────────────────────────────
  var style = document.createElement("style");
  // Allegro handbook OKLCH tokens
  var surface = "oklch(0.17 0.014 240)";
  var surfaceEl = "oklch(0.22 0.012 240)";
  var text = "oklch(0.93 0.004 240)";
  var border = "oklch(0.26 0.012 240)";
  var accent = "oklch(0.68 0.13 215)";
  var muted = "oklch(0.58 0.006 240)";
  var destructive = "oklch(0.65 0.2 25)";
  var mono = "ui-monospace,SFMono-Regular,Menlo,Monaco,Consolas,monospace";

  style.textContent = [
    ":host{all:initial}",
    ".badge{width:32px;height:32px;border-radius:8px;background:" + surface + ";color:" + accent + ";display:flex;align-items:center;justify-content:center;cursor:pointer;font-weight:700;font-size:16px;box-shadow:0 2px 8px oklch(0 0 0/.3);transition:transform .15s ease}",
    ".badge:hover{transform:scale(1.1)}",
    ".panel{display:none;width:320px;max-height:420px;background:" + surface + ";color:" + text + ";border-radius:8px;box-shadow:0 4px 24px oklch(0 0 0/.4);overflow:hidden;flex-direction:column}",
    ".panel.open{display:flex}",
    ".tabs{display:flex;border-bottom:1px solid " + border + "}",
    ".tab{flex:1;padding:8px 0;text-align:center;cursor:pointer;color:" + muted + ";font-size:12px;font-weight:600;border:none;background:none;transition:color .15s}",
    ".tab.active{color:" + accent + ";box-shadow:inset 0 -2px 0 " + accent + "}",
    ".tab-body{flex:1;overflow-y:auto;padding:10px 12px}",
    ".row{display:flex;justify-content:space-between;padding:4px 0;border-bottom:1px solid " + border + ";font-size:12px}",
    ".row:last-child{border-bottom:none}",
    ".label{color:" + muted + "}",
    ".value{color:" + accent + ";font-family:" + mono + ";max-width:160px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap}",
    ".comp{padding:6px 0;border-bottom:1px solid " + border + "}",
    ".comp:last-child{border-bottom:none}",
    ".comp-name{font-weight:600;color:" + accent + ";font-size:12px}",
    ".comp-file{font-size:11px;color:" + muted + ";text-decoration:none;display:block;margin-top:2px}",
    ".comp-file:hover{color:" + accent + "}",
    ".highlight-btn{background:none;border:1px solid " + border + ";color:" + muted + ";border-radius:4px;padding:2px 6px;font-size:10px;cursor:pointer;margin-top:4px}",
    ".highlight-btn:hover{border-color:" + destructive + ";color:" + destructive + "}",
    ".empty{color:" + muted + ";font-style:italic;font-size:12px;padding:12px 0}",
  ].join("\n");
  shadow.appendChild(style);

  // ── Badge ──────────────────────────────────────────────────────────
  var badge = document.createElement("div");
  badge.className = "badge";
  badge.textContent = "S";
  badge.title = "Score Dev Tools";
  shadow.appendChild(badge);

  // ── Panel ──────────────────────────────────────────────────────────
  var panel = document.createElement("div");
  panel.className = "panel";

  var tabs = document.createElement("div");
  tabs.className = "tabs";

  var stateTab = document.createElement("button");
  stateTab.className = "tab active";
  stateTab.textContent = "State";

  var compTab = document.createElement("button");
  compTab.className = "tab";
  compTab.textContent = "Components";

  tabs.appendChild(stateTab);
  tabs.appendChild(compTab);
  panel.appendChild(tabs);

  var tabBody = document.createElement("div");
  tabBody.className = "tab-body";
  panel.appendChild(tabBody);

  shadow.appendChild(panel);

  // ── State ──────────────────────────────────────────────────────────
  var expanded = false;
  var activeTab = "state";

  badge.addEventListener("click", function () {
    expanded = !expanded;
    panel.classList.toggle("open", expanded);
    badge.style.display = expanded ? "none" : "flex";
    if (expanded) renderTab();
  });

  stateTab.addEventListener("click", function () {
    activeTab = "state";
    stateTab.classList.add("active");
    compTab.classList.remove("active");
    renderTab();
  });

  compTab.addEventListener("click", function () {
    activeTab = "components";
    compTab.classList.add("active");
    stateTab.classList.remove("active");
    renderTab();
  });

  // Close on click outside
  document.addEventListener("click", function (e) {
    if (expanded && !host.contains(e.target)) {
      expanded = false;
      panel.classList.remove("open");
      badge.style.display = "flex";
    }
  });

  // ── Tab Rendering ──────────────────────────────────────────────────

  function renderTab() {
    tabBody.innerHTML = "";
    if (activeTab === "state") renderStateTab();
    else renderComponentsTab();
  }

  function renderStateTab() {
    var meta = window.__SCORE_DEV_META__;
    if (!meta || (!meta.states.length && !meta.computeds.length)) {
      tabBody.innerHTML = '<div class="empty">No reactive state on this page.</div>';
      return;
    }

    var Score = window.Score;
    if (!Score) {
      tabBody.innerHTML = '<div class="empty">Score runtime not loaded.</div>';
      return;
    }

    // Render state entries
    meta.states.forEach(function (name) {
      var row = document.createElement("div");
      row.className = "row";

      var label = document.createElement("span");
      label.className = "label";
      label.textContent = "@State " + name;

      var val = document.createElement("span");
      val.className = "value";

      // Try to read from global scope (emitted by JSEmitter)
      try {
        var signal = eval(name);
        if (signal && typeof signal.get === "function") {
          val.textContent = String(signal.get());
          // Set up live updates via effect
          Score.effect(function () {
            val.textContent = String(signal.get());
          });
        } else {
          val.textContent = String(signal);
        }
      } catch (e) {
        val.textContent = "(unavailable)";
      }

      row.appendChild(label);
      row.appendChild(val);
      tabBody.appendChild(row);
    });

    meta.computeds.forEach(function (name) {
      var row = document.createElement("div");
      row.className = "row";

      var label = document.createElement("span");
      label.className = "label";
      label.textContent = "@Computed " + name;

      var val = document.createElement("span");
      val.className = "value";

      try {
        var signal = eval(name);
        if (signal && typeof signal.get === "function") {
          val.textContent = String(signal.get());
          Score.effect(function () {
            val.textContent = String(signal.get());
          });
        } else {
          val.textContent = String(signal);
        }
      } catch (e) {
        val.textContent = "(unavailable)";
      }

      row.appendChild(label);
      row.appendChild(val);
      tabBody.appendChild(row);
    });
  }

  function renderComponentsTab() {
    var components = document.querySelectorAll("[data-score-component]");
    if (!components.length) {
      tabBody.innerHTML = '<div class="empty">No annotated components found.</div>';
      return;
    }

    components.forEach(function (el) {
      var name = el.getAttribute("data-score-component");
      var file = el.getAttribute("data-score-file") || "";
      var line = el.getAttribute("data-score-line") || "1";

      var comp = document.createElement("div");
      comp.className = "comp";

      var nameEl = document.createElement("div");
      nameEl.className = "comp-name";
      nameEl.textContent = name;
      comp.appendChild(nameEl);

      if (file) {
        var link = document.createElement("a");
        link.className = "comp-file";
        link.href = "vscode://file/" + file + ":" + line;
        link.textContent = file + ":" + line;
        comp.appendChild(link);
      }

      var btn = document.createElement("button");
      btn.className = "highlight-btn";
      btn.textContent = "Highlight";
      btn.addEventListener("click", function () {
        el.style.outline = "2px solid oklch(0.65 0.2 25)";
        el.style.outlineOffset = "2px";
        setTimeout(function () {
          el.style.outline = "";
          el.style.outlineOffset = "";
        }, 1500);
      });
      comp.appendChild(btn);

      tabBody.appendChild(comp);
    });
  }

  // Initial render if expanded
  if (expanded) renderTab();
})();
