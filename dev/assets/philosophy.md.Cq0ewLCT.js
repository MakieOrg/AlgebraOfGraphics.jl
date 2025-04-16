import{_ as a,c as s,o as e,aA as t}from"./chunks/framework.BHupBgA7.js";const n="/dev/assets/bmpurjo.CM3m4x7e.png",l="/dev/assets/cugmbwi.BIQiVKp_.png",u=JSON.parse('{"title":"Philosophy","description":"","frontmatter":{},"headers":[],"relativePath":"philosophy.md","filePath":"philosophy.md","lastUpdated":null}'),h={name:"philosophy.md"};function r(o,i,p,d,k,c){return e(),s("div",null,i[0]||(i[0]=[t(`<h1 id="philosophy" tabindex="-1">Philosophy <a class="header-anchor" href="#philosophy" aria-label="Permalink to &quot;Philosophy&quot;">​</a></h1><p>AlgebraOfGraphics aims to be a declarative, <em>question-driven</em> language for data visualizations. This section describes its main guiding principles.</p><h2 id="From-question-to-plot" tabindex="-1">From question to plot <a class="header-anchor" href="#From-question-to-plot" aria-label="Permalink to &quot;From question to plot {#From-question-to-plot}&quot;">​</a></h2><p>When analyzing a dataset, we often think in abstract, declarative terms. We have <em>questions</em> concerning our data, which can be answered by appropriate visualizations. For instance, we could ask whether a discrete variable <code>:x</code> affects the distribution of a continuous variable <code>:y</code>. We would then like to generate a visualization that answers this question.</p><p>In imperative programming, this would be implemented via the following steps.</p><ol><li><p>Pick the dataset.</p></li><li><p>Divide the dataset into subgroups according to the values of <code>:x</code>.</p></li><li><p>Compute the density of <code>:y</code> on each subgroup.</p></li><li><p>Choose a plot attribute to distinguish subgroups, for instance <code>color</code>.</p></li><li><p>Select as many distinguishable colors as there are unique values of <code>:x</code>.</p></li><li><p>Plot all the density curves on top of each other.</p></li><li><p>Create a legend, describing how unique values of <code>:x</code> are associated to colors.</p></li></ol><p>While the above procedure is certainly feasible, it can introduce a cognitive overhead, especially when more variables and attributes are involved.</p><p>In a declarative framework, the user needs to express the <em>question</em>, and the library will take care of creating the visualization. Let us solve the above problem in a toy dataset.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">plt </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(df) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># declare the dataset</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">plt </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> density</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># declare the analysis</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">plt </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mapping</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:y</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># declare the arguments of the analysis</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">plt </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mapping</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(color </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :x</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># declare the grouping and the respective visual attribute</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">draw</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(plt) </span><span style="--shiki-light:#6A737D;--shiki-dark:#6A737D;"># draw the visualization and its legend</span></span></code></pre></div><p><img src="`+n+`" alt="" width="600px" height="450px"></p><h2 id="No-mind-reading" tabindex="-1">No mind reading <a class="header-anchor" href="#No-mind-reading" aria-label="Permalink to &quot;No mind reading {#No-mind-reading}&quot;">​</a></h2><p>Plotting packages requires the user to specify a large amount of settings. The temptation is then to engineer a plotting library in such a way that it would guess what the user actually wanted. AlgebraOfGraphics follows a different approach, based on algebraic manipulations of plot descriptors.</p><p>The key intuition is that a large fraction of the &quot;clutter&quot; in a plot specification comes from repeating the same information over and over. Different layers of the same plot will share some but not all information, and the user should be able to distinguish settings that are private to a layer from those that are shared across layers.</p><p>We achieve this goal using the distributive properties of addition and multiplication. This is best explained by example. Let us assume that we wish to visually inspect whether a discrete variable <code>:x</code> affects the joint distribution of two continuous variables, <code>:y</code> and <code>:z</code>.</p><p>We would like to have two layers, one with the raw data, the other with an analysis (kernel density estimation).</p><p>Naturally, the axes should represent the same variables (<code>:y</code> and <code>:z</code>) for both layers. Only the density layer should be a contour plot, whereas only the scatter layer should have some transparency and be grouped (according to <code>:x</code>) in different subplots.</p><div class="language-julia vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">julia</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">plt </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> data</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(df) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    (</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        visual</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Scatter, alpha </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 0.3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mapping</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(layout </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> :x</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">+</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">        density</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">() </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> visual</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Contour, colormap </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">=</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> Reverse</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:grays</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">))</span></span>
<span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">    ) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">*</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    mapping</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:y</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">, </span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">:z</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">)</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">draw</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(plt)</span></span></code></pre></div><p><img src="`+l+`" alt="" width="600px" height="450px"></p><p>In this case, thanks to the distributive property, it is clear that the dataset and the positional arguments <code>:y</code>, <code>:z</code> are shared across layers, the transparency and the grouping are specific to the data layer, whereas the <code>density</code> analysis, the <code>Contour</code> visualization, and the choice of color map are specific to the analysis layer.</p><h2 id="User-defined-building-blocks" tabindex="-1">User-defined building blocks <a class="header-anchor" href="#User-defined-building-blocks" aria-label="Permalink to &quot;User-defined building blocks {#User-defined-building-blocks}&quot;">​</a></h2><p>It is common in data analysis tasks to &quot;pipe&quot; a sequence of operations. This became very popular in the data science field with the <code>%&gt;%</code> operator in the R language, and it can allow users to seamlessly compose a sequence of tasks:</p><div class="language-R vp-adaptive-theme"><button title="Copy Code" class="copy"></button><span class="lang">R</span><pre class="shiki shiki-themes github-light github-dark vp-code" tabindex="0"><code><span class="line"><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">df </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">%&gt;%</span></span>
<span class="line"><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;">    filter</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Weight </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">&lt;</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> 3</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">%&gt;%</span></span>
<span class="line"><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">    group_by</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Species) </span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;">%&gt;%</span></span>
<span class="line"><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">    summarise</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(</span><span style="--shiki-light:#E36209;--shiki-dark:#FFAB70;">avg_height</span><span style="--shiki-light:#D73A49;--shiki-dark:#F97583;"> =</span><span style="--shiki-light:#005CC5;--shiki-dark:#79B8FF;"> mean</span><span style="--shiki-light:#24292E;--shiki-dark:#E1E4E8;">(Height))</span></span></code></pre></div><p>Naturally, the alternative would be to create a statement per operation and to assign each intermediate result to its own variable.</p><p>AlgebraOfGraphics is markedly in favor of the latter approach. It is recommended that commonly used <em>building blocks</em> are stored in variables with meaningful names. If we often make a scatter plot with some transparency, we can create a variable <code>transparent_scatter = visual(Scatter, alpha = 0.5)</code> and use it consistently. If some columns of our dataset are always analyzed together, with a similar set of transformations, we can store that information as <code>variables = mapping(variable1 =&gt; f1 =&gt; label1, variable2 =&gt; f2 =&gt; label2)</code>.</p><p>Working over one or more datasets, the user would then create a <em>library</em> of building blocks to be combined with each other with <code>*</code> and <code>+</code>. These two operators allow for a much larger number of possible combinations than just sequential composition, thus fully justifying the extra characters used to name intermediate entities.</p><h2 id="Opinionated-defaults" tabindex="-1">Opinionated defaults <a class="header-anchor" href="#Opinionated-defaults" aria-label="Permalink to &quot;Opinionated defaults {#Opinionated-defaults}&quot;">​</a></h2><p>While users should be able to customize every aspect of their plots, it is important to note that this customization can be very time-consuming, and many subtleties can escape the attention of the casual user:</p><ul><li><p>Is the color palette colorblind-friendly?</p></li><li><p>Would the colors be distinguishable in black and white (when printed)?</p></li><li><p>Is the color gradient perceptually uniform?</p></li><li><p>Are the labels and the ticks legible for readers with low vision?</p></li><li><p>Are the spacing and typographic hierarchies respected?</p></li></ul><p>To remedy this, AlgebraOfGraphics aims to provide solid, opinionated default settings. In particular, it uses a <a href="https://www.nature.com/articles/nmeth.1618?WT.ec_id=NMETH-201106" target="_blank" rel="noreferrer">conservative, colorblind-friendly palette</a> and a <a href="https://www.nature.com/articles/s41467-020-19160-7" target="_blank" rel="noreferrer">perceptually uniform, universally readable color map</a>. It follows <a href="https://www.ibm.com/design/language/typography/type-basics/#titles-and-subtitles" target="_blank" rel="noreferrer">IBM guidelines</a> to differentiate titles and labels from tick labels via font weight, while using the same typeface at a readable size.</p><h2 id="Wide-format-support" tabindex="-1">Wide format support <a class="header-anchor" href="#Wide-format-support" aria-label="Permalink to &quot;Wide format support {#Wide-format-support}&quot;">​</a></h2><p>Finally, AlgebraOfGraphics aims to support many different data formats. Different problems require organizing the data in different formats, and AlgebraOfGraphics should support a wide range of options.</p><p>This is achieved in three different ways. First, the <a href="https://github.com/JuliaData/Tables.jl" target="_blank" rel="noreferrer">Tables interface</a> ensures integration with a large variety of data sources. Second, using the TODO REFLINK Wide data syntax, users can compare many different columns in the same visualization, without having to first reshape the dataset to a long format. Finally, tabular datasets are not a requirement: users may also work directly with TODO REFLINK Pre-grouped data, which are not organized as a table, but rather as a collection of (possibly multi-dimensional) arrays.</p>`,32)]))}const y=a(h,[["render",r]]);export{u as __pageData,y as default};
