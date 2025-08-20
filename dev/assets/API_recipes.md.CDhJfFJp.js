import{_ as t,C as o,c as r,o as c,j as a,a as p,aA as i,G as e,w as l}from"./chunks/framework.Fi7d9u-2.js";const y=JSON.parse('{"title":"Recipes","description":"","frontmatter":{},"headers":[],"relativePath":"API/recipes.md","filePath":"API/recipes.md","lastUpdated":null}'),d={name:"API/recipes.md"},h={class:"jldocstring custom-block",open:""},u={class:"jldocstring custom-block",open:""};function g(k,s,b,f,m,_){const n=o("Badge");return c(),r("div",null,[s[8]||(s[8]=a("h1",{id:"Recipes",tabindex:"-1"},[p("Recipes "),a("a",{class:"header-anchor",href:"#Recipes","aria-label":'Permalink to "Recipes {#Recipes}"'},"​")],-1)),a("details",h,[a("summary",null,[s[0]||(s[0]=a("a",{id:"AlgebraOfGraphics.choropleth",href:"#AlgebraOfGraphics.choropleth"},[a("span",{class:"jlbinding"},"AlgebraOfGraphics.choropleth")],-1)),s[1]||(s[1]=p()),e(n,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),s[3]||(s[3]=i(`<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">choropleth</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(geometries; transformation, attributes</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Choropleth map, where regions are defined by <code>geometries</code>. Use <code>transformation</code> to transform coordinates (see <a href="https://github.com/JuliaGeo/Proj.jl" target="_blank" rel="noreferrer">Proj.jl</a> for more information).</p><div class="warning custom-block"><p class="custom-block-title">Warning</p><p>The <code>transformation</code> keyword argument is experimental and could be deprecated (even in a non-breaking release) in favor of a different syntax.</p></div><p><strong>Attributes</strong></p><p>Available attributes and their defaults for <code>Plot{AlgebraOfGraphics.choropleth}</code> are:</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>  alpha               1.0</span></span>
<span class="line"><span>  clip_planes         Plane3f[]</span></span>
<span class="line"><span>  color               RGB{Float32}(0.4, 0.4, 0.4)</span></span>
<span class="line"><span>  colormap            :viridis</span></span>
<span class="line"><span>  colorrange          Makie.Automatic()</span></span>
<span class="line"><span>  colorscale          identity</span></span>
<span class="line"><span>  cycle               [:color =&gt; :patchcolor]</span></span>
<span class="line"><span>  depth_shift         0.0f0</span></span>
<span class="line"><span>  highclip            Makie.Automatic()</span></span>
<span class="line"><span>  inspectable         true</span></span>
<span class="line"><span>  inspector_clear     Makie.Automatic()</span></span>
<span class="line"><span>  inspector_hover     Makie.Automatic()</span></span>
<span class="line"><span>  inspector_label     Makie.Automatic()</span></span>
<span class="line"><span>  joinstyle           :miter</span></span>
<span class="line"><span>  linecap             :butt</span></span>
<span class="line"><span>  linestyle           &quot;nothing&quot;</span></span>
<span class="line"><span>  lowclip             Makie.Automatic()</span></span>
<span class="line"><span>  miter_limit         1.0471975511965976</span></span>
<span class="line"><span>  nan_color           :transparent</span></span>
<span class="line"><span>  overdraw            false</span></span>
<span class="line"><span>  shading             false</span></span>
<span class="line"><span>  space               :data</span></span>
<span class="line"><span>  ssao                false</span></span>
<span class="line"><span>  stroke_depth_shift  -1.0f-5</span></span>
<span class="line"><span>  strokecolor         :black</span></span>
<span class="line"><span>  strokecolormap      :viridis</span></span>
<span class="line"><span>  strokewidth         0</span></span>
<span class="line"><span>  transparency        false</span></span>
<span class="line"><span>  visible             true</span></span></code></pre></div>`,6)),e(n,{type:"info",class:"source-link",text:"source"},{default:l(()=>s[2]||(s[2]=[a("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1,__:[2]})]),a("details",u,[a("summary",null,[s[4]||(s[4]=a("a",{id:"AlgebraOfGraphics.linesfill",href:"#AlgebraOfGraphics.linesfill"},[a("span",{class:"jlbinding"},"AlgebraOfGraphics.linesfill")],-1)),s[5]||(s[5]=p()),e(n,{type:"info",class:"jlObjectType jlFunction",text:"Function"})]),s[7]||(s[7]=i(`<div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">linesfill</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(xs, ys; lower, upper, attributes</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">...</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><p>Line plot with a shaded area between <code>lower</code> and <code>upper</code>. If <code>lower</code> and <code>upper</code> are not given, shaded area is between <code>0</code> and <code>ys</code>.</p><p><strong>Attributes</strong></p><p>Available attributes and their defaults for <code>Plot{AlgebraOfGraphics.linesfill}</code> are:</p><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>  color       :black</span></span>
<span class="line"><span>  colormap    :viridis</span></span>
<span class="line"><span>  colorrange  Makie.Automatic()</span></span>
<span class="line"><span>  direction   :x</span></span>
<span class="line"><span>  fillalpha   0.15</span></span>
<span class="line"><span>  linestyle   &quot;nothing&quot;</span></span>
<span class="line"><span>  linewidth   1.5</span></span>
<span class="line"><span>  lower       Makie.Automatic()</span></span>
<span class="line"><span>  upper       Makie.Automatic()</span></span></code></pre></div>`,5)),e(n,{type:"info",class:"source-link",text:"source"},{default:l(()=>s[6]||(s[6]=[a("a",{href:"https://github.com/MakieOrg/AlgebraOfGraphics.jl",target:"_blank",rel:"noreferrer"},"source",-1)])),_:1,__:[6]})])])}const A=t(d,[["render",g]]);export{y as __pageData,A as default};
