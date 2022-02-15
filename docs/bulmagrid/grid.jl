function DemoCards.cardtheme(::Val{:__AlgebraOfGraphics__})

    bulma_grid_section_template = mt"""
    {{{description}}}

    ```@raw html
    <div class="columns is-multiline">
    ```

    {{{cards}}}

    ```@raw html
    </div>
    ```
    """

    bulma_grid_card_template = mt"""
    ```@raw html
    <div class="column is-half">
        <div class="card">
            <div class="card-image">
    ```
    [![card cover image]({{{coverpath}}})](@ref {{id}})
    @raw```
            </div>
            <div class="card-content">
                <h3 class="is-size-5">
                    {{{title}}}
                </h3>
                <p class="is-size-6">
                    {{{description}}}
                </p>
            </div>
        </div>
    </div>
    ```
    """

    templates = Dict(
        "card" => bulma_grid_card_template,
        "section" => bulma_grid_section_template
    )
    return templates, abspath(@__DIR__, "style.css")
end
