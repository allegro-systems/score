/// Injects development-time annotations and scripts into rendered HTML.
public struct DevToolsInjector: Sendable {

    private init() {}

    /// Returns a `<script>` tag that loads the Score dev tools overlay,
    /// or an empty string in production.
    public static func scriptTag(environment: Environment) -> String {
        guard environment == .development else { return "" }
        return "<script type=\"module\" src=\"/static/score-devtools.js\"></script>"
    }

    /// Returns an inline `<script>` that sets up `window.__SCORE_DEV__` with
    /// comprehensive metadata about the page's reactive state, or an empty
    /// string in production.
    public static func metadataScript(
        pageStates: [JSEmitter.StateInfo],
        pageComputeds: [JSEmitter.ComputedInfo],
        pageActions: [JSEmitter.ActionInfo],
        componentScopes: [JSEmitter.ComponentScope],
        environment: Environment
    ) -> String {
        guard environment == .development else { return "" }

        let hasContent =
            !pageStates.isEmpty || !pageComputeds.isEmpty
            || !pageActions.isEmpty || !componentScopes.isEmpty
        guard hasContent else { return "" }

        var js = "<script>\nwindow.__SCORE_DEV__=window.__SCORE_DEV__||{};\n"
        js.append("Object.assign(window.__SCORE_DEV__,{")
        js.append("page:{")
        js.append("states:[\(pageStates.map { stateJSON($0) }.joined(separator: ","))],")
        js.append("computeds:[\(pageComputeds.map { computedJSON($0) }.joined(separator: ","))],")
        js.append("actions:[\(pageActions.map { actionJSON($0) }.joined(separator: ","))]")
        js.append("},")
        js.append("elements:[\(componentScopes.map { componentJSON($0) }.joined(separator: ","))]")
        js.append("});\n")
        js.append("window.__SCORE_DEV__.signals=window.__SCORE_DEV__.signals||{};\n")
        js.append("</script>")
        return js
    }

    /// The complete client-side dev tools overlay JavaScript.
    ///
    /// Served at `/static/score-devtools.js` in development mode. Uses a
    /// custom element with Shadow DOM to isolate its styles from the page.
    public static let clientScript: String = #"""
        (()=>{
        if(document.querySelector('#score-devtools-root'))return;
        const D=window.__SCORE_DEV__||{page:{states:[],computeds:[],actions:[]},elements:[],signals:{}};
        const root=document.createElement('div');
        root.id='score-devtools-root';
        const shadow=root.attachShadow({mode:'open'});

        const S=`
        *{margin:0;padding:0;box-sizing:border-box}
        :host{font-family:-apple-system,BlinkMacSystemFont,'SF Mono',Menlo,monospace;font-size:12px;color:#e0e0e0;position:fixed;bottom:16px;left:50%;transform:translateX(-50%);z-index:2147483647;pointer-events:none}
        .pill{pointer-events:auto;display:flex;align-items:center;gap:10px;padding:6px 16px;background:rgba(24,24,27,.92);backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);border:1px solid rgba(255,255,255,.08);border-radius:20px;cursor:pointer;user-select:none;transition:all .2s ease;box-shadow:0 4px 24px rgba(0,0,0,.4)}
        .pill:hover{background:rgba(30,30,34,.96);border-color:rgba(255,255,255,.14);box-shadow:0 6px 32px rgba(0,0,0,.5)}
        .pill-logo{color:#569cd6;font-weight:600;font-size:12px;letter-spacing:-.2px;white-space:nowrap}
        .pill-sep{width:1px;height:14px;background:rgba(255,255,255,.1)}
        .pill-info{color:rgba(255,255,255,.45);font-size:11px;white-space:nowrap}
        .pill-path{color:rgba(255,255,255,.3);font-size:10px;white-space:nowrap}
        .panel{pointer-events:auto;display:none;position:fixed;bottom:60px;left:50%;transform:translateX(-50%);width:580px;max-width:calc(100vw - 32px);height:320px;background:rgba(24,24,27,.96);backdrop-filter:blur(16px);-webkit-backdrop-filter:blur(16px);border:1px solid rgba(255,255,255,.08);border-radius:12px;flex-direction:column;overflow:hidden;box-shadow:0 8px 48px rgba(0,0,0,.5)}
        .panel.open{display:flex}
        .resize-handle{height:4px;background:transparent;cursor:ns-resize;flex-shrink:0;border-radius:12px 12px 0 0}
        .resize-handle:hover{background:rgba(86,156,214,.4)}
        .panel-header{display:flex;align-items:center;justify-content:space-between;padding:0 14px;height:36px;border-bottom:1px solid rgba(255,255,255,.06);flex-shrink:0}
        .tabs{display:flex;gap:0}
        .tab{background:none;border:none;color:rgba(255,255,255,.35);font:inherit;padding:8px 12px;cursor:pointer;border-bottom:2px solid transparent;transition:color .15s,border-color .15s;font-size:11px;font-weight:500;letter-spacing:.3px}
        .tab:hover{color:rgba(255,255,255,.7)}
        .tab.active{color:#569cd6;border-bottom-color:#569cd6}
        .close-btn{background:none;border:none;color:rgba(255,255,255,.3);font:inherit;cursor:pointer;padding:4px 6px;border-radius:6px;font-size:14px;line-height:1;transition:all .15s}
        .close-btn:hover{background:rgba(255,255,255,.06);color:rgba(255,255,255,.7)}
        .panel-body{flex:1;overflow:auto;padding:10px 14px}
        .panel-body::-webkit-scrollbar{width:5px}
        .panel-body::-webkit-scrollbar-track{background:transparent}
        .panel-body::-webkit-scrollbar-thumb{background:rgba(255,255,255,.1);border-radius:3px}
        .tree-item{padding:4px 6px;display:flex;align-items:center;cursor:pointer;border-radius:6px;transition:background .1s}
        .tree-item:hover{background:rgba(255,255,255,.04)}
        .tree-name{color:#4ec9b0;font-size:12px}
        .tree-item[data-stateful] .tree-name{color:#569cd6}
        .tree-badge{font-size:9px;padding:2px 6px;border-radius:4px;margin-left:8px;background:rgba(255,255,255,.05);color:rgba(255,255,255,.3);text-transform:uppercase;letter-spacing:.4px;font-weight:500}
        .tree-badge.stateful{background:rgba(86,156,214,.15);color:#9cdcfe}
        .tree-source{color:rgba(255,255,255,.25);font-size:10px;margin-left:auto;padding-left:12px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis;max-width:240px;direction:rtl;text-align:left;cursor:pointer;border-radius:3px;padding:1px 4px;transition:all .15s;text-decoration:none}
        .tree-source:hover{color:rgba(255,255,255,.5);background:rgba(255,255,255,.06)}
        .state-table{width:100%;border-collapse:collapse;margin-bottom:12px}
        .state-table th{text-align:left;color:rgba(255,255,255,.3);font-weight:500;padding:4px 8px 4px 0;border-bottom:1px solid rgba(255,255,255,.06);font-size:10px;text-transform:uppercase;letter-spacing:.5px}
        .state-table td{padding:5px 8px 5px 0;border-bottom:1px solid rgba(255,255,255,.03);vertical-align:top}
        .state-name{color:#9cdcfe}
        .state-value{color:#ce9178;font-family:inherit;word-break:break-all}
        .state-scope{color:rgba(255,255,255,.3);font-size:11px}
        .state-persisted{color:#4ec9b0;font-size:11px}
        .section-label{color:rgba(255,255,255,.25);font-size:10px;text-transform:uppercase;letter-spacing:1px;padding:10px 0 4px;border-bottom:1px solid rgba(255,255,255,.06);margin-bottom:4px;font-weight:500}
        .action-item{padding:4px 0;display:flex;align-items:baseline;gap:8px}
        .action-name{color:#dcdcaa}
        .action-body{color:rgba(255,255,255,.3);font-size:11px;overflow:hidden;text-overflow:ellipsis;white-space:nowrap;max-width:320px}
        .highlight-overlay{position:fixed;pointer-events:none;z-index:2147483646;border:2px solid #569cd6;background:rgba(86,156,214,.08);border-radius:3px;transition:all .1s ease-out}
        .empty{color:rgba(255,255,255,.2);font-style:italic;padding:12px 0}
        `;

        let expanded=false;
        let panelHeight=320;
        let activeTab='components';

        shadow.innerHTML=`<style>${S}</style>
        <div class="panel" id="panel">
          <div class="resize-handle" id="resize"></div>
          <div class="panel-header">
            <div class="tabs" id="tabs">
              <button class="tab active" data-tab="components">Components</button>
              <button class="tab" data-tab="state">State</button>
            </div>
            <button class="close-btn" id="close">&times;</button>
          </div>
          <div class="panel-body" id="body"></div>
        </div>
        <div class="pill" id="pill">
          <span class="pill-logo">Score</span>
          <span class="pill-sep"></span>
          <span class="pill-info" id="pill-info"></span>
          <span class="pill-path" id="pill-path"></span>
        </div>`;

        const $=s=>shadow.querySelector(s);
        const pill=$('#pill');
        const panel=$('#panel');
        const body=$('#body');
        const pillInfo=$('#pill-info');
        const pillPath=$('#pill-path');

        const overlay=document.createElement('div');
        overlay.className='highlight-overlay';
        overlay.style.display='none';
        shadow.appendChild(overlay);

        pillPath.textContent=location.pathname;

        function toggle(){
          expanded=!expanded;
          panel.classList.toggle('open',expanded);
          if(expanded)render();
        }

        pill.addEventListener('click',toggle);
        $('#close').addEventListener('click',(e)=>{e.stopPropagation();expanded=false;panel.classList.remove('open')});

        $('#tabs').addEventListener('click',(e)=>{
          const tab=e.target.dataset?.tab;
          if(!tab)return;
          activeTab=tab;
          shadow.querySelectorAll('.tab').forEach(t=>t.classList.toggle('active',t.dataset.tab===tab));
          render();
        });

        let resizing=false;
        $('#resize').addEventListener('mousedown',(e)=>{
          e.preventDefault();
          resizing=true;
          const startY=e.clientY;
          const startH=panelHeight;
          function onMove(ev){
            panelHeight=Math.max(120,Math.min(window.innerHeight-80,startH+(startY-ev.clientY)));
            panel.style.height=panelHeight+'px';
          }
          function onUp(){resizing=false;document.removeEventListener('mousemove',onMove);document.removeEventListener('mouseup',onUp)}
          document.addEventListener('mousemove',onMove);
          document.addEventListener('mouseup',onUp);
        });

        function getComponents(){
          const els=document.querySelectorAll('[data-score-component]');
          const items=[];
          for(const el of els){
            let depth=0;
            let p=el.parentElement;
            while(p){
              if(p.hasAttribute&&p.hasAttribute('data-score-component'))depth++;
              p=p.parentElement;
            }
            const src=el.getAttribute('data-source')||el.querySelector('[data-source]')?.getAttribute('data-source')||'';
            const srcPath=el.getAttribute('data-source-path')||el.querySelector('[data-source-path]')?.getAttribute('data-source-path')||'';
            items.push({el,name:el.dataset.scoreComponent,isStateful:el.hasAttribute('data-score-stateful'),depth,source:src,sourcePath:srcPath});
          }
          return items;
        }

        function renderComponents(){
          const items=getComponents();
          pillInfo.textContent=items.length+' component'+(items.length===1?'':'s');
          if(!items.length)return '<div class="empty">No components found on this page.</div>';
          let h='';
          for(const item of items){
            const pad=item.depth?` style="padding-left:${item.depth*16}px"`:'';
            const badge=item.isStateful?'<span class="tree-badge stateful">Stateful</span>':'';
            const srcLabel=item.source?formatSource(item.source,item.sourcePath):'';
            h+=`<div class="tree-item" data-idx="${items.indexOf(item)}"${item.isStateful?' data-stateful':''}${pad}><span class="tree-name">${esc(item.name)}</span>${badge}${srcLabel}</div>`;
          }
          return h;
        }

        function renderState(){
          const page=D.page||{states:[],computeds:[],actions:[]};
          const elements=D.elements||[];
          const signals=D.signals||{};
          let h='';

          const allStates=[...page.states.map(s=>({...s,scope:'Page'}))];
          for(const el of elements){
            for(const s of(el.states||[]))allStates.push({...s,scope:el.name});
          }
          const allComputeds=[...page.computeds.map(c=>({...c,scope:'Page'}))];
          for(const el of elements){
            for(const c of(el.computeds||[]))allComputeds.push({...c,scope:el.name});
          }
          const allActions=[...page.actions.map(a=>({...a,scope:'Page'}))];
          for(const el of elements){
            for(const a of(el.actions||[]))allActions.push({...a,scope:el.name});
          }

          if(allStates.length){
            h+='<div class="section-label">State</div>';
            h+='<table class="state-table"><thead><tr><th>Name</th><th>Value</th><th>Initial</th><th>Scope</th><th>Persisted</th></tr></thead><tbody>';
            for(const s of allStates){
              const sig=signals[s.name];
              const val=sig?formatValue(sig.get()):'—';
              const persisted=s.storageKey?'<span class="state-persisted">'+esc(s.storageKey)+'</span>':'—';
              h+=`<tr><td class="state-name">${esc(s.name)}</td><td class="state-value" data-signal="${esc(s.name)}">${val}</td><td class="state-value">${esc(s.initial||'')}</td><td class="state-scope">${esc(s.scope)}</td><td>${persisted}</td></tr>`;
            }
            h+='</tbody></table>';
          }

          if(allComputeds.length){
            h+='<div class="section-label">Computed</div>';
            h+='<table class="state-table"><thead><tr><th>Name</th><th>Value</th><th>Expression</th><th>Scope</th></tr></thead><tbody>';
            for(const c of allComputeds){
              const sig=signals[c.name];
              const val=sig?formatValue(sig.get()):'—';
              h+=`<tr><td class="state-name">${esc(c.name)}</td><td class="state-value" data-signal="${esc(c.name)}">${val}</td><td class="action-body">${esc(c.body||'')}</td><td class="state-scope">${esc(c.scope)}</td></tr>`;
            }
            h+='</tbody></table>';
          }

          if(allActions.length){
            h+='<div class="section-label">Actions</div>';
            for(const a of allActions){
              h+=`<div class="action-item"><span class="action-name">${esc(a.name)}()</span><span class="action-body">${esc(a.body||'')}</span><span class="state-scope">${esc(a.scope)}</span></div>`;
            }
          }

          if(!h)h='<div class="empty">No reactive state on this page.</div>';
          return h;
        }

        const editorScheme=localStorage.getItem('score-editor')||'vscode';

        function formatSource(src,srcPath){
          const parts=src.split(':');
          if(parts.length<2)return '';
          const file=parts[0].split('/').pop();
          const line=parts[1];
          if(!srcPath)return `<span class="tree-source">${esc(file)}:${esc(line)}</span>`;
          const pp=srcPath.split(':');
          const href=editorScheme+'://file/'+pp[0]+':'+(pp[1]||'1')+':'+(pp[2]||'1');
          return `<a class="tree-source" href="${esc(href)}">${esc(file)}:${esc(line)}</a>`;
        }

        function render(){
          if(!expanded)return;
          body.innerHTML=activeTab==='components'?renderComponents():renderState();
          if(activeTab==='components')bindTreeHover();
        }

        function bindTreeHover(){
          const items=getComponents();
          body.querySelectorAll('.tree-item').forEach(el=>{
            const idx=parseInt(el.dataset.idx);
            el.addEventListener('mouseenter',()=>highlightElement(items[idx]?.el));
            el.addEventListener('mouseleave',()=>{overlay.style.display='none'});
          });
          body.querySelectorAll('a.tree-source').forEach(el=>{
            el.addEventListener('click',(e)=>{e.stopPropagation()});
          });
        }

        function highlightElement(el){
          if(!el){overlay.style.display='none';return}
          const r=el.getBoundingClientRect();
          if(r.width===0&&r.height===0){overlay.style.display='none';return}
          overlay.style.display='block';
          overlay.style.top=r.top+'px';
          overlay.style.left=r.left+'px';
          overlay.style.width=r.width+'px';
          overlay.style.height=r.height+'px';
        }

        function formatValue(v){
          if(v===null)return'<i>null</i>';
          if(v===undefined)return'<i>undefined</i>';
          if(typeof v==='string')return'"'+esc(v)+'"';
          if(typeof v==='boolean')return v?'true':'false';
          return esc(String(v));
        }

        function esc(s){
          return String(s).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
        }

        let pollTimer=null;
        function startPoll(){
          if(pollTimer)return;
          pollTimer=setInterval(()=>{
            if(!expanded||activeTab!=='state')return;
            const signals=D.signals||{};
            body.querySelectorAll('[data-signal]').forEach(td=>{
              const sig=signals[td.dataset.signal];
              if(sig)td.innerHTML=formatValue(sig.get());
            });
          },300);
        }

        document.body.appendChild(root);
        const items=getComponents();
        pillInfo.textContent=items.length+' component'+(items.length===1?'':'s');
        startPoll();
        })();
        """#

    private static func stateJSON(_ s: JSEmitter.StateInfo) -> String {
        "{name:\"\(jsEscape(s.name))\",initial:\"\(jsEscape(s.initialValue))\",storageKey:\"\(jsEscape(s.storageKey))\",isTheme:\(s.isTheme)}"
    }

    private static func computedJSON(_ c: JSEmitter.ComputedInfo) -> String {
        "{name:\"\(jsEscape(c.name))\",body:\"\(jsEscape(c.body))\"}"
    }

    private static func actionJSON(_ a: JSEmitter.ActionInfo) -> String {
        "{name:\"\(jsEscape(a.name))\",body:\"\(jsEscape(a.body))\"}"
    }

    private static func componentJSON(_ e: JSEmitter.ComponentScope) -> String {
        var json = "{name:\"\(jsEscape(e.name))\","
        json += "states:[\(e.states.map { stateJSON($0) }.joined(separator: ","))],"
        json += "computeds:[\(e.computeds.map { computedJSON($0) }.joined(separator: ","))],"
        json += "actions:[\(e.actions.map { actionJSON($0) }.joined(separator: ","))]}"
        return json
    }

    private static func jsEscape(_ s: String) -> String {
        s.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
    }
}
