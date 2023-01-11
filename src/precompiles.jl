using SnoopPrecompile

@precompile_setup begin
    df1 = (
        x = rand(40),
        y = rand(40),
        t = repeat(1:10, 4),
        grp2 = [repeat(["A"], 20); repeat(["B"], 20)],
        grp1 = [repeat(["a"], 10); repeat(["b"], 10); 
                repeat(["c"], 10); repeat(["d"], 10)]
    )

    @precompile_all_calls begin
        dta = data(df1)

        dta * mapping(
            :x, :y, color = :grp1, marker = :grp2, row=:grp2
        ) * visual(Scatter) |> draw
   
        dta * mapping(
            :t, :y, color = :grp1, linestyle = :grp2, col=:grp2
        ) * visual(Lines) |> draw
    end
end