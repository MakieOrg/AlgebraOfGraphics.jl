import{_ as l,C as p,c as h,o as r,j as s,aA as e,a as t,G as n,w as d}from"./chunks/framework.Cva0UXtJ.js";const m=JSON.parse('{"title":"Data","description":"","frontmatter":{},"headers":[],"relativePath":"reference/data.md","filePath":"reference/data.md","lastUpdated":null}'),o={name:"reference/data.md"},k={class:"jldocstring custom-block",open:""};function c(g,a,E,u,y,b){const i=p("Badge");return r(),h("div",null,[a[4]||(a[4]=s("h1",{id:"data",tabindex:"-1"},[t("Data "),s("a",{class:"header-anchor",href:"#data","aria-label":'Permalink to "Data"'},"​")],-1)),s("details",k,[s("summary",null,[a[0]||(a[0]=s("a",{id:"AlgebraOfGraphics.data",href:"#AlgebraOfGraphics.data"},[s("span",{class:"jlbinding"},"AlgebraOfGraphics.data")],-1)),a[1]||(a[1]=t()),n(i,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),a[3]||(a[3]=e('<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(table)</span></span></code></pre></div><p>Create a <a href="/v0.9.7/API/types#AlgebraOfGraphics.Layer"><code>Layer</code></a> with its data field set to a table-like object.</p><p>There are no type restrictions on this object, as long as it respects the Tables interface. In particular, any one of <a href="https://github.com/JuliaData/Tables.jl/blob/main/INTEGRATIONS.md" target="_blank" rel="noreferrer">these formats</a> should work out of the box.</p><p>To create a fully specified layer, the layer created with <code>data</code> needs to be multiplied with the output of <a href="/v0.9.7/reference/mapping#AlgebraOfGraphics.mapping"><code>mapping</code></a>.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">spec </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mapping</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div>',5)),n(i,{type:"info",class:"source-link",text:"source"},{default:d(()=>a[2]||(a[2]=[s("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1})]),a[5]||(a[5]=e(`<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> AlgebraOfGraphics</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">df </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (a </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), b </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> rand</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">10</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(df)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Layer </span></span>
<span class="line"><span>  transformation: identity</span></span>
<span class="line"><span>  data: AlgebraOfGraphics.Columns{@NamedTuple{a::Vector{Float64}, b::Vector{Float64}}}</span></span>
<span class="line"><span>  positional:</span></span>
<span class="line"><span>  named:</span></span></code></pre></div>`,2))])}const C=l(o,[["render",c]]);export{m as __pageData,C as default};
