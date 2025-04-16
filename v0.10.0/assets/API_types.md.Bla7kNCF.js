import{_ as n,C as p,c as o,o as d,j as e,a as t,aA as l,G as i,w as r}from"./chunks/framework.D0XGVUHR.js";const F=JSON.parse('{"title":"Types","description":"","frontmatter":{},"headers":[],"relativePath":"API/types.md","filePath":"API/types.md","lastUpdated":null}'),h={name:"API/types.md"},c={class:"jldocstring custom-block",open:""},g={class:"jldocstring custom-block",open:""},k={class:"jldocstring custom-block",open:""},y={class:"jldocstring custom-block",open:""},b={class:"jldocstring custom-block",open:""},u={class:"jldocstring custom-block",open:""},f={class:"jldocstring custom-block",open:""},A={class:"jldocstring custom-block",open:""},E={class:"jldocstring custom-block",open:""};function m(j,s,T,_,C,O){const a=p("Badge");return d(),o("div",null,[s[36]||(s[36]=e("h1",{id:"types",tabindex:"-1"},[t("Types "),e("a",{class:"header-anchor",href:"#types","aria-label":'Permalink to "Types"'},"​")],-1)),e("details",c,[e("summary",null,[s[0]||(s[0]=e("a",{id:"AlgebraOfGraphics.AbstractDrawable",href:"#AlgebraOfGraphics.AbstractDrawable"},[e("span",{class:"jlbinding"},"AlgebraOfGraphics.AbstractDrawable")],-1)),s[1]||(s[1]=t()),i(a,{type:"info",class:"jlObjectType jlType",text:"Type"})]),s[3]||(s[3]=l('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">AbstractDrawable</span></span></code></pre></div><p>Abstract type encoding objects that can be drawn via <a href="/v0.10.0/API/functions#AlgebraOfGraphics.draw"><code>AlgebraOfGraphics.draw</code></a>.</p>',2)),i(a,{type:"info",class:"source-link",text:"source"},{default:r(()=>s[2]||(s[2]=[e("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})]),e("details",g,[e("summary",null,[s[4]||(s[4]=e("a",{id:"AlgebraOfGraphics.AbstractAlgebraic",href:"#AlgebraOfGraphics.AbstractAlgebraic"},[e("span",{class:"jlbinding"},"AlgebraOfGraphics.AbstractAlgebraic")],-1)),s[5]||(s[5]=t()),i(a,{type:"info",class:"jlObjectType jlType",text:"Type"})]),s[7]||(s[7]=l('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">AbstractAlgebraic  </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&lt;:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> AbstractDrawable</span></span></code></pre></div><p>Abstract type encoding objects that can be combined together using <code>+</code> and <code>*</code>.</p>',2)),i(a,{type:"info",class:"source-link",text:"source"},{default:r(()=>s[6]||(s[6]=[e("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})]),e("details",k,[e("summary",null,[s[8]||(s[8]=e("a",{id:"AlgebraOfGraphics.Layer",href:"#AlgebraOfGraphics.Layer"},[e("span",{class:"jlbinding"},"AlgebraOfGraphics.Layer")],-1)),s[9]||(s[9]=t()),i(a,{type:"info",class:"jlObjectType jlType",text:"Type"})]),s[11]||(s[11]=l('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Layer</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(transformation, data, positional</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">AbstractVector</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, named</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">AbstractDictionary</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Algebraic object encoding a single layer of a visualization. It is composed of a dataset, positional and named arguments, as well as a transformation to be applied to those. <code>Layer</code> objects can be multiplied, yielding a novel <code>Layer</code> object, or added, yielding a <a href="/v0.10.0/API/types#AlgebraOfGraphics.Layers"><code>AlgebraOfGraphics.Layers</code></a> object.</p>',2)),i(a,{type:"info",class:"source-link",text:"source"},{default:r(()=>s[10]||(s[10]=[e("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})]),e("details",y,[e("summary",null,[s[12]||(s[12]=e("a",{id:"AlgebraOfGraphics.Layers",href:"#AlgebraOfGraphics.Layers"},[e("span",{class:"jlbinding"},"AlgebraOfGraphics.Layers")],-1)),s[13]||(s[13]=t()),i(a,{type:"info",class:"jlObjectType jlType",text:"Type"})]),s[15]||(s[15]=l('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Layers</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(layers</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Vector{Layer}</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Algebraic object encoding a list of <a href="/v0.10.0/API/types#AlgebraOfGraphics.Layer"><code>AlgebraOfGraphics.Layer</code></a> objects. <code>Layers</code> objects can be added or multiplied, yielding a novel <code>Layers</code> object.</p>',2)),i(a,{type:"info",class:"source-link",text:"source"},{default:r(()=>s[14]||(s[14]=[e("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})]),e("details",b,[e("summary",null,[s[16]||(s[16]=e("a",{id:"AlgebraOfGraphics.zerolayer",href:"#AlgebraOfGraphics.zerolayer"},[e("span",{class:"jlbinding"},"AlgebraOfGraphics.zerolayer")],-1)),s[17]||(s[17]=t()),i(a,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),s[19]||(s[19]=l(`<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">zerolayer</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()</span></span></code></pre></div><p>Returns a <code>Layers</code> with an empty layer list which can act as a zero in the layer algebra.</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>layer * zerolayer() ~ zerolayer()</span></span>
<span class="line"><span>layer + zerolayer() ~ layer</span></span></code></pre></div>`,3)),i(a,{type:"info",class:"source-link",text:"source"},{default:r(()=>s[18]||(s[18]=[e("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})]),e("details",u,[e("summary",null,[s[20]||(s[20]=e("a",{id:"AlgebraOfGraphics.ProcessedLayer",href:"#AlgebraOfGraphics.ProcessedLayer"},[e("span",{class:"jlbinding"},"AlgebraOfGraphics.ProcessedLayer")],-1)),s[21]||(s[21]=t()),i(a,{type:"info",class:"jlObjectType jlType",text:"Type"})]),s[23]||(s[23]=l('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">ProcessedLayer</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(l</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Layer</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Process a <code>Layer</code> and return the resulting <code>ProcessedLayer</code>.</p><p>Note that this method should not be used anymore as processing a <code>Layer</code> can now potentially return multiple <code>ProcessedLayer</code> objects. Therefore, you should use the plural form <code>ProcessedLayers(layer)</code>.</p>',3)),i(a,{type:"info",class:"source-link",text:"source"},{default:r(()=>s[22]||(s[22]=[e("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})]),e("details",f,[e("summary",null,[s[24]||(s[24]=e("a",{id:"AlgebraOfGraphics.ProcessedLayers",href:"#AlgebraOfGraphics.ProcessedLayers"},[e("span",{class:"jlbinding"},"AlgebraOfGraphics.ProcessedLayers")],-1)),s[25]||(s[25]=t()),i(a,{type:"info",class:"jlObjectType jlType",text:"Type"})]),s[27]||(s[27]=l('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">ProcessedLayers</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(layers</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Vector{ProcessedLayer}</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Object encoding a list of <a href="/v0.10.0/API/types#AlgebraOfGraphics.ProcessedLayer"><code>AlgebraOfGraphics.ProcessedLayer</code></a> objects. <code>ProcessedLayers</code> objects are the output of the processing pipeline and can be drawn without further processing.</p>',2)),i(a,{type:"info",class:"source-link",text:"source"},{default:r(()=>s[26]||(s[26]=[e("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})]),e("details",A,[e("summary",null,[s[28]||(s[28]=e("a",{id:"AlgebraOfGraphics.Entry",href:"#AlgebraOfGraphics.Entry"},[e("span",{class:"jlbinding"},"AlgebraOfGraphics.Entry")],-1)),s[29]||(s[29]=t()),i(a,{type:"info",class:"jlObjectType jlType",text:"Type"})]),s[31]||(s[31]=l('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Entry</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(plottype</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">PlotType</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, positional</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Arguments</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, named</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">NamedArguments</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Define plottype as well as positional and named arguments for a single plot.</p>',2)),i(a,{type:"info",class:"source-link",text:"source"},{default:r(()=>s[30]||(s[30]=[e("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})]),e("details",E,[e("summary",null,[s[32]||(s[32]=e("a",{id:"AlgebraOfGraphics.AxisEntries",href:"#AlgebraOfGraphics.AxisEntries"},[e("span",{class:"jlbinding"},"AlgebraOfGraphics.AxisEntries")],-1)),s[33]||(s[33]=t()),i(a,{type:"info",class:"jlObjectType jlType",text:"Type"})]),s[35]||(s[35]=l('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">AxisEntries</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(axis</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Union{Axis, Nothing}</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, entries</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">::</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Vector{Entry}</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, categoricalscales, continuousscales)</span></span></code></pre></div><p>Define all ingredients to make plots on an axis. Each categorical scale should be a <code>CategoricalScale</code>, and each continuous scale should be a <code>ContinuousScale</code>.</p>',2)),i(a,{type:"info",class:"source-link",text:"source"},{default:r(()=>s[34]||(s[34]=[e("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})])])}const G=n(h,[["render",m]]);export{F as __pageData,G as default};
