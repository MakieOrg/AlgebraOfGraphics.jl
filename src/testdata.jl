# nonmissing rows from Palmer Penguins data, licensed CC0, see https://allisonhorst.github.io/palmerpenguins/
function penguins()
    (;
        species = mapreduce(Base.splat(fill), vcat, [("Adelie", 146), ("Gentoo", 119), ("Chinstrap", 68)]),
        island = mapreduce(Base.splat(fill), vcat, [("Torgersen", 15), ("Biscoe", 10), ("Dream", 19), ("Biscoe", 18), ("Torgersen", 16), ("Dream", 16), ("Biscoe", 16), ("Torgersen", 16), ("Dream", 20), ("Biscoe", 119), ("Dream", 68)]),
        bill_length_mm = [39.1,39.5,40.3,36.7,39.3,38.9,39.2,41.1,38.6,34.6,36.6,38.7,42.5,34.4,46.0,37.8,37.7,35.9,38.2,38.8,35.3,40.6,40.5,37.9,40.5,39.5,37.2,39.5,40.9,36.4,39.2,38.8,42.2,37.6,39.8,36.5,40.8,36.0,44.1,37.0,39.6,41.1,36.0,42.3,39.6,40.1,35.0,42.0,34.5,41.4,39.0,40.6,36.5,37.6,35.7,41.3,37.6,41.1,36.4,41.6,35.5,41.1,35.9,41.8,33.5,39.7,39.6,45.8,35.5,42.8,40.9,37.2,36.2,42.1,34.6,42.9,36.7,35.1,37.3,41.3,36.3,36.9,38.3,38.9,35.7,41.1,34.0,39.6,36.2,40.8,38.1,40.3,33.1,43.2,35.0,41.0,37.7,37.8,37.9,39.7,38.6,38.2,38.1,43.2,38.1,45.6,39.7,42.2,39.6,42.7,38.6,37.3,35.7,41.1,36.2,37.7,40.2,41.4,35.2,40.6,38.8,41.5,39.0,44.1,38.5,43.1,36.8,37.5,38.1,41.1,35.6,40.2,37.0,39.7,40.2,40.6,32.1,40.7,37.3,39.0,39.2,36.6,36.0,37.8,36.0,41.5,46.1,50.0,48.7,50.0,47.6,46.5,45.4,46.7,43.3,46.8,40.9,49.0,45.5,48.4,45.8,49.3,42.0,49.2,46.2,48.7,50.2,45.1,46.5,46.3,42.9,46.1,47.8,48.2,50.0,47.3,42.8,45.1,59.6,49.1,48.4,42.6,44.4,44.0,48.7,42.7,49.6,45.3,49.6,50.5,43.6,45.5,50.5,44.9,45.2,46.6,48.5,45.1,50.1,46.5,45.0,43.8,45.5,43.2,50.4,45.3,46.2,45.7,54.3,45.8,49.8,49.5,43.5,50.7,47.7,46.4,48.2,46.5,46.4,48.6,47.5,51.1,45.2,45.2,49.1,52.5,47.4,50.0,44.9,50.8,43.4,51.3,47.5,52.1,47.5,52.2,45.5,49.5,44.5,50.8,49.4,46.9,48.4,51.1,48.5,55.9,47.2,49.1,46.8,41.7,53.4,43.3,48.1,50.5,49.8,43.5,51.5,46.2,55.1,48.8,47.2,46.8,50.4,45.2,49.9,46.5,50.0,51.3,45.4,52.7,45.2,46.1,51.3,46.0,51.3,46.6,51.7,47.0,52.0,45.9,50.5,50.3,58.0,46.4,49.2,42.4,48.5,43.2,50.6,46.7,52.0,50.5,49.5,46.4,52.8,40.9,54.2,42.5,51.0,49.7,47.5,47.6,52.0,46.9,53.5,49.0,46.2,50.9,45.5,50.9,50.8,50.1,49.0,51.5,49.8,48.1,51.4,45.7,50.7,42.5,52.2,45.2,49.3,50.2,45.6,51.9,46.8,45.7,55.8,43.5,49.6,50.8,50.2],   
        bill_depth_mm = [18.7,17.4,18.0,19.3,20.6,17.8,19.6,17.6,21.2,21.1,17.8,19.0,20.7,18.4,21.5,18.3,18.7,19.2,18.1,17.2,18.9,18.6,17.9,18.6,18.9,16.7,18.1,17.8,18.9,17.0,21.1,20.0,18.5,19.3,19.1,18.0,18.4,18.5,19.7,16.9,18.8,19.0,17.9,21.2,17.7,18.9,17.9,19.5,18.1,18.6,17.5,18.8,16.6,19.1,16.9,21.1,17.0,18.2,17.1,18.0,16.2,19.1,16.6,19.4,19.0,18.4,17.2,18.9,17.5,18.5,16.8,19.4,16.1,19.1,17.2,17.6,18.8,19.4,17.8,20.3,19.5,18.6,19.2,18.8,18.0,18.1,17.1,18.1,17.3,18.9,18.6,18.5,16.1,18.5,17.9,20.0,16.0,20.0,18.6,18.9,17.2,20.0,17.0,19.0,16.5,20.3,17.7,19.5,20.7,18.3,17.0,20.5,17.0,18.6,17.2,19.8,17.0,18.5,15.9,19.0,17.6,18.3,17.1,18.0,17.9,19.2,18.5,18.5,17.6,17.5,17.5,20.1,16.5,17.9,17.1,17.2,15.5,17.0,16.8,18.7,18.6,18.4,17.8,18.1,17.1,18.5,13.2,16.3,14.1,15.2,14.5,13.5,14.6,15.3,13.4,15.4,13.7,16.1,13.7,14.6,14.6,15.7,13.5,15.2,14.5,15.1,14.3,14.5,14.5,15.8,13.1,15.1,15.0,14.3,15.3,15.3,14.2,14.5,17.0,14.8,16.3,13.7,17.3,13.6,15.7,13.7,16.0,13.7,15.0,15.9,13.9,13.9,15.9,13.3,15.8,14.2,14.1,14.4,15.0,14.4,15.4,13.9,15.0,14.5,15.3,13.8,14.9,13.9,15.7,14.2,16.8,16.2,14.2,15.0,15.0,15.6,15.6,14.8,15.0,16.0,14.2,16.3,13.8,16.4,14.5,15.6,14.6,15.9,13.8,17.3,14.4,14.2,14.0,17.0,15.0,17.1,14.5,16.1,14.7,15.7,15.8,14.6,14.4,16.5,15.0,17.0,15.5,15.0,16.1,14.7,15.8,14.0,15.1,15.2,15.9,15.2,16.3,14.1,16.0,16.2,13.7,14.3,15.7,14.8,16.1,17.9,19.5,19.2,18.7,19.8,17.8,18.2,18.2,18.9,19.9,17.8,20.3,17.3,18.1,17.1,19.6,20.0,17.8,18.6,18.2,17.3,17.5,16.6,19.4,17.9,19.0,18.4,19.0,17.8,20.0,16.6,20.8,16.7,18.8,18.6,16.8,18.3,20.7,16.6,19.9,19.5,17.5,19.1,17.0,17.9,18.5,17.9,19.6,18.7,17.3,16.4,19.0,17.3,19.7,17.3,18.8,16.6,19.9,18.8,19.4,19.5,16.5,17.0,19.8,18.1,18.2,19.0,18.7],
        flipper_length_mm = [181,186,195,193,190,181,195,182,191,198,185,195,197,184,194,174,180,189,185,180,187,183,187,172,180,178,178,188,184,195,196,190,180,181,184,182,195,186,196,185,190,182,190,191,186,188,190,200,187,191,186,193,181,194,185,195,185,192,184,192,195,188,190,198,190,190,196,197,190,195,191,184,187,195,189,196,187,193,191,194,190,189,189,190,202,205,185,186,187,208,190,196,178,192,192,203,183,190,193,184,199,190,181,197,198,191,193,197,191,196,188,199,189,189,187,198,176,202,186,199,191,195,191,210,190,197,193,199,187,190,191,200,185,193,193,187,188,190,192,185,190,184,195,193,187,201,211,230,210,218,215,210,211,219,209,215,214,216,214,213,210,217,210,221,209,222,218,215,213,215,215,215,215,210,220,222,209,207,230,220,220,213,219,208,208,208,225,210,216,222,217,210,225,213,215,210,220,210,225,217,220,208,220,208,224,208,221,214,231,219,230,229,220,223,216,221,221,217,216,230,209,220,215,223,212,221,212,224,212,228,218,218,212,230,218,228,212,224,214,226,216,222,203,225,219,228,215,228,215,210,219,208,209,216,229,213,230,217,230,222,214,215,222,212,213,192,196,193,188,197,198,178,197,195,198,193,194,185,201,190,201,197,181,190,195,181,191,187,193,195,197,200,200,191,205,187,201,187,203,195,199,195,210,192,205,210,187,196,196,196,201,190,212,187,198,199,201,193,203,187,197,191,203,202,194,206,189,195,207,202,193,210,198],
        body_mass_g = [3750,3800,3250,3450,3650,3625,4675,3200,3800,4400,3700,3450,4500,3325,4200,3400,3600,3800,3950,3800,3800,3550,3200,3150,3950,3250,3900,3300,3900,3325,4150,3950,3550,3300,4650,3150,3900,3100,4400,3000,4600,3425,3450,4150,3500,4300,3450,4050,2900,3700,3550,3800,2850,3750,3150,4400,3600,4050,2850,3950,3350,4100,3050,4450,3600,3900,3550,4150,3700,4250,3700,3900,3550,4000,3200,4700,3800,4200,3350,3550,3800,3500,3950,3600,3550,4300,3400,4450,3300,4300,3700,4350,2900,4100,3725,4725,3075,4250,2925,3550,3750,3900,3175,4775,3825,4600,3200,4275,3900,4075,2900,3775,3350,3325,3150,3500,3450,3875,3050,4000,3275,4300,3050,4000,3325,3500,3500,4475,3425,3900,3175,3975,3400,4250,3400,3475,3050,3725,3000,3650,4250,3475,3450,3750,3700,4000,4500,5700,4450,5700,5400,4550,4800,5200,4400,5150,4650,5550,4650,5850,4200,5850,4150,6300,4800,5350,5700,5000,4400,5050,5000,5100,5650,4600,5550,5250,4700,5050,6050,5150,5400,4950,5250,4350,5350,3950,5700,4300,4750,5550,4900,4200,5400,5100,5300,4850,5300,4400,5000,4900,5050,4300,5000,4450,5550,4200,5300,4400,5650,4700,5700,5800,4700,5550,4750,5000,5100,5200,4700,5800,4600,6000,4750,5950,4625,5450,4725,5350,4750,5600,4600,5300,4875,5550,4950,5400,4750,5650,4850,5200,4925,4875,4625,5250,4850,5600,4975,5500,5500,4700,5500,4575,5500,5000,5950,4650,5500,4375,5850,6000,4925,4850,5750,5200,5400,3500,3900,3650,3525,3725,3950,3250,3750,4150,3700,3800,3775,3700,4050,3575,4050,3300,3700,3450,4400,3600,3400,2900,3800,3300,4150,3400,3800,3700,4550,3200,4300,3350,4100,3600,3900,3850,4800,2700,4500,3950,3650,3550,3500,3675,4450,3400,4300,3250,3675,3325,3950,3600,4050,3350,3450,3250,4050,3800,3525,3950,3650,3650,4000,3400,3775,4100,3775],
        sex = ["female", "male"][[2,1,1,1,2,1,2,1,2,2,1,1,2,1,2,1,2,1,2,2,1,2,1,1,2,1,2,1,2,1,2,2,1,1,2,1,2,1,2,1,2,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,2,1,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,1,2,1,2,1,2,1,2,2,1,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,1,2,1,2,2,1,2,2,1,1,2,1,2,1,2,1,2,1,2,1,2,2,1,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,2,1,2,2,1,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,1,2,1,2,1,2,2,1,2,1,2,1,2,1,2,1,2,2,1,1,2,1,2,1,2,2,1,2,1,1,2,1,2,1,2,1,2,1,2,2,1,1,2,1,2,1,2,1,2,1,2,1,2,1,2,1,2,2,1,1,2,1,2,2,1,2,1,1,2,1,2,2,1,1,2,1,2,1,2,1,2,2,1,2,1,1,2,1,2,2,1]],
    )
end