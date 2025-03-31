import{_ as i,c as a,o as n,aA as t}from"./chunks/framework.D0XGVUHR.js";const e="/v0.10.0/assets/yshkvnb.BafslIq3.png",l="/v0.10.0/assets/vqnwgjq.BcoYRlZy.png",h="/v0.10.0/assets/cpfioaa.DnthETxm.png",p="/v0.10.0/assets/shahdlp.uj4iqoH1.png",k="/v0.10.0/assets/kvafpyg.BB6rv7fA.png",o="/v0.10.0/assets/kqxqkyb.BK79pjvD.png",d="/v0.10.0/assets/reqcwah.B1RG5M_q.png",r="/v0.10.0/assets/arvxliq.DOyqvmAm.png",g="/v0.10.0/assets/xwhafdw.BN_D7HvC.png",c="/v0.10.0/assets/pgsaejz.DjTvGX-k.png",E="/v0.10.0/assets/lfnnlhi.DbV1nWmh.png",y="/v0.10.0/assets/fwfutxs.bAiwwcno.png",A=JSON.parse('{"title":"Intro to AoG - VI - Editing and composing AoG plots with Makie","description":"","frontmatter":{},"headers":[],"relativePath":"tutorials/intro-vi.md","filePath":"tutorials/intro-vi.md","lastUpdated":null}'),u={name:"tutorials/intro-vi.md"};function F(b,s,f,C,m,v){return n(),a("div",null,s[0]||(s[0]=[t(`<h1 id="Intro-to-AoG-VI-Editing-and-composing-AoG-plots-with-Makie" tabindex="-1">Intro to AoG - VI - Editing and composing AoG plots with Makie <a class="header-anchor" href="#Intro-to-AoG-VI-Editing-and-composing-AoG-plots-with-Makie" aria-label="Permalink to &quot;Intro to AoG - VI - Editing and composing AoG plots with Makie {#Intro-to-AoG-VI-Editing-and-composing-AoG-plots-with-Makie}&quot;">​</a></h1><p>In the last chapters we have concentrated on creating standalone AlgebraOfGraphics figures, without focusing to much on fiddling with the visual results. However, in practice, many people spend a lot of time on tweaking their figures until they are satisfied with the smallest details.</p><p>Too often, such edits still happen in vector graphics software like Inkscape these days, which is both time consuming and non-reproducible, and should therefore be avoided if at all possible. Luckily, AlgebraOfGraphics is built on Makie, and Makie has a special focus on layouting and interactive editing. This means that it is easy to combine multiple AoG plots in a figure, as well as changing the underlying plot objects programmatically if that&#39;s desired.</p><p>Let&#39;s first bring our trusty old penguin dataset back in and draw a basic facet plot. We store the output of <code>draw</code> in a variable <code>figuregrid</code>, too:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> AlgebraOfGraphics</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> CairoMakie</span></span>
<span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> DataFrames</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">penguins </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> DataFrame</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(AlgebraOfGraphics</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">penguins</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">())</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">spec </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(penguins) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    mapping</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        :bill_length_mm</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Bill length (mm)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        :bill_depth_mm</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Bill depth (mm)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        row </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :sex</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        col </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :island</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        color </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :species</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Species&quot;</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    visual</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Scatter)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figuregrid </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> draw</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(spec)</span></span></code></pre></div><p><img src="`+e+`" alt="" width="600px" height="450px"></p><p>The type of <code>figuregrid</code> is:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">typeof</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figuregrid)</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>AlgebraOfGraphics.FigureGrid</span></span></code></pre></div><p>True to its name, it stores two fields, <code>figure</code> and <code>grid</code>.</p><p>The <code>figure</code> contains the Makie <code>Figure</code> object in which every other element is drawn. We can do basic modifications to its underlying <code>Scene</code> object, like changing its background color (check Makie&#39;s <a href="https://docs.makie.org/stable/tutorials/scenes" target="_blank" rel="noreferrer">scene tutorial</a> for more information on <code>Scene</code>s):</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> figuregrid</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">scene</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">backgroundcolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">to_color</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:gray90</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+l+`" alt="" width="600px" height="450px"></p><p>We can also resize the figure:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">resize!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figure, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">500</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">300</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+h+`" alt="" width="500px" height="300px"></p><h2 id="Drawing-into-an-existing-Figure" tabindex="-1">Drawing into an existing <code>Figure</code> <a class="header-anchor" href="#Drawing-into-an-existing-Figure" aria-label="Permalink to &quot;Drawing into an existing \`Figure\` {#Drawing-into-an-existing-Figure}&quot;">​</a></h2><p>But we can also add further objects to our <code>Figure</code>. And we can do this directly with AlgebraOfGraphics by using the <code>draw!</code> function instead of <code>draw</code> (the <code>!</code> is a naming convention in Julia that hints that something is being modified by a function, here a <code>Figure</code>).</p><p>Let&#39;s say we wanted to also show flipper length vs body mass in a separate plot. We can do that by <code>draw!</code>ing the specification into a grid position of the underlying figure layout (check, for example, <a href="https://docs.makie.org/stable/tutorials/layout-tutorial" target="_blank" rel="noreferrer">the layout tutorial in the Makie docs</a> to learn more about grid layouts).</p><p>To know where to put our new plot, it can be helpful to look at the current layout first:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">layout</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>GridLayout[1:2, 1:4] with 14 children</span></span>
<span class="line"><span> ┣━ [1, 1] Axis</span></span>
<span class="line"><span> ┣━ [2, 1] Axis</span></span>
<span class="line"><span> ┣━ [1, 2] Axis</span></span>
<span class="line"><span> ┣━ [2, 2] Axis</span></span>
<span class="line"><span> ┣━ [1, 3] Axis</span></span>
<span class="line"><span> ┣━ [2, 3] Axis</span></span>
<span class="line"><span> ┣━ [1:2, 1] Label</span></span>
<span class="line"><span> ┣━ [2, 1:3] Label</span></span>
<span class="line"><span> ┣━ [1, 3] Label</span></span>
<span class="line"><span> ┣━ [2, 3] Label</span></span>
<span class="line"><span> ┣━ [1, 1] Label</span></span>
<span class="line"><span> ┣━ [1, 2] Label</span></span>
<span class="line"><span> ┣━ [1, 3] Label</span></span>
<span class="line"><span> ┗━ [1:2, 4] Legend</span></span></code></pre></div><p>This <code>[1:2, 1:4]</code> layout has 2 rows and 4 columns, so if we wanted to put something to the right of it, that could live in fifth column and cross over both rows. Let&#39;s execute that idea by specifying the grid position <code>figure[:, 5]</code>. This means all rows, 5th column (which will be created if it doesn&#39;t exist):</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">flipper_spec </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(penguins) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    mapping</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:flipper_length_mm</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Flipper length (mm)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:body_mass_g</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Body mass (g)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, color </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :species</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figuregrid_flipper </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> draw!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figure[:, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">5</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">], flipper_spec)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+p+`" alt="" width="500px" height="300px"></p><p>As you can see, our <code>flipper_spec</code>, while using a color scale, did not create its own legend. AlgebraOfGraphics doesn&#39;t automatically draw legends when <code>draw!</code> is used, because it&#39;s likely that the position should be something special anyway. We could draw the legend by calling <code>legend!(figure[row, col], figuregrid_flipper)</code> but we don&#39;t need it here because it would be redundant. If you skip redundant legends, make sure that they really are the same though, and you didn&#39;t accidentally assign colors differently in one of the graphs!</p><p>Our composed figure is a bit squished, so we could resize again:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">resize!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figure, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">700</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">400</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+k+`" alt="" width="700px" height="400px"></p><h2 id="Layout-modifications" tabindex="-1">Layout modifications <a class="header-anchor" href="#Layout-modifications" aria-label="Permalink to &quot;Layout modifications {#Layout-modifications}&quot;">​</a></h2><p>Maybe we don&#39;t like the position of the shared legend. In Makie, we can move layout elements around whenever we want, we just need to get ahold of them first. We can get the only <code>Legend</code> object in different ways, one would be to get it from the <code>figure.content</code> vector:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">legend </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> only</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">filter</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">-&gt;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> x </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">isa</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Legend, figure</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">content))</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Legend()</span></span></code></pre></div><p>Another way would be to use its layout position <code>[1:2, 4]</code> that we printed above, and grab it with Makie&#39;s <code>content</code> function:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">legend </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> content</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figure[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">:</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">])</span></span></code></pre></div><div class="language- vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang"></span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span>Legend()</span></span></code></pre></div><p>We can move the legend to any other place by assigning it to a new layout position. I want to place it centered below both other plots, for which I will also change its orientation to horizontal:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">legend</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">orientation </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :horizontal</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">legend</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">titleposition </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :left</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">end</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">+</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, :] </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> legend</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+o+`" alt="" width="700px" height="400px"></p><p>The legend has moved correctly, although it has also left a hole in column 4. We can delete that column with the <code>deletecol!</code> function from <code>GridLayoutBase</code>, which is the package that implements Makie&#39;s layouts:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Makie</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">GridLayoutBase</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">deletecol!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figure</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">layout, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+d+`" alt="" width="700px" height="400px"></p><p>To label our two subplots, we can add Makie&#39;s <code>Label</code> objects to our figure. By using the <code>TopLeft()</code> side, we place the labels outside of the main grid and left-aligned into the gap space:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Label</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figure[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">TopLeft</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()], </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;A&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, font </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :bold</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, fontsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 24</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, halign </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :left</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Label</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figure[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">TopLeft</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()], </span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;B&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, font </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :bold</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, fontsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 24</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, halign </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :left</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+r+`" alt="" width="700px" height="400px"></p><p>Maybe the fourth column is a little thin with 25%, we could push it up to 40% to balance out the look:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">colsize!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figure</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">layout, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Relative</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.4</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+g+`" alt="" width="700px" height="400px"></p><h2 id="Axis-modifications" tabindex="-1">Axis modifications <a class="header-anchor" href="#Axis-modifications" aria-label="Permalink to &quot;Axis modifications {#Axis-modifications}&quot;">​</a></h2><p>We haven&#39;t looked at the <code>grid</code> field of <code>figuregrid</code>, yet. It contains <code>AxisEntries</code> objects which store references to all the axes in a plot&#39;s facet layout. So if we want to make some axis modifications after the fact, we can grab them from there, too:</p><p>Let&#39;s pretend that the data in row 2, column 2 of our original facet plot is somehow of high importance, which we&#39;d like to signal with a reddish background color:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figuregrid</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">grid[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">2</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">]</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">axis</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">backgroundcolor </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :rosybrown1</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+c+`" alt="" width="700px" height="400px"></p><p>To explain why we colored one axis red, we can add a small footnote-like <code>Label</code> to the figure:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">Label</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    figure[</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">end</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">+</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, :],</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    rich</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        rich</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;⬛&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, color </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :rosybrown1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, fontsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 18</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">),</span></span>
<span class="line"><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">        &quot; The male penguins on Dream island have to be mentioned specifically.&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        fontsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 10</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ),</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    halign </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :right</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+E+`" alt="" width="700px" height="400px"></p><h2 id="Free-modifications" tabindex="-1">Free modifications <a class="header-anchor" href="#Free-modifications" aria-label="Permalink to &quot;Free modifications {#Free-modifications}&quot;">​</a></h2><p>One last example to really emphasize the flexibility of plotting with Makie and AlgebraOfGraphics. As the <code>Figure</code> is basically just a drawing canvas, we can freely plot into it wherever we want. You could imagine drawing connections between different axes or labels, annotations outside the margins, whatever you can think of.</p><p>Let&#39;s say we wanted to distribute our figure during review, and wanted to mark it as a draft. We can achieve this by plotting a <code>text</code> into the main <code>Scene</code> of the figure, effectively plotting across all other content.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">text!</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(figure</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">scene, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.5</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.5</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, space </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :relative</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, fontsize </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 200</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, text </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;DRAFT&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    color </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:gray</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">0.1</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">), rotation </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> pi</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">/</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">8</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, font </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :bold</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, align </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:center</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:center</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">figure</span></span></code></pre></div><p><img src="`+y+'" alt="" width="700px" height="400px"></p><h2 id="summary" tabindex="-1">Summary <a class="header-anchor" href="#summary" aria-label="Permalink to &quot;Summary&quot;">​</a></h2><p>In this chapter, you have seen how to draw compose multiple AlgebraOfGraphics plots in a Makie <code>Figure</code>, make layout, legend and axis modifications, and achieve even more unusual effects by plotting directly into the figure&#39;s main scene. Making use of all of these options can save you a lot of time that you would otherwise spend editing and re-editing your plots manually. For more techniques and possibilities, refer to sources like <a href="https://docs.makie.org/stable/" target="_blank" rel="noreferrer">Makie&#39;s documentation</a> or the gallery <a href="https://beautiful.makie.org/" target="_blank" rel="noreferrer">Beautiful Makie</a>.</p><p>In the next chapter, we&#39;ll have a look at one more special feature that <code>mapping</code> provides - the ability to have multiple scales of the same aesthetic in one plot.</p>',64)]))}const B=i(u,[["render",F]]);export{A as __pageData,B as default};
