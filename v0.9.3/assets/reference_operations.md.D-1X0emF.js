import{_ as a,c as i,o,az as t}from"./chunks/framework.Byibden0.js";const u=JSON.parse('{"title":"Algebraic Operations","description":"","frontmatter":{},"headers":[],"relativePath":"reference/operations.md","filePath":"reference/operations.md","lastUpdated":null}'),r={name:"reference/operations.md"};function l(n,e,s,c,d,p){return o(),i("div",null,e[0]||(e[0]=[t('<h1 id="Algebraic-Operations" tabindex="-1">Algebraic Operations <a class="header-anchor" href="#Algebraic-Operations" aria-label="Permalink to &quot;Algebraic Operations {#Algebraic-Operations}&quot;">​</a></h1><p>There are two <em>algebraic types</em> that can be added or multiplied with each other: <a href="/v0.9.3/API/types#AlgebraOfGraphics.Layer"><code>AlgebraOfGraphics.Layer</code></a> and <a href="/v0.9.3/API/types#AlgebraOfGraphics.Layers"><code>AlgebraOfGraphics.Layers</code></a>.</p><h2 id="Multiplication-on-individual-layers" tabindex="-1">Multiplication on individual layers <a class="header-anchor" href="#Multiplication-on-individual-layers" aria-label="Permalink to &quot;Multiplication on individual layers {#Multiplication-on-individual-layers}&quot;">​</a></h2><p>Each layer is composed of data, mappings, and transformations. Datasets can be replaced, mappings can be merged, and transformations can be concatenated. These operations, taken together, define an associative operation on layers, which we call multiplication <code>*</code>.</p><p>Multiplication is primarily useful to combine partially defined layers.</p><h2 id="addition" tabindex="-1">Addition <a class="header-anchor" href="#addition" aria-label="Permalink to &quot;Addition&quot;">​</a></h2><p>The operation <code>+</code> is used to superimpose separate layers. <code>a + b</code> has as many layers as <code>la + lb</code>, where <code>la</code> and <code>lb</code> are the number of layers in <code>a</code> and <code>b</code> respectively.</p><h2 id="Multiplication-on-lists-of-layers" tabindex="-1">Multiplication on lists of layers <a class="header-anchor" href="#Multiplication-on-lists-of-layers" aria-label="Permalink to &quot;Multiplication on lists of layers {#Multiplication-on-lists-of-layers}&quot;">​</a></h2><p>Multiplication naturally extends to lists of layers. Given two <code>Layers</code> objects <code>a</code> and <code>b</code>, containing <code>la</code> and <code>lb</code> layers respectively, the product <code>a * b</code> contains <code>la * lb</code> layers—all possible pair-wise products.</p>',9)]))}const b=a(r,[["render",l]]);export{u as __pageData,b as default};
