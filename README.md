# TRIBE – TRIplet-based Block size Estimation

[![DOI](https://zenodo.org/badge/DOI/10.5281/zenodo.24558801.svg)](https://doi.org/10.5281/zenodo.24558801)

TRIBE is a MATLAB application that estimates the in-situ block size distribution (IBSD) of a fractured rock mass from the spacings of its discontinuity sets. It needs only two inputs:

1. the spacings of each set, in the format of the DICE output `Spacing_Values_per_set.txt` (Menegoni et al., 2023);
2. the mean orientation (dip and dip direction) of each set.

## Method

For every triplet of sets (i, j, k), TRIBE computes the volume of each combination of one measured spacing per set:

- Umili et al. (2024): V<sub>b</sub> = S<sub>i</sub> S<sub>j</sub> S<sub>k</sub> / q, with q = |n<sub>i</sub> · (n<sub>j</sub> × n<sub>k</sub>)|
- Palmström (2005): V<sub>b</sub> = S<sub>i</sub> S<sub>j</sub> S<sub>k</sub> / (sin γ<sub>ij</sub> sin γ<sub>ik</sub> sin γ<sub>jk</sub>)

where n are the unit normals of the mean set planes and γ the angles between the sets. The non-orthogonality coefficient q is 1 for mutually orthogonal sets and tends to 0 for nearly co-zonal sets, which do not bound closed blocks. Only the triplets with q above a threshold (0.5 by default; 0 retains all of them) are used.

All the combinations are enumerated, so the IBSD describes the complete population of potential blocks defined by the measured spacings. When their number exceeds a user-defined limit (2×10<sup>8</sup> by default), TRIBE draws a Monte Carlo sample from the same distribution and still computes the mean volume exactly.

TRIBE returns:

- the statistics of the block volumes: mean, standard deviation, minimum, P10, median, P90, P99 and maximum of the number distribution, and V50 and V80, the volumes below which 50% and 80% of the total volume is contained;
- the side of the equivalent cube, L<sub>eq</sub> = V<sub>b</sub><sup>1/3</sup>, for the minimum, mean and P99 volumes;
- the cumulative frequency distribution (CDF, by number of blocks) and the cumulative volume distribution (CDV), evaluated on a fixed logarithmic grid of volumes (10<sup>−8</sup> to 10<sup>5</sup> m³);
- for each triplet: q, the Palmström factor, the number of combinations, the mean volume and the share of the total volume.

Because the curves of every run are exported on the same volume grid, IBSDs computed from different datasets (e.g. spacings measured at different scales), or an IBSD and a rockfall block size distribution, can be compared directly by the user.

## Requirements

MATLAB R2021a or later. No toolbox is required. Full enumeration needs about 1 GB of memory for every 10<sup>8</sup> combinations, plus the space needed to sort them.

## Use

**As a MATLAB app.** Install `TRIBE.mlappinstall` (Releases page) and open TRIBE from the Apps tab.

**From the source code.** Add the TRIBE folder to the MATLAB path and type `TRIBE`. Then:

1. load the spacing file;
2. type the dip and dip direction of each set in the table, or load them from a CSV or Excel file with the columns `Set`, `Dip` and `DipDirection`; untick the sets that should not be used (at least three sets are needed);
3. choose the volume formulation and the q threshold, and press *Run*;
4. press *Export results* to save the tables and the figure.

**Without the interface.**

```matlab
D   = tribelib.readDICESpacings('Spacing_Values_per_set.txt');
O   = tribelib.readOrientations('orientations.csv');
opt = tribelib.defaultOptions();        % opt.formulation, opt.qThreshold, ...
R   = tribelib.computeIBSD(D, O, opt);
tribelib.exportIBSD(R, pwd);
```

See `examples/run_example.m`, which uses the synthetic files in `examples/data`.

**Packaging the app.** In MATLAB, open the Apps tab, choose *Package App*, select `TRIBE.m` as the main file, add the `+tribelib` folder and press *Package*.

## Input files

**Spacings.** Text file with the name of each set followed by its spacings in metres, separated by spaces or tabs (the format written by DICE). Sets can have different numbers of spacings, and the values of a set can continue on the following lines.

```
S0	0.450 0.571 0.361 0.221 ...
J1	0.312 0.204 0.472 ...
```

Spacings measured with other tools (e.g. on scan windows in a GIS) can be analysed by writing them in the same format.

**Set orientations** (optional file; the values can also be typed in the interface):

```
Set,Dip,DipDirection
S0,30,150
J1,80,60
```

## Output

*Export results* creates a new folder `TRIBE_results_<date_time>`, so earlier results are never overwritten. It contains `TRIBE_results.xlsx` (sheets Statistics, Triplets, Sets, Curves and Options), the figure `IBSD.png`/`IBSD.fig`, the results structure `TRIBE_results.mat` and the log of the session.

## Notes on interpretation

- The IBSD assumes fully persistent discontinuities and depends on the scale and resolution at which the discontinuities were mapped.
- The mean volume is controlled by the upper tail of the distribution and therefore by a few large spacings. The median and the volume-weighted percentiles V50 and V80 are more robust descriptors.

## Citation

If you use TRIBE, please cite:

Foletti, M.G., Menegoni, N., Testa, G., Poggi, E., Benedetti, G., Comedini, M., Zucca, F., Perotti, C., Elmo, D., Giordan, D., Bellini, V., Seno, S., Maino, M. Estimating rock block volume using drone and open-source fractured rock mass characterization tools. *Engineering Geology* (submitted).

and the software:

Foletti, M.G., Menegoni, N. (2026). TRIBE: TRIplet-based Block size Estimation (v1.0.0). Zenodo. https://doi.org/10.5281/zenodo.24558801

## References

- Menegoni, N., Giordan, D., Inama, R., & Perotti, C. (2023). DICE: An open-source MATLAB application for quantification and parametrization of digital outcrop model-based fracture datasets. *Journal of Rock Mechanics and Geotechnical Engineering*, 15(5), 1090–1110. https://doi.org/10.1016/j.jrmge.2022.09.011
- Palmström, A. (2005). Measurements of and correlations between block size and rock quality designation (RQD). *Tunnelling and Underground Space Technology*, 20(4), 362–377. https://doi.org/10.1016/j.tust.2005.01.005
- Umili, G., Carriero, M. T., Taboni, B., Migliazza, M. R., & Ferrero, A. M. (2024). A new analytical solution for calculating rock block volume. *Rock Mechanics and Rock Engineering*, 57(5), 3109–3120. https://doi.org/10.1007/s00603-023-03728-y

## License

MIT License, see `LICENSE`.
