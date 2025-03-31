import{_ as a,c as o,o as r,aA as t}from"./chunks/framework.BHupBgA7.js";const u=JSON.parse('{"title":"Changelog","description":"","frontmatter":{},"headers":[],"relativePath":"changelog.md","filePath":"changelog.md","lastUpdated":null}'),l={name:"changelog.md"};function i(c,e,n,d,s,h){return r(),o("div",null,e[0]||(e[0]=[t('<h1 id="changelog" tabindex="-1">Changelog <a class="header-anchor" href="#changelog" aria-label="Permalink to &quot;Changelog&quot;">​</a></h1><h2 id="unreleased" tabindex="-1">Unreleased <a class="header-anchor" href="#unreleased" aria-label="Permalink to &quot;Unreleased&quot;">​</a></h2><ul><li><p>Added better error messages for the common case of failing to construct single element NamedTuples in calls like <code>draw(axis = (key = value))</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/630" target="_blank" rel="noreferrer">#630</a>.</p></li><li><p>Fixed bug when color or markersize mappings had singular limits by expanding the limits to <code>(0, v)</code>, <code>(-v, 0)</code> or <code>(0, 1)</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/634" target="_blank" rel="noreferrer">#634</a>.</p></li></ul><h2 id="v0.10.0-2025-03-30" tabindex="-1">v0.10.0 - 2025-03-30 <a class="header-anchor" href="#v0.10.0-2025-03-30" aria-label="Permalink to &quot;v0.10.0 - 2025-03-30 {#v0.10.0-2025-03-30}&quot;">​</a></h2><ul><li><p><strong>Breaking</strong>: The <code>colorbar!</code> function now returns a <code>Vector{Colorbar}</code> with zero or more entries. Before it would return <code>Union{Nothing,Colorbar}</code>, but now it&#39;s possible to draw more than one colorbar if there are multiple colorscales <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/628" target="_blank" rel="noreferrer">#628</a>.</p></li><li><p><strong>Breaking</strong>: <code>filled_contours</code> does not create a legend by default but a colorbar. The colorbar can be disabled again by setting, e.g., <code>scales(Color = (; colorbar = false))</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/628" target="_blank" rel="noreferrer">#628</a>.</p></li><li><p><strong>Breaking</strong>: Changed the behavior of the <code>from_continuous</code> palette in combination with a scale consisting of <code>Bin</code>s. Colors will now be sampled relative to the positions of their bins&#39; midpoints, meaning that smaller bins that lie closer together have more similar colors. The previous behavior with colors sampled evenly can be regained by using <code>from_continuous(cmap; relative = false)</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/628" target="_blank" rel="noreferrer">#628</a>.</p></li><li><p>Added the ability to display a colorbar for categorical color scales. The colorbar normally consists of evenly spaced, labelled sections, one for each category. In the special case that the data values of the categorical scale are of type <code>Bin</code>, the colorbar displays each bin&#39;s color at the correct numerical positions <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/628" target="_blank" rel="noreferrer">#628</a>.</p></li><li><p>Added the <code>clipped</code> function which is primarily meant to set highclip and lowclip colors on top of categorical color palettes, for use with categorical scales with <code>Bin</code>s if those bins extend to plus/minus infinity <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/628" target="_blank" rel="noreferrer">#628</a>.</p></li></ul><h2 id="v0.9.7-2025-03-28" tabindex="-1">v0.9.7 - 2025-03-28 <a class="header-anchor" href="#v0.9.7-2025-03-28" aria-label="Permalink to &quot;v0.9.7 - 2025-03-28 {#v0.9.7-2025-03-28}&quot;">​</a></h2><ul><li><p>Added <code>wrapped</code> convenience function for the <code>Layout</code> scale palette which allows to cap either rows or columns and change layout direction <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/625" target="_blank" rel="noreferrer">#625</a>.</p></li><li><p>Replaced unnecessary <code>show_labels</code> keyword for <code>Row</code>, <code>Col</code> and <code>Layout</code> scales with</p></li><li><p>Fixed hiding of duplicate axis labels in unlinked layouts of either only col or only row <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/623" target="_blank" rel="noreferrer">#623</a>.</p></li></ul><h2 id="v0.9.6-2025-03-26" tabindex="-1">v0.9.6 - 2025-03-26 <a class="header-anchor" href="#v0.9.6-2025-03-26" aria-label="Permalink to &quot;v0.9.6 - 2025-03-26 {#v0.9.6-2025-03-26}&quot;">​</a></h2><ul><li><p>Added support for input data with units attached, either through Unitful.jl or DynamicQuantities.jl extensions, available from Julia 1.9 on <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/619" target="_blank" rel="noreferrer">#619</a>.</p></li><li><p>The provisional <code>MarkerSize</code> tick calculation method is replaced with Makie&#39;s default tick finder <code>WilkinsonTicks</code>. Ticks and tickformat can be changed using the new <code>ticks</code> and <code>tickformat</code> scale options <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/621" target="_blank" rel="noreferrer">#621</a>.</p></li><li><p>Added <code>plottype</code> argument to <code>histogram</code> to allow for different plot types <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/591" target="_blank" rel="noreferrer">#591</a>.</p></li></ul><h2 id="v0.9.5-2025-03-14" tabindex="-1">v0.9.5 - 2025-03-14 <a class="header-anchor" href="#v0.9.5-2025-03-14" aria-label="Permalink to &quot;v0.9.5 - 2025-03-14 {#v0.9.5-2025-03-14}&quot;">​</a></h2><ul><li>Added <code>mergeable(layer.plottype, layer.primary)</code> function, intended for extension by third-party packages that define recipes <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/592" target="_blank" rel="noreferrer">#592</a>.</li></ul><h2 id="v0.9.4-2025-03-08" tabindex="-1">v0.9.4 - 2025-03-08 <a class="header-anchor" href="#v0.9.4-2025-03-08" aria-label="Permalink to &quot;v0.9.4 - 2025-03-08 {#v0.9.4-2025-03-08}&quot;">​</a></h2><ul><li>Added internal copy of the Palmer Penguins dataset to AoG to reduce friction in the intro tutorials, accessible via the <code>AlgebraOfGraphics.penguins()</code> function <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/613" target="_blank" rel="noreferrer">#613</a>.</li></ul><h2 id="v0.9.3-2025-02-12" tabindex="-1">v0.9.3 - 2025-02-12 <a class="header-anchor" href="#v0.9.3-2025-02-12" aria-label="Permalink to &quot;v0.9.3 - 2025-02-12 {#v0.9.3-2025-02-12}&quot;">​</a></h2><ul><li>Fixed use of <code>from_continuous</code> with colormap specifications like <code>(colormap, alpha)</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/603" target="_blank" rel="noreferrer">#603</a>.</li></ul><h2 id="v0.9.2-2025-02-03" tabindex="-1">v0.9.2 - 2025-02-03 <a class="header-anchor" href="#v0.9.2-2025-02-03" aria-label="Permalink to &quot;v0.9.2 - 2025-02-03 {#v0.9.2-2025-02-03}&quot;">​</a></h2><ul><li>Fixed <code>data(...) * mapping(col =&gt; func =&gt; label =&gt; scale)</code> label-extraction bug <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/596" target="_blank" rel="noreferrer">#596</a>.</li></ul><h2 id="v0.9.1-2025-01-31" tabindex="-1">v0.9.1 - 2025-01-31 <a class="header-anchor" href="#v0.9.1-2025-01-31" aria-label="Permalink to &quot;v0.9.1 - 2025-01-31 {#v0.9.1-2025-01-31}&quot;">​</a></h2><ul><li>Fixed passing <code>axis</code> keyword to <code>draw(::Pagination, ...)</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/595" target="_blank" rel="noreferrer">#595</a>.</li></ul><h2 id="v0.9.0-2025-01-30" tabindex="-1">v0.9.0 - 2025-01-30 <a class="header-anchor" href="#v0.9.0-2025-01-30" aria-label="Permalink to &quot;v0.9.0 - 2025-01-30 {#v0.9.0-2025-01-30}&quot;">​</a></h2><ul><li><strong>Breaking</strong>: <code>paginate</code> now splits facet plots into pages <em>after</em> fitting scales and not <em>before</em> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/593" target="_blank" rel="noreferrer">#593</a>. This means that, e.g., categorical color mappings are consistent across pages where before each page could have a different mapping if some groups were not represented on a given page. This change also makes pagination work with the split X and Y scales feature enabled by version 0.8.14. <code>paginate</code>&#39;s return type changes from <code>PaginatedLayers</code> to <code>Pagination</code> because no layers are stored in that type anymore. The interface to use <code>Pagination</code> with <code>draw</code> and other functions doesn&#39;t change compared to <code>PaginatedLayers</code>. <code>paginate</code> now also accepts an optional second positional argument which are the scales that are normally passed to <code>draw</code> when not paginating, but which must be available prior to pagination to fit all scales accordingly.</li></ul><h2 id="v0.8.14-2025-01-16" tabindex="-1">v0.8.14 - 2025-01-16 <a class="header-anchor" href="#v0.8.14-2025-01-16" aria-label="Permalink to &quot;v0.8.14 - 2025-01-16 {#v0.8.14-2025-01-16}&quot;">​</a></h2><ul><li><p>Added automatic <code>alpha</code> forwarding to all legend elements which will have an effect from Makie 0.22.1 on <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/588" target="_blank" rel="noreferrer">#588</a>.</p></li><li><p>Added the ability to use multiple different X and Y scales within one facet layout. The requirement is that not more than one X and Y scale is used per facet. <code>Row</code>, <code>Col</code> and <code>Layout</code> scales got the ability to set <code>show_labels = false</code> in <code>scales</code>. Also added the <code>zerolayer</code> function which can be used as a basis to build up the required mappings iteratively <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/586" target="_blank" rel="noreferrer">#586</a>.</p></li><li><p>Increased compat to Makie 0.22 and GeometryBasics 0.5 <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/587" target="_blank" rel="noreferrer">#587</a>.</p></li><li><p>Increased compat to Colors 0.13 <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/589" target="_blank" rel="noreferrer">#589</a>.</p></li></ul><h2 id="v0.8.13-2024-10-21" tabindex="-1">v0.8.13 - 2024-10-21 <a class="header-anchor" href="#v0.8.13-2024-10-21" aria-label="Permalink to &quot;v0.8.13 - 2024-10-21 {#v0.8.13-2024-10-21}&quot;">​</a></h2><ul><li>Added aesthetics for <code>Stairs</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/573" target="_blank" rel="noreferrer">#573</a>.</li></ul><h2 id="v0.8.12-2024-10-07" tabindex="-1">v0.8.12 - 2024-10-07 <a class="header-anchor" href="#v0.8.12-2024-10-07" aria-label="Permalink to &quot;v0.8.12 - 2024-10-07 {#v0.8.12-2024-10-07}&quot;">​</a></h2><ul><li>Added <code>legend</code> keyword in <code>visual</code> to allow overriding legend element attributes <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/570" target="_blank" rel="noreferrer">#570</a>.</li></ul><h2 id="v0.8.11-2024-09-25" tabindex="-1">v0.8.11 - 2024-09-25 <a class="header-anchor" href="#v0.8.11-2024-09-25" aria-label="Permalink to &quot;v0.8.11 - 2024-09-25 {#v0.8.11-2024-09-25}&quot;">​</a></h2><ul><li>Fixed lexicographic natural sorting of tuples (this would fall back to default sort order before) <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/568" target="_blank" rel="noreferrer">#568</a>.</li></ul><h2 id="v0.8.10-2024-09-24" tabindex="-1">v0.8.10 - 2024-09-24 <a class="header-anchor" href="#v0.8.10-2024-09-24" aria-label="Permalink to &quot;v0.8.10 - 2024-09-24 {#v0.8.10-2024-09-24}&quot;">​</a></h2><ul><li>Fixed markercolor in <code>ScatterLines</code> legends when it did not match <code>color</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/567" target="_blank" rel="noreferrer">#567</a>.</li></ul><h2 id="v0.8.9-2024-09-24" tabindex="-1">v0.8.9 - 2024-09-24 <a class="header-anchor" href="#v0.8.9-2024-09-24" aria-label="Permalink to &quot;v0.8.9 - 2024-09-24 {#v0.8.9-2024-09-24}&quot;">​</a></h2><ul><li>Added ability to include layers in the legend without using scales by adding <code>visual(label = &quot;some label&quot;)</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/565" target="_blank" rel="noreferrer">#565</a>.</li></ul><h2 id="v0.8.8-2024-09-17" tabindex="-1">v0.8.8 - 2024-09-17 <a class="header-anchor" href="#v0.8.8-2024-09-17" aria-label="Permalink to &quot;v0.8.8 - 2024-09-17 {#v0.8.8-2024-09-17}&quot;">​</a></h2><ul><li><p>Fixed aesthetics of <code>errorbar</code> so that x and y stay labelled correctly when using <code>direction = :x</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/560" target="_blank" rel="noreferrer">#560</a>.</p></li><li><p>Added ability to specify <code>title</code>, <code>subtitle</code> and <code>footnotes</code> plus settings in the <code>draw</code> function <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/556" target="_blank" rel="noreferrer">#556</a>.</p></li><li><p>Added <code>dodge_x</code> and <code>dodge_y</code> keywords to <code>mapping</code> that allow to dodge any plot types that have <code>AesX</code> or <code>AesY</code> data <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/558" target="_blank" rel="noreferrer">#558</a>.</p></li></ul><h2 id="v0.8.7-2024-09-06" tabindex="-1">v0.8.7 - 2024-09-06 <a class="header-anchor" href="#v0.8.7-2024-09-06" aria-label="Permalink to &quot;v0.8.7 - 2024-09-06 {#v0.8.7-2024-09-06}&quot;">​</a></h2><ul><li><p>Added ability to return <code>ProcessedLayers</code> from transformations, thereby enabling multi-layer transformations, such as scatter plus errorbars <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/549" target="_blank" rel="noreferrer">#549</a>.</p></li><li><p>Fixed bug where <code>mergesorted</code> applied on string vectors used <code>isless</code> instead of natural sort <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/553" target="_blank" rel="noreferrer">#553</a>.</p></li></ul><h2 id="v0.8.6-2024-09-02" tabindex="-1">v0.8.6 - 2024-09-02 <a class="header-anchor" href="#v0.8.6-2024-09-02" aria-label="Permalink to &quot;v0.8.6 - 2024-09-02 {#v0.8.6-2024-09-02}&quot;">​</a></h2><ul><li><p>Added <code>bar_labels</code> to <code>BarPlot</code>&#39;s aesthetic mapping <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/544" target="_blank" rel="noreferrer">#544</a>.</p></li><li><p>Added ability to hide legend or colorbar by passing, e.g., <code>legend = (; show = false)</code> to <code>draw</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/547" target="_blank" rel="noreferrer">#547</a>.</p></li></ul><h2 id="v0.8.5-2024-08-27" tabindex="-1">v0.8.5 - 2024-08-27 <a class="header-anchor" href="#v0.8.5-2024-08-27" aria-label="Permalink to &quot;v0.8.5 - 2024-08-27 {#v0.8.5-2024-08-27}&quot;">​</a></h2><ul><li><p>Added <code>presorted</code> helper function to keep categorical data in the order encountered in the source table, instead of sorting it alphabetically <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/529" target="_blank" rel="noreferrer">#529</a>.</p></li><li><p>Added <code>from_continuous</code> helper function which allows to sample continuous colormaps evenly to use them as categorical palettes without having to specify how many categories there are <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/541" target="_blank" rel="noreferrer">#541</a>.</p></li></ul><h2 id="v0.8.4-2024-08-26" tabindex="-1">v0.8.4 - 2024-08-26 <a class="header-anchor" href="#v0.8.4-2024-08-26" aria-label="Permalink to &quot;v0.8.4 - 2024-08-26 {#v0.8.4-2024-08-26}&quot;">​</a></h2><ul><li><p>Added <code>fillto</code> to <code>BarPlot</code> aesthetics <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/535" target="_blank" rel="noreferrer">#535</a>.</p></li><li><p>Fixed bug when giving <code>datalimits</code> of <code>density</code> as a (low, high) tuple <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/536" target="_blank" rel="noreferrer">#536</a>.</p></li><li><p>Fixed bug where facet-local continuous scale limits were used instead of the globally merged ones, possibly leading to mismatches between data and legend <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/539" target="_blank" rel="noreferrer">#539</a>.</p></li></ul><h2 id="v0.8.3-2024-08-23" tabindex="-1">v0.8.3 - 2024-08-23 <a class="header-anchor" href="#v0.8.3-2024-08-23" aria-label="Permalink to &quot;v0.8.3 - 2024-08-23 {#v0.8.3-2024-08-23}&quot;">​</a></h2><ul><li>Fixed incorrect x/y axis assignment for the <code>violin</code> plot type <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/528" target="_blank" rel="noreferrer">#528</a>.</li></ul><h2 id="v0.8.2-2024-08-21" tabindex="-1">v0.8.2 - 2024-08-21 <a class="header-anchor" href="#v0.8.2-2024-08-21" aria-label="Permalink to &quot;v0.8.2 - 2024-08-21 {#v0.8.2-2024-08-21}&quot;">​</a></h2><ul><li><p>Enable use of <code>LaTeXString</code>s and <code>rich</code> text in <code>renamer</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/525" target="_blank" rel="noreferrer">#525</a>.</p></li><li><p>Fixed widths of boxplots with color groupings <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/524" target="_blank" rel="noreferrer">#524</a>.</p></li></ul><h2 id="v0.8.1-2024-08-20" tabindex="-1">v0.8.1 - 2024-08-20 <a class="header-anchor" href="#v0.8.1-2024-08-20" aria-label="Permalink to &quot;v0.8.1 - 2024-08-20 {#v0.8.1-2024-08-20}&quot;">​</a></h2><ul><li>Added back support for <code>Hist</code>, <code>CrossBar</code>, <code>ECDFPlot</code> and <code>Density</code> <a href="https://github.com/MakieOrg/AlgebraOfGraphics.jl/pull/522" target="_blank" rel="noreferrer">#522</a>.</li></ul><h2 id="v0.8.0-2024-07-26" tabindex="-1">v0.8.0 - 2024-07-26 <a class="header-anchor" href="#v0.8.0-2024-07-26" aria-label="Permalink to &quot;v0.8.0 - 2024-07-26 {#v0.8.0-2024-07-26}&quot;">​</a></h2><ul><li><p><strong>Breaking</strong>: Columns with element types of <code>Union{Missing,T}</code> are not treated as categorical by default anymore, instead <code>T</code> decides if data is seen as categorical, continuous or geometrical. If you relied on numerical vectors with <code>missing</code>s being treated as categorical, you can use <code>:columnname =&gt; nonnumeric</code> in the <code>mapping</code> instead.</p></li><li><p><strong>Breaking</strong>: <code>AbstractString</code> categories are now sorted with natural sort order by default. This means that where you got <code>[&quot;1&quot;, &quot;10&quot;, &quot;2&quot;]</code> before, you now get <code>[&quot;1&quot;, &quot;2&quot;, &quot;10&quot;]</code>. You can use <code>sorter</code>, the <code>categories</code> keyword or categorical arrays to sort your data differently if needed.</p></li></ul><h2 id="v0.7.0-2024-07-16" tabindex="-1">v0.7.0 - 2024-07-16 <a class="header-anchor" href="#v0.7.0-2024-07-16" aria-label="Permalink to &quot;v0.7.0 - 2024-07-16 {#v0.7.0-2024-07-16}&quot;">​</a></h2><ul><li><p><strong>Breaking</strong>: The <code>palette</code> keyword of <code>draw</code> linking palettes to keyword arguments was removed. Instead, palettes need to be passed to specific scales like <code>draw(..., scales(Color = (; palette = :Set1_3)))</code></p></li><li><p><strong>Breaking</strong>: All recipes need to have the new function <code>aesthetic_mapping</code> defined for all sets of positional arguments that should be supported, as can be seen in <code>src/aesthetics.jl</code>. This breaks usage of all custom recipes. Additionally, not all Makie plots have been ported to the new system yet. If you encounter missing plots, or missing attributes of already ported plots, please open an issue.</p></li><li><p><strong>Breaking</strong>: All custom recipes that should be displayed in a legend, need to have <code>legend_elements(P, attributes, scale_args)</code> defined as can be seen in <code>src/guides/legend.jl</code>. AlgebraOfGraphics cannot use the same default mechanism as Makie, which can create a legend from an existing plot, because AlgebraOfGraphics needs to create the legend before the plot is instantiated.</p></li><li><p><strong>Breaking</strong>: Pregrouped data cannot be passed anymore to the plain <code>mapping(...)</code> without any <code>data(tabular)</code>. Instead, you should use <code>pregrouped(...)</code> which is a shortcut for <code>data(Pregrouped()) * mapping(...)</code>.</p></li><li><p><strong>Breaking</strong>: <code>Contour</code> and <code>Contourf</code> generally do not work anymore with <code>visual()</code>. Instead, the <code>contours()</code> and <code>filled_contours()</code> analyses should be used. <code>Contour</code> can still be used with categorical colors, but not with continuous ones.</p></li><li><p><strong>Breaking</strong>: All colormap properties for continuous color scales need to be passed via <code>scales</code> now, and not through <code>visual</code>. This is to have central control over the scale as it can be used by multiple <code>visual</code>s simultaneously.</p></li><li><p>Horizontal barplots, violins, errorbars, rangebars and other plot types that have two different orientations work correctly now. Axis labels switch accordingly when the orientation is changed.</p></li><li><p>Plotting functions whose positional arguments don&#39;t correspond to X, Y, Z work correctly now. For example, <code>HLines</code> (1 =&gt; Y) or <code>rangebars</code> (1 =&gt; X, 2 =&gt; Y, 3 =&gt; Y).</p></li><li><p>It is possible to add categories beyond those present in the data with the <code>categories</code> keyword within a scale&#39;s settings. It is also possible to reorder or otherwise transform the existing categories by passing a function to <code>categories</code>.</p></li><li><p>The supported attributes are not limited anymore to a specific set of names, for example, <code>strokecolor</code> can work the same as <code>color</code> did before, and the two can share a scale via their shared aesthetic type.</p></li><li><p>There can be multiple scales of the same aesthetic now. This allows to have separate legends for different plot types using the same aesthetics. Scale separation works by pairing a variable in <code>mapping</code> with a <code>scale(id_symbol)</code>.</p></li><li><p>Legend entries can be reordered using the <code>legend = (; order = ...)</code> option in <code>draw</code>. Specific scales can opt out of the legend by passing <code>legend = false</code> in <code>scales</code>.</p></li><li><p>Labels can now be anything that Makie supports, primarily <code>String</code>s, <code>LaTeXString</code>s or <code>rich</code> text.</p></li><li><p>Legend elements now usually reflect all attributes set in their corresponding <code>visual</code>.</p></li><li><p>Simple column vectors of data can now be passed directly to <code>mapping</code> without using <code>data</code> first. Additionally, scalar values are accepted as a shortcut for columns with the same repeated value.</p></li><li><p>Columns from outside a table source in <code>data</code> can now be passed to <code>mapping</code> by wrapping them in the <code>direct</code> function. Scalar values are accepted as a shortcut for columns with the same repeated value. For example, to create a label for columns <code>x</code> and <code>y</code> from a dataframe passed to <code>data</code>, one could now do <code>mapping(:x, :y, color = direct(&quot;label&quot;))</code> without having to create a column full of <code>&quot;label&quot;</code> strings first.</p></li><li><p>The numbers at which categorical values are plotted on x and y axis can now be changed via <code>scales(X = (; palette = [1, 2, 4]))</code> or similar.</p></li><li><p>Continuous marker size scales can now be shown in the legend. Numerical values are proportional to area and not diameter now, which makes more sense with respect to human perception. The min and max marker size can be set using the <code>sizerange</code> property for the respective scale in <code>scales</code>.</p></li></ul><h2 id="v0.6.11-2022-08-08" tabindex="-1">v0.6.11 - 2022-08-08 <a class="header-anchor" href="#v0.6.11-2022-08-08" aria-label="Permalink to &quot;v0.6.11 - 2022-08-08 {#v0.6.11-2022-08-08}&quot;">​</a></h2><ul><li>Added <code>paginate</code> for pagination of large facet plots.</li></ul><h2 id="v0.6.8-2022-06-14" tabindex="-1">v0.6.8 - 2022-06-14 <a class="header-anchor" href="#v0.6.8-2022-06-14" aria-label="Permalink to &quot;v0.6.8 - 2022-06-14 {#v0.6.8-2022-06-14}&quot;">​</a></h2><ul><li>Added <code>choropleth</code> recipe to supersede <code>geodata</code> for geographical data.</li></ul><h2 id="v0.6.1-2022-01-28" tabindex="-1">v0.6.1 - 2022-01-28 <a class="header-anchor" href="#v0.6.1-2022-01-28" aria-label="Permalink to &quot;v0.6.1 - 2022-01-28 {#v0.6.1-2022-01-28}&quot;">​</a></h2><ul><li><p>Support <code>level</code> in <code>linear</code> analysis for confidence interval.</p></li><li><p>Replaced tuples and named tuples in <code>Layer</code> and <code>Entry</code> with dictionaries from <a href="https://github.com/andyferris/Dictionaries.jl" target="_blank" rel="noreferrer">Dictionaries.jl</a>.</p></li><li><p>Split internal <code>Entry</code> type into <code>ProcessedLayer</code> (to be used for analyses) and <code>Entry</code> (to be used for plotting).</p></li></ul><h2 id="v0.6.0-2021-10-24" tabindex="-1">v0.6.0 - 2021-10-24 <a class="header-anchor" href="#v0.6.0-2021-10-24" aria-label="Permalink to &quot;v0.6.0 - 2021-10-24 {#v0.6.0-2021-10-24}&quot;">​</a></h2><ul><li><p><strong>Breaking</strong>: Default axis linking behavior has changed: now only axes corresponding to the same variable are linked. For consistency with <code>row</code>/<code>col</code>, <code>layout</code> will hide decorations of linked axes and span axis labels if appropriate.</p></li><li><p>Customizable legend and colorbar position and look.</p></li><li><p>Customizable axis linking behavior.</p></li></ul><h2 id="v0.5-2021-08-05" tabindex="-1">v0.5 - 2021-08-05 <a class="header-anchor" href="#v0.5-2021-08-05" aria-label="Permalink to &quot;v0.5 - 2021-08-05 {#v0.5-2021-08-05}&quot;">​</a></h2><ul><li><p><strong>Breaking</strong>: <code>Axis(ae)</code> has been replaced by <code>ae.axis</code>.</p></li><li><p><strong>Breaking</strong>: <code>Legend(fg)</code> has been replaced by <code>legend!(fg)</code> and <code>colorbar!(fg)</code>.</p></li><li><p><code>legend!</code> and <code>colorbar!</code> API allows for custom legend placement.</p></li></ul><h2 id="v0.4-2021-05-21" tabindex="-1">v0.4 - 2021-05-21 <a class="header-anchor" href="#v0.4-2021-05-21" aria-label="Permalink to &quot;v0.4 - 2021-05-21 {#v0.4-2021-05-21}&quot;">​</a></h2><ul><li><p><strong>Breaking</strong>: Removed deprecations for <code>style</code> and <code>spec</code> (now only <code>mapping</code> and <code>visual</code> are allowed).</p></li><li><p><strong>Breaking</strong>: Analyses now require parentheses (i.e. <code>linear()</code> instead of <code>linear</code>).</p></li><li><p><strong>Breaking</strong>: Rename <code>layout_x</code> and <code>layout_y</code> to <code>col</code> and <code>row</code>.</p></li><li><p><strong>Breaking</strong>: Rename <code>wts</code> keyword argument to <code>weights</code>.</p></li><li><p><strong>Breaking</strong>: <code>categorical</code> has been replaced by <code>nonnumeric</code>.</p></li></ul>',65)]))}const g=a(l,[["render",i]]);export{u as __pageData,g as default};
