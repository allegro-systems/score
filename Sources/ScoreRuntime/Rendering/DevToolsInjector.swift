import Foundation

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

        var js = "<script>\nwindow.__SCORE_DEV__=window.__SCORE_DEV__||{};\n"

        let editor = ProcessInfo.processInfo.environment["SCORE_EDITOR"]
        if let editor, !editor.isEmpty {
            js.append("window.__SCORE_DEV__.editor=\"\(jsEscape(editor))\";\n")
        }

        let hasContent =
            !pageStates.isEmpty || !pageComputeds.isEmpty
            || !pageActions.isEmpty || !componentScopes.isEmpty
        if hasContent {
            js.append("Object.assign(window.__SCORE_DEV__,{")
            js.append("page:{")
            js.append("states:[\(pageStates.map { stateJSON($0) }.joined(separator: ","))],")
            js.append("computeds:[\(pageComputeds.map { computedJSON($0) }.joined(separator: ","))],")
            js.append("actions:[\(pageActions.map { actionJSON($0) }.joined(separator: ","))]")
            js.append("},")
            js.append("elements:[\(componentScopes.map { componentJSON($0) }.joined(separator: ","))]")
            js.append("});\n")
        }
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
        .inspect-btn{pointer-events:auto;background:none;border:1px solid rgba(255,255,255,.1);color:rgba(255,255,255,.4);cursor:pointer;padding:3px 8px;border-radius:4px;font:inherit;font-size:11px;transition:all .15s;display:flex;align-items:center;gap:4px;white-space:nowrap}
        .inspect-btn:hover{background:rgba(255,255,255,.06);color:rgba(255,255,255,.7);border-color:rgba(255,255,255,.2)}
        .inspect-btn.active{background:rgba(86,156,214,.2);color:#9cdcfe;border-color:rgba(86,156,214,.4)}
        .inspect-btn svg{width:14px;height:14px}
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
        .tree-item.selected{background:rgba(86,156,214,.15);border:1px solid rgba(86,156,214,.3)}
        .tree-toggle{width:14px;height:14px;display:inline-flex;align-items:center;justify-content:center;color:rgba(255,255,255,.25);font-size:9px;flex-shrink:0;margin-right:2px;transition:transform .15s;user-select:none}
        .tree-toggle:hover{color:rgba(255,255,255,.5)}
        .tree-toggle.collapsed{transform:rotate(-90deg)}
        .tree-name{color:#4ec9b0;font-size:12px}
        .tree-item[data-stateful] .tree-name{color:#569cd6}
        .tree-item[data-element] .tree-name{color:rgba(255,255,255,.3);font-style:italic}
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
        .empty{color:rgba(255,255,255,.2);font-style:italic;padding:12px 0}
        `;

        let expanded=false;
        let panelHeight=320;
        let activeTab='components';
        let inspecting=false;
        let selectedComponentEl=null;

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
          <button class="inspect-btn" id="inspect-btn"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2"><circle cx="11" cy="11" r="3"/><line x1="2" y1="11" x2="8" y2="11"/><line x1="14" y1="11" x2="22" y2="11"/><line x1="11" y1="2" x2="11" y2="8"/><line x1="11" y1="14" x2="11" y2="22"/></svg>Inspect</button>
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
        const inspectBtn=$('#inspect-btn');

        const overlayHost=document.createElement('div');
        overlayHost.id='score-devtools-overlays';
        overlayHost.style.cssText='position:fixed;top:0;left:0;width:0;height:0;z-index:2147483646;pointer-events:none';
        const overlayShadow=overlayHost.attachShadow({mode:'open'});
        overlayShadow.innerHTML=`<style>
        .highlight-overlay{position:fixed;pointer-events:none;z-index:2147483646;border:2px solid #569cd6;background:rgba(86,156,214,.08);border-radius:3px;transition:all .1s ease-out;box-sizing:border-box}
        .inspect-tooltip{position:fixed;pointer-events:auto;z-index:2147483647;font-family:-apple-system,BlinkMacSystemFont,'SF Mono',Menlo,monospace;font-size:12px;color:#e0e0e0;background:rgba(24,24,27,.96);backdrop-filter:blur(12px);-webkit-backdrop-filter:blur(12px);border:1px solid rgba(255,255,255,.12);border-radius:8px;padding:8px 10px;max-width:380px;box-shadow:0 4px 24px rgba(0,0,0,.5);display:none}
        .tip-component{display:flex;align-items:center;gap:6px;margin-bottom:4px}
        .tip-component-name{color:#4ec9b0;font-weight:600;font-size:12px}
        .tip-component-name.stateful{color:#569cd6}
        .tip-tag{color:rgba(255,255,255,.35);font-size:11px}
        .tip-breadcrumb{color:rgba(255,255,255,.25);font-size:10px;margin-bottom:6px;white-space:nowrap;overflow:hidden;text-overflow:ellipsis}
        .tip-breadcrumb span{color:rgba(255,255,255,.4)}
        .tip-section{margin-top:4px;padding-top:4px;border-top:1px solid rgba(255,255,255,.06)}
        .tip-section-title{color:rgba(255,255,255,.3);font-size:9px;text-transform:uppercase;letter-spacing:.5px;margin-bottom:2px}
        .tip-classes{color:#ce9178;font-size:11px;word-break:break-all}
        .tip-row{display:flex;align-items:baseline;gap:6px;padding:1px 0}
        .tip-label{color:rgba(255,255,255,.3);font-size:10px;min-width:48px}
        .tip-val{color:#dcdcaa;font-size:11px}
        .tip-val.binding{color:#9cdcfe}
        .tip-modifier{color:#c586c0;font-size:11px;padding:1px 0}
        .tip-attr-name{color:#9cdcfe;font-size:11px}
        .tip-attr-val{color:#ce9178;font-size:11px;margin-left:0}
        .tip-source{color:rgba(255,255,255,.25);font-size:10px;margin-top:4px;padding-top:4px;border-top:1px solid rgba(255,255,255,.06)}
        .tip-style-prop{display:flex;gap:6px;padding:1px 0 1px 12px;font-size:11px}
        .tip-style-name{color:rgba(255,255,255,.4);min-width:56px}
        .tip-style-val{color:#ce9178}
        .tip-bp-label{display:flex;align-items:center;gap:4px;font-size:9px;color:rgba(255,255,255,.2);padding:4px 0 2px;text-transform:uppercase;letter-spacing:.4px;font-weight:400}
        .tip-bp-label::before{content:'';flex:1;max-width:20px;height:1px;background:rgba(255,255,255,.08)}
        .tip-bp-label::after{content:'';flex:1;height:1px;background:rgba(255,255,255,.08)}
        .tip-action-desc{color:rgba(255,255,255,.35);font-size:10px;font-style:italic;padding:0 0 2px 56px}
        .tip-edit-btn{background:none;border:1px solid rgba(255,255,255,.1);color:rgba(255,255,255,.3);cursor:pointer;padding:1px 5px;border-radius:3px;font:inherit;font-size:9px;margin-left:auto;transition:all .15s}
        .tip-edit-btn:hover{background:rgba(86,156,214,.2);color:#9cdcfe;border-color:rgba(86,156,214,.4)}
        </style>
        <div class="highlight-overlay" id="overlay" style="display:none"></div>
        <div class="inspect-tooltip" id="tooltip"></div>`;
        const overlay=overlayShadow.querySelector('#overlay');
        const tooltip=overlayShadow.querySelector('#tooltip');

        pillPath.textContent=location.pathname;

        function toggle(){
          expanded=!expanded;
          panel.classList.toggle('open',expanded);
          if(expanded)render();
        }

        pill.addEventListener('click',(e)=>{
          if(e.target===inspectBtn||inspectBtn.contains(e.target))return;
          toggle();
        });
        $('#close').addEventListener('click',(e)=>{e.stopPropagation();expanded=false;panel.classList.remove('open')});

        $('#tabs').addEventListener('click',(e)=>{
          const tab=e.target.dataset?.tab;
          if(!tab)return;
          activeTab=tab;
          shadow.querySelectorAll('.tab').forEach(t=>t.classList.toggle('active',t.dataset.tab===tab));
          render();
        });

        // --- Inspector Mode ---

        inspectBtn.addEventListener('click',(e)=>{
          e.stopPropagation();
          toggleInspect();
        });

        const inspectCursorStyle=document.createElement('style');
        inspectCursorStyle.textContent='*{cursor:crosshair!important}';

        function toggleInspect(){
          inspecting=!inspecting;
          inspectBtn.classList.toggle('active',inspecting);
          if(inspecting){
            document.addEventListener('mousemove',onInspectMove,true);
            document.addEventListener('click',onInspectClick,true);
            document.addEventListener('keydown',onInspectKey,true);
            document.head.appendChild(inspectCursorStyle);
          }else{
            document.removeEventListener('mousemove',onInspectMove,true);
            document.removeEventListener('click',onInspectClick,true);
            document.removeEventListener('keydown',onInspectKey,true);
            inspectCursorStyle.remove();
            overlay.style.display='none';
            tooltip.style.display='none';
          }
        }

        function onInspectKey(e){
          if(e.key==='Escape'){
            e.preventDefault();
            e.stopPropagation();
            toggleInspect();
          }
        }

        function isDevToolsElement(el){
          return root.contains(el)||root===el||overlayHost.contains(el)||overlayHost===el;
        }

        function onInspectMove(e){
          const el=document.elementFromPoint(e.clientX,e.clientY);
          if(!el){overlay.style.display='none';tooltip.style.display='none';return}
          if(isDevToolsElement(el))return;
          highlightElement(el);
          showTooltip(el,e.clientX,e.clientY);
        }

        function onInspectClick(e){
          const el=document.elementFromPoint(e.clientX,e.clientY);
          if(!el||isDevToolsElement(el))return;
          e.preventDefault();
          e.stopPropagation();
          e.stopImmediatePropagation();
          selectElement(el);
          toggleInspect();
        }

        function findComponentAncestry(el){
          const chain=[];
          let node=el;
          while(node){
            if(node.hasAttribute){
              if(node.hasAttribute('data-score-component')){
                chain.unshift({el:node,name:node.getAttribute('data-score-component'),isStateful:node.hasAttribute('data-score-stateful')});
              }else if(node.hasAttribute('data-score-element')){
                chain.unshift({el:node,name:node.getAttribute('data-score-element'),isStateful:false,isElement:true});
              }
            }
            node=node.parentElement;
          }
          return chain;
        }

        function findNearestComponent(el){
          let node=el;
          while(node){
            if(node.hasAttribute&&node.hasAttribute('data-score-component'))return node;
            node=node.parentElement;
          }
          return null;
        }

        const skipAttrs=new Set(['class','style','title','data-score-component','data-score-stateful','data-score-modifiers','data-score-element','data-source','data-source-path','data-scope','data-s','data-r','data-bind','hidden','aria-hidden']);

        function getElementInfo(el){
          const info={tag:el.tagName.toLowerCase(),modifiers:[],attrs:[],bindings:[],scope:null,source:null,sourcePath:null};
          let mods=el.getAttribute('data-score-modifiers');
          if(!mods){let p=el.parentElement;while(p&&!mods){mods=p.getAttribute('data-score-modifiers');if(!mods)p=p.parentElement}}
          if(mods)info.modifiers=mods.split(';;').filter(Boolean);
          for(const attr of el.attributes){
            if(skipAttrs.has(attr.name))continue;
            info.attrs.push({name:attr.name,value:attr.value});
          }
          const scope=el.getAttribute('data-scope')||el.closest('[data-scope]')?.getAttribute('data-scope');
          if(scope)info.scope=scope;
          if(el.hasAttribute('data-s'))info.bindings.push({type:'event',index:el.getAttribute('data-s')});
          if(el.hasAttribute('data-r'))info.bindings.push({type:'reactive',index:el.getAttribute('data-r')});
          if(el.hasAttribute('data-bind'))info.bindings.push({type:'text',name:el.getAttribute('data-bind')});
          if(el.hasAttribute('hidden')&&el.closest('[data-r]'))info.bindings.push({type:'visibility',note:'hidden by state'});
          const src=el.getAttribute('data-source');
          if(src)info.source=src;
          const srcPath=el.getAttribute('data-source-path');
          if(srcPath)info.sourcePath=srcPath;
          return info;
        }

        function findEventBinding(idx){
          const i=parseInt(idx);
          const elements=D.elements||[];
          for(const el of elements){
            for(const b of (el.bindings||[])){
              if(b.index===i)return{binding:b,actions:el.actions||[]};
            }
          }
          return null;
        }

        function getStateBindingsForScope(scopeName){
          const result={states:[],computeds:[],actions:[]};
          const elements=D.elements||[];
          for(const el of elements){
            if(el.name===scopeName||el.name.startsWith(scopeName)){
              result.states.push(...(el.states||[]));
              result.computeds.push(...(el.computeds||[]));
              result.actions.push(...(el.actions||[]));
            }
          }
          return result;
        }

        const BREAKPOINT_NAMES=new Set(['compact','wide','tablet','large','desktop','cinema']);

        function splitAtDepth0(s){
          const parts=[];let depth=0,start=0;
          for(let i=0;i<s.length;i++){
            if(s[i]==='(')depth++;else if(s[i]===')')depth--;
            else if(s[i]===','&&depth===0){const p=s.substring(start,i).trim();if(p)parts.push(p);start=i+1}
          }
          const last=s.substring(start).trim();if(last)parts.push(last);return parts;
        }

        function parseModParts(s){
          const paren=s.indexOf('(');
          if(paren<0)return{name:s,props:[]};
          const name=s.substring(0,paren);
          const inner=s.substring(paren+1,s.length-1);
          const pairs=splitAtDepth0(inner);
          const props=pairs.map(p=>{
            const colon=p.indexOf(':');
            if(colon<0)return{key:'',value:p.trim()};
            return{key:p.substring(0,colon).trim(),value:p.substring(colon+1).trim().replace(/^\./,'')};
          });
          return{name,props};
        }

        function parseModifiers(modStrings){
          const defaults=[];const breakpoints={};
          for(const s of modStrings){
            const paren=s.indexOf('(');
            if(paren>0){
              const prefix=s.substring(0,paren);
              if(BREAKPOINT_NAMES.has(prefix)){
                const inner=s.substring(paren+1,s.length-1);
                if(!breakpoints[prefix])breakpoints[prefix]=[];
                for(const part of splitAtDepth0(inner))breakpoints[prefix].push(parseModParts(part));
                continue;
              }
            }
            defaults.push(parseModParts(s));
          }
          return{defaults,breakpoints};
        }

        function renderStyleProps(mods){
          let h='';
          for(const m of mods){
            h+=`<div class="tip-modifier">${esc(m.name)}</div>`;
            for(const p of m.props){
              if(p.key){
                h+=`<div class="tip-style-prop"><span class="tip-style-name">${esc(p.key)}</span><span class="tip-style-val">${esc(p.value)}</span></div>`;
              }else{
                h+=`<div class="tip-style-prop"><span class="tip-style-val">${esc(p.value)}</span></div>`;
              }
            }
          }
          return h;
        }

        function showTooltip(el,mx,my){
          const ancestry=findComponentAncestry(el);
          const info=getElementInfo(el);
          let h='';

          if(ancestry.length){
            const leaf=ancestry[ancestry.length-1];
            h+=`<div class="tip-component"><span class="tip-component-name${leaf.isStateful?' stateful':''}">${esc(leaf.name)}</span><span class="tip-tag">&lt;${esc(info.tag)}&gt;</span></div>`;
            if(ancestry.length>1){
              h+='<div class="tip-breadcrumb">';
              h+=ancestry.map((a,i)=>i<ancestry.length-1?`<span>${esc(a.name)}</span>`:'').filter(Boolean).join(' &rsaquo; ');
              h+='</div>';
            }
          }else{
            h+=`<div class="tip-component"><span class="tip-tag">&lt;${esc(info.tag)}&gt;</span></div>`;
          }

          if(info.modifiers.length){
            const parsed=parseModifiers(info.modifiers);
            h+='<div class="tip-section"><div class="tip-section-title">Styles</div>';
            h+=renderStyleProps(parsed.defaults);
            for(const bp of Object.keys(parsed.breakpoints)){
              h+=`<div class="tip-bp-label">${esc(bp)}</div>`;
              h+=renderStyleProps(parsed.breakpoints[bp]);
            }
            h+='</div>';
          }

          if(info.attrs.length){
            h+='<div class="tip-section"><div class="tip-section-title">Attributes</div>';
            for(const a of info.attrs){
              h+=`<div class="tip-row"><span class="tip-attr-name">${esc(a.name)}</span>`;
              if(a.value)h+=`<span class="tip-attr-val">="${esc(a.value)}"</span>`;
              h+='</div>';
            }
            h+='</div>';
          }

          const scopeState=info.scope?getStateBindingsForScope(info.scope):null;
          const bindingsH=[];
          if(info.scope){
            bindingsH.push(`<div class="tip-row"><span class="tip-label">scope</span><span class="tip-val binding">${esc(info.scope)}</span></div>`);
            const signals=D.signals||{};
            for(const s of scopeState.states){
              const sig=signals[s.name];
              const val=sig?formatValuePlain(sig.get()):s.initial||'?';
              bindingsH.push(`<div class="tip-row"><span class="tip-label">@State</span><span class="tip-val binding">${esc(s.name)} = ${esc(val)}</span></div>`);
            }
            for(const c of scopeState.computeds){
              const sig=signals[c.name];
              const val=sig?formatValuePlain(sig.get()):'?';
              bindingsH.push(`<div class="tip-row"><span class="tip-label">@Computed</span><span class="tip-val binding">${esc(c.name)} = ${esc(val)}</span></div>`);
            }
          }
          for(const b of info.bindings){
            if(b.type==='reactive')bindingsH.push(`<div class="tip-row"><span class="tip-label">reactive</span><span class="tip-val binding">data-r="${esc(b.index)}"</span></div>`);
            if(b.type==='text')bindingsH.push(`<div class="tip-row"><span class="tip-label">text</span><span class="tip-val binding">$${esc(b.name)}</span></div>`);
            if(b.type==='visibility')bindingsH.push(`<div class="tip-row"><span class="tip-label">visible</span><span class="tip-val binding">${esc(b.note)}</span></div>`);
          }
          if(bindingsH.length){
            h+='<div class="tip-section"><div class="tip-section-title">Bindings</div>';
            h+=bindingsH.join('');
            h+='</div>';
          }

          const actionsH=[];
          if(info.scope){
            for(const a of scopeState.actions){
              actionsH.push(`<div class="tip-row"><span class="tip-label">@Action</span><span class="tip-val">${esc(a.name)}()</span></div>`);
              if(a.body)actionsH.push(`<div class="tip-action-desc">${esc(a.body)}</div>`);
            }
          }
          for(const b of info.bindings){
            if(b.type==='event'){
              const found=findEventBinding(b.index);
              if(found){
                const eb=found.binding;
                actionsH.push(`<div class="tip-row"><span class="tip-label">on ${esc(eb.event)}</span><span class="tip-val binding">→ ${esc(eb.handler)}()</span></div>`);
                const ma=found.actions.find(a=>a.name===eb.handler);if(ma&&ma.body)actionsH.push(`<div class="tip-action-desc">${esc(ma.body)}</div>`);
              }else{
                actionsH.push(`<div class="tip-row"><span class="tip-label">event</span><span class="tip-val">data-s="${esc(b.index)}"</span></div>`);
              }
            }
          }
          if(actionsH.length){
            h+='<div class="tip-section"><div class="tip-section-title">Actions</div>';
            h+=actionsH.join('');
            h+='</div>';
          }

          if(info.source){
            const parts=info.source.split(':');
            const file=parts[0]?.split('/').pop()||'';
            const line=parts[1]||'';
            h+=`<div class="tip-source">${esc(file)}:${esc(line)}</div>`;
          }

          if(!h){tooltip.style.display='none';return}
          tooltip.innerHTML=h;
          tooltip.style.display='block';

          const tr=tooltip.getBoundingClientRect();
          let tx=mx+12;
          let ty=my+12;
          if(tx+tr.width>window.innerWidth-8)tx=mx-tr.width-12;
          if(ty+tr.height>window.innerHeight-8)ty=my-tr.height-12;
          if(tx<8)tx=8;
          if(ty<8)ty=8;
          tooltip.style.left=tx+'px';
          tooltip.style.top=ty+'px';
        }

        function selectElement(el){
          const componentEl=findNearestComponent(el);
          selectedComponentEl=componentEl||el;
          if(!expanded){expanded=true;panel.classList.add('open');}
          activeTab='components';
          shadow.querySelectorAll('.tab').forEach(t=>t.classList.toggle('active',t.dataset.tab==='components'));
          render();
          highlightElement(selectedComponentEl);
          if(componentEl){
            const items=getComponents();
            const idx=items.findIndex(i=>i.el===componentEl);
            if(idx>=0){
              const treeItem=body.querySelector(`.tree-item[data-idx="${idx}"]`);
              if(treeItem){
                treeItem.scrollIntoView({block:'center',behavior:'smooth'});
              }
            }
          }
        }

        // --- Resize ---

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
          const els=document.querySelectorAll('[data-score-component],[data-score-element]');
          const items=[];
          for(const el of els){
            let depth=0;
            let p=el.parentElement;
            while(p){
              if(p.hasAttribute&&(p.hasAttribute('data-score-component')||p.hasAttribute('data-score-element')))depth++;
              p=p.parentElement;
            }
            const isElement=el.hasAttribute('data-score-element');
            const name=isElement?el.getAttribute('data-score-element'):el.dataset.scoreComponent;
            const src=el.getAttribute('data-source')||(!isElement&&el.querySelector('[data-source]')?.getAttribute('data-source'))||'';
            const srcPath=el.getAttribute('data-source-path')||(!isElement&&el.querySelector('[data-source-path]')?.getAttribute('data-source-path'))||'';
            items.push({el,name,isStateful:el.hasAttribute('data-score-stateful'),isElement,depth,source:src,sourcePath:srcPath});
          }
          return items;
        }

        const collapsedComponents=new Set();

        function renderComponents(){
          const items=getComponents();
          pillInfo.textContent=items.length+' component'+(items.length===1?'':'s');
          if(!items.length)return '<div class="empty">No components found on this page.</div>';
          // Build parent map and detect which items have children
          const hasChildren=new Set();
          for(let i=0;i<items.length;i++){
            for(let j=i+1;j<items.length;j++){
              if(items[j].depth>items[i].depth){hasChildren.add(i);break}
              if(items[j].depth<=items[i].depth)break;
            }
          }
          // Determine which items are hidden by a collapsed ancestor
          const hiddenItems=new Set();
          for(let i=0;i<items.length;i++){
            if(collapsedComponents.has(i)){
              for(let j=i+1;j<items.length;j++){
                if(items[j].depth<=items[i].depth)break;
                hiddenItems.add(j);
              }
            }
          }
          let h='';
          for(let i=0;i<items.length;i++){
            if(hiddenItems.has(i))continue;
            const item=items[i];
            const pad=item.depth?` style="padding-left:${item.depth*16}px"`:'';
            const badge=item.isStateful?'<span class="tree-badge stateful">Stateful</span>':'';
            const srcLabel=item.source?formatSource(item.source,item.sourcePath):'';
            const sel=selectedComponentEl===item.el?' selected':'';
            const toggle=hasChildren.has(i)?`<span class="tree-toggle${collapsedComponents.has(i)?' collapsed':''}" data-toggle="${i}">&#9662;</span>`:'<span style="width:16px;display:inline-block;flex-shrink:0"></span>';
            const elAttr=item.isElement?' data-element':'';
            h+=`<div class="tree-item${sel}" data-idx="${i}"${item.isStateful?' data-stateful':''}${elAttr}${pad}>${toggle}<span class="tree-name">${esc(item.name)}</span>${badge}${srcLabel}</div>`;
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
            for(const s of allStates){
              const sig=signals[s.name];
              const val=sig?formatValuePlain(sig.get()):s.initial||'—';
              h+=`<div class="action-item"><span class="state-name">${esc(s.name)}</span><span class="state-value" data-signal="${esc(s.name)}">${esc(val)}</span><span class="state-scope">${esc(s.scope)}</span></div>`;
              if(s.storageKey)h+=`<div style="padding-left:8px;font-size:10px;color:#4ec9b0">persisted: ${esc(s.storageKey)}</div>`;
            }
          }

          if(allComputeds.length){
            h+='<div class="section-label">Computed</div>';
            for(const c of allComputeds){
              const sig=signals[c.name];
              const val=sig?formatValuePlain(sig.get()):'—';
              h+=`<div class="action-item"><span class="state-name">${esc(c.name)}</span><span class="state-value" data-signal="${esc(c.name)}">${esc(val)}</span><span class="state-scope">${esc(c.scope)}</span></div>`;
            }
          }

          if(allActions.length){
            h+='<div class="section-label">Actions</div>';
            for(const a of allActions){
              h+=`<div class="action-item"><span class="action-name">${esc(a.name)}()</span><span class="state-scope">${esc(a.scope)}</span></div>`;
              if(a.body)h+=`<div style="padding-left:8px;font-size:11px;color:rgba(255,255,255,.3)">${esc(a.body)}</div>`;
            }
          }

          if(!h)h='<div class="empty">No reactive state on this page.</div>';
          return h;
        }

        const editorScheme=(window.__SCORE_DEV__&&window.__SCORE_DEV__.editor)||'vscode';

        function formatSource(src,srcPath){
          const parts=src.split(':');
          if(parts.length<2)return '';
          const file=parts[0].split('/').pop();
          const line=parts[1];
          if(!srcPath)return `<span class="tree-source">${esc(file)}:${esc(line)}</span>`;
          const pp=srcPath.split(':');
          const filePath=pp[0].startsWith('/')?pp[0]:'/'+pp[0];
          const ln=pp[1]||'1',col=pp[2]||'1';
          let href;
          if(editorScheme==='subl'||editorScheme==='sublime'){
            href='subl://open?url=file://'+encodeURIComponent(filePath)+'&line='+ln+'&column='+col;
          }else if(editorScheme==='idea'||editorScheme==='webstorm'){
            href=editorScheme+'://open?file='+encodeURIComponent(filePath)+'&line='+ln+'&column='+col;
          }else{
            href=editorScheme+'://file'+filePath+':'+ln+':'+col;
          }
          return `<a class="tree-source" href="${esc(href)}">${esc(file)}:${esc(line)}</a>`;
        }

        function render(){
          if(!expanded)return;
          body.innerHTML=activeTab==='components'?renderComponents():renderState();
          if(activeTab==='components')bindTreeEvents();
        }

        function bindTreeEvents(){
          const items=getComponents();
          body.querySelectorAll('.tree-toggle').forEach(el=>{
            el.addEventListener('click',(e)=>{
              e.stopPropagation();
              const idx=parseInt(el.dataset.toggle);
              if(collapsedComponents.has(idx))collapsedComponents.delete(idx);
              else collapsedComponents.add(idx);
              render();
            });
          });
          body.querySelectorAll('.tree-item').forEach(el=>{
            const idx=parseInt(el.dataset.idx);
            el.addEventListener('mouseenter',()=>highlightElement(items[idx]?.el));
            el.addEventListener('mouseleave',()=>{if(!selectedComponentEl)overlay.style.display='none'});
            el.addEventListener('click',()=>{
              selectedComponentEl=items[idx]?.el||null;
              if(selectedComponentEl)highlightElement(selectedComponentEl);
              render();
            });
          });
          body.querySelectorAll('a.tree-source').forEach(el=>{
            el.addEventListener('click',(e)=>{
              e.preventDefault();
              e.stopPropagation();
              const href=el.getAttribute('href');
              if(href){
                const f=document.createElement('iframe');
                f.style.display='none';
                f.src=href;
                document.body.appendChild(f);
                setTimeout(()=>f.remove(),500);
              }
            });
          });
        }

        function getVisibleRect(el){
          let r=el.getBoundingClientRect();
          if(r.width>0||r.height>0)return r;
          // display:contents elements have zero rect — compute from children
          let top=Infinity,left=Infinity,bottom=-Infinity,right=-Infinity;
          for(const child of el.children){
            const cr=child.getBoundingClientRect();
            if(cr.width===0&&cr.height===0)continue;
            top=Math.min(top,cr.top);
            left=Math.min(left,cr.left);
            bottom=Math.max(bottom,cr.bottom);
            right=Math.max(right,cr.right);
          }
          if(top===Infinity)return null;
          return{top,left,width:right-left,height:bottom-top};
        }

        function highlightElement(el){
          if(!el){overlay.style.display='none';return}
          const r=getVisibleRect(el);
          if(!r){overlay.style.display='none';return}
          const vv=window.visualViewport;const vw=vv?vv.width:window.innerWidth,vh=vv?vv.height:window.innerHeight;
          const top=Math.max(0,r.top),left=Math.max(0,r.left);
          const bottom=Math.min(vh,r.top+r.height),right=Math.min(vw,r.left+r.width);
          if(right<=left||bottom<=top){overlay.style.display='none';return}
          overlay.style.display='block';
          overlay.style.top=top+'px';
          overlay.style.left=left+'px';
          overlay.style.width=(right-left)+'px';
          overlay.style.height=(bottom-top)+'px';
        }

        function formatValue(v){
          if(v===null)return'<i>null</i>';
          if(v===undefined)return'<i>undefined</i>';
          if(typeof v==='string')return'"'+esc(v)+'"';
          if(typeof v==='boolean')return v?'true':'false';
          return esc(String(v));
        }

        function formatValuePlain(v){
          if(v===null)return'null';
          if(v===undefined)return'undefined';
          if(typeof v==='string')return'"'+v+'"';
          return String(v);
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
              if(sig)td.textContent=formatValuePlain(sig.get());
            });
          },300);
        }

        async function devEdit(payload){
          try{
            const res=await fetch('/_dev/edit',{method:'POST',headers:{'content-type':'application/json'},body:JSON.stringify(payload)});
            if(!res.ok){const t=await res.text();console.error('[Score DevTools] edit failed:',t);return false}
            return true;
          }catch(e){console.error('[Score DevTools] edit error:',e);return false}
        }

        function makeEditable(el){
          if(!el||!el.hasAttribute('data-source-path'))return;
          el.addEventListener('dblclick',async(e)=>{
            e.preventDefault();e.stopPropagation();
            const srcPath=el.getAttribute('data-source-path');
            const text=el.textContent;
            const newText=prompt('Edit text content:',text);
            if(newText===null||newText===text)return;
            const ok=await devEdit({type:'text',sourcePath:srcPath,oldValue:text,newValue:newText});
            if(ok)el.textContent=newText;
          });
        }

        function initEditableElements(){
          document.querySelectorAll('[data-source-path][data-bind]').forEach(makeEditable);
          document.querySelectorAll('[data-source-path]').forEach(el=>{
            if(el.children.length===0&&el.textContent.trim())makeEditable(el);
          });
        }

        window.__scoreDevTools={
          toggle(){root.style.display=root.style.display==='none'?'':'none'},
          show(){root.style.display=''},
          hide(){root.style.display='none';expanded=false;panel.classList.remove('open');if(inspecting)toggleInspect()},
          get visible(){return root.style.display!=='none'},
          edit:devEdit
        };

        document.body.appendChild(root);
        document.body.appendChild(overlayHost);
        const items=getComponents();
        pillInfo.textContent=items.length+' component'+(items.length===1?'':'s');
        startPoll();
        initEditableElements();
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

    private static func eventBindingJSON(_ b: JSEmitter.EventBinding) -> String {
        "{event:\"\(jsEscape(b.event))\",handler:\"\(jsEscape(b.handler))\",index:\(b.documentIndex)}"
    }

    private static func componentJSON(_ e: JSEmitter.ComponentScope) -> String {
        let states = e.states.map { stateJSON($0) }.joined(separator: ",")
        let computeds = e.computeds.map { computedJSON($0) }.joined(separator: ",")
        let actions = e.actions.map { actionJSON($0) }.joined(separator: ",")
        let bindings = e.bindings.map { eventBindingJSON($0) }.joined(separator: ",")
        return "{name:\"\(jsEscape(e.name))\",states:[\(states)],computeds:[\(computeds)],actions:[\(actions)],bindings:[\(bindings)]}"
    }

    static func jsEscape(_ s: String) -> String {
        var result = ""
        result.reserveCapacity(s.count)
        for c in s {
            switch c {
            case "\\": result.append("\\\\")
            case "\"": result.append("\\\"")
            case "\n": result.append("\\n")
            default: result.append(c)
            }
        }
        return result
    }
}
