import{_ as i,c as a,o as t,az as e}from"./chunks/framework.Ct9LGY9G.js";const l="/previews/PR614/assets/demo_hero.oiCFiX7F.png",c=JSON.parse('{"title":"Welcome to AlgebraOfGraphics!","description":"","frontmatter":{"layout":"home","hero":{"name":"AlgebraOfGraphics","text":null,"tagline":"An algebraic spin on grammar-of-graphics data visualization powered by Makie.jl","image":{"src":"logo.svg","alt":"AlgebraOfGraphics"},"actions":[{"theme":"brand","text":"Getting started","link":"/tutorials/intro-i"},{"theme":"alt","text":"View on Github","link":"https://github.com/MakieOrg/AlgebraOfGraphics.jl"}]}},"headers":[],"relativePath":"index.md","filePath":"index.md","lastUpdated":null}'),n={name:"index.md"};function h(p,s,r,k,o,d){return t(),a("div",null,s[0]||(s[0]=[e(`<h1 id="Welcome-to-AlgebraOfGraphics!" tabindex="-1">Welcome to AlgebraOfGraphics! <a class="header-anchor" href="#Welcome-to-AlgebraOfGraphics!" aria-label="Permalink to &quot;Welcome to AlgebraOfGraphics! {#Welcome-to-AlgebraOfGraphics!}&quot;">​</a></h1><p>AlgebraOfGraphics (AoG) defines a language for data visualization, inspired by the grammar-of-graphics system made popular by the R library <a href="https://ggplot2.tidyverse.org/" target="_blank" rel="noreferrer">ggplot2</a>. It is based on the plotting package <a href="https://docs.makie.org/stable/" target="_blank" rel="noreferrer">Makie.jl</a> which means that most capabilities of Makie are available, and AoG plots can be freely composed with normal Makie figures.</p><h2 id="example" tabindex="-1">Example <a class="header-anchor" href="#example" aria-label="Permalink to &quot;Example&quot;">​</a></h2><p>In AlgebraOfGraphics, a few simple building blocks can be combined using <code>+</code> and <code>*</code> to quickly create complex visualizations, like this:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> AlgebraOfGraphics, CairoMakie</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">spec </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(AlgebraOfGraphics</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">penguins</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">()) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    mapping</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        :bill_length_mm</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Bill length (mm)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        :bill_depth_mm</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Bill depth (mm)&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        color </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :species</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =&gt;</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;"> &quot;Species&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        row </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :sex</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">        col </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :island</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">,</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    (</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">visual</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Scatter, alpha </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 0.3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">+</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> linear</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">())</span></span>
<span class="line"></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">draw</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(spec)</span></span></code></pre></div><img src="`+l+`" style="max-width:640px;width:100%;height:auto;"><h2 id="installation" tabindex="-1">Installation <a class="header-anchor" href="#installation" aria-label="Permalink to &quot;Installation&quot;">​</a></h2><p>You can install AlgebraOfGraphics from the General Registry with the usual Pkg commands:</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">using</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;"> Pkg</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">Pkg</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">.</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">add</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#032F62;--shiki-dark:#9ECBFF;">&quot;AlgebraOfGraphics&quot;</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span></code></pre></div><h2 id="First-steps" tabindex="-1">First steps <a class="header-anchor" href="#First-steps" aria-label="Permalink to &quot;First steps {#First-steps}&quot;">​</a></h2><p>Have a look at the <a href="/previews/PR614/tutorials/intro-i#Intro-to-AoG-I-Fundamentals">Intro to AoG - I - Fundamentals</a> tutorial to get to know AlgebraOfGraphics!</p>`,11)]))}const E=i(n,[["render",h]]);export{c as __pageData,E as default};
