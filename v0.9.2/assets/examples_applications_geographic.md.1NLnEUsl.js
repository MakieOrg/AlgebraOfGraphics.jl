import{_ as i,c as a,o as n,az as t}from"./chunks/framework.BxqUZRRL.js";const h="/v0.9.2/assets/ydwovwx.CkXkPG1R.png",g=JSON.parse('{"title":"Geographic data","description":"","frontmatter":{},"headers":[],"relativePath":"examples/applications/geographic.md","filePath":"examples/applications/geographic.md","lastUpdated":null}'),l={name:"examples/applications/geographic.md"};function p(e,s,k,r,d,E){return n(),a("div",null,s[0]||(s[0]=[t(`<h1 id="Geographic-data" tabindex="-1">Geographic data <a class="header-anchor" href="#Geographic-data" aria-label="Permalink to &quot;Geographic data {#Geographic-data}&quot;">​</a></h1><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> AlgebraOfGraphics, CairoMakie</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Shapefile, ZipFile</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Downloads</span></span></code></pre></div><p>Antarctic coastline. Data from the SCAR Antarctic Digital Database<sup class="footnote-ref"><a href="#fn1" id="fnref1">[1]</a></sup>.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># Download, extract, and load shapefile</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">t </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mktempdir</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> dir</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    url </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;https://ramadda.data.bas.ac.uk/repository/entry/get/add_coastline_medium_res_polygon_v7_4.zip?entryid=synth%3Ae747e63e-9d93-49c2-bafc-cf3d3f8e5afa%3AL2FkZF9jb2FzdGxpbmVfbWVkaXVtX3Jlc19wb2x5Z29uX3Y3XzQuemlw&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    r </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> ZipFile</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Reader</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">seekstart</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Downloads</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">download</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(url, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">IOBuffer</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">())))</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    for</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> f </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">in</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> r</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">files</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        open</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(dir, f</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">name), write </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> true</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">do</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> io</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">            write</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(io, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">read</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(f, String));</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">        end</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">    end</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    Shapefile</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Table</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">joinpath</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(dir, </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;add_coastline_medium_res_polygon_v7_4.shp&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">end</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># Draw map</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">plt </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(t) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mapping</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:geometry</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, color </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :surface</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> visual</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Choropleth)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">fg </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> draw</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(plt; axis</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(aspect</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,))</span></span></code></pre></div><p><img src="`+h+'" alt=""></p><hr class="footnotes-sep"><section class="footnotes"><ol class="footnotes-list"><li id="fn1" class="footnote-item"><p>Gerrish, L., Fretwell, P., &amp; Cooper, P. (2021). Medium resolution vector polygons of the Antarctic coastline (7.4) [Data set]. UK Polar Data Centre, Natural Environment Research Council, UK Research &amp; Innovation. <a href="https://doi.org/10.5285/747e63e-9d93-49c2-bafc-cf3d3f8e5afa" target="_blank" rel="noreferrer">https://doi.org/10.5285/747e63e-9d93-49c2-bafc-cf3d3f8e5afa</a> <a href="#fnref1" class="footnote-backref">↩︎</a></p></li></ol></section>',7)]))}const c=i(l,[["render",p]]);export{g as __pageData,c as default};
