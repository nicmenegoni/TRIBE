function R = computeIBSD(D, O, opt)
%COMPUTEIBSD In-situ block size distribution from the spacings of each set.
%   R = tribelib.computeIBSD(D, O) computes the IBSD from the spacings in D
%   (see tribelib.readDICESpacings) and the mean set orientations in O, a
%   table with the columns Set, Dip and DipDirection (degrees) listing the
%   sets to be used. R = tribelib.computeIBSD(D, O, opt) uses the options opt
%   (see tribelib.defaultOptions).
%
%   For every triplet of sets with q > opt.qThreshold, the volume of each
%   combination of one spacing per set is computed as V = S1*S2*S3/g, where
%   g is the non-orthogonality coefficient q (Umili et al., 2024) or the
%   product of the sines of the inter-set angles (Palmström, 2005). The
%   volumes of all the retained triplets form the IBSD.
%
%   R.tables contains the statistics of the IBSD, the geometry of the
%   triplets, the spacings of each set and the CDF and CDV curves.

if nargin < 3 || isempty(opt)
    opt = tribelib.defaultOptions();
end
rng(opt.seed);

% Spacings of the sets listed in O, in the same order
[found, idx] = ismember(O.Set, D.sets);
if ~all(found)
    error('TRIBE:sets', 'No spacing found for the sets: %s', strjoin(O.Set(~found)', ', '));
end
S = D.S(idx(:)');
nSp = cellfun(@numel, S);
if any(nSp == 0)
    error('TRIBE:sets', 'The sets %s have no spacing.', strjoin(O.Set(nSp == 0)', ', '));
end

% Geometry of the triplets and correction factor
G = tribelib.setGeometry(O);
switch lower(opt.formulation)
    case 'umili'
        g = G.q;
        label = 'Umili et al. (2024)';
    case 'palmstrom'
        g = G.palmstrom;
        label = 'Palmström (2005)';
    otherwise
        error('TRIBE:formulation', 'Unknown formulation "%s".', opt.formulation);
end
retained = G.q > opt.qThreshold;
if ~any(retained)
    error('TRIBE:qThreshold', 'No triplet has q > %g. Lower the threshold.', opt.qThreshold);
end
tr = find(retained);

% Block volumes and statistics
[vol, info] = tribelib.ibsdVolumes(S, G.triplets(tr, :), g(tr), opt.maxExact, opt.nMonteCarlo);
st = tribelib.distStats(vol, opt.volumeGrid);
clear vol
if ~info.exact
    st.Mean = tribelib.exactMean(S, G.triplets(tr, :), g(tr));
    st.Leq_mean = st.Mean^(1/3);
end

% Contribution of each triplet (computed analytically from the sums of the spacings)
nT = numel(G.q);
nComb = zeros(nT, 1);
vSum = zeros(nT, 1);
for t = 1:nT
    k = G.triplets(t, :);
    nComb(t) = prod(nSp(k));
    vSum(t) = prod(cellfun(@sum, S(k))) / g(t);
end
share = nan(nT, 1);
share(tr) = 100 * vSum(tr) / sum(vSum(tr));
meanT = vSum ./ nComb;

TB.Statistics = table( ...
    {'Formulation'; 'q threshold'; 'Retained triplets'; 'Number of combinations'; 'Full enumeration'; ...
    'Mean'; 'Standard deviation'; 'Minimum'; 'P10'; 'Median (P50)'; 'P90'; 'P99'; 'Maximum'; ...
    'V50 (CDV)'; 'V80 (CDV)'; 'Leq of the minimum volume'; 'Leq of the mean volume'; 'Leq of the P99 volume'}, ...
    {label; sprintf('%g', opt.qThreshold); char(strjoin(G.name(tr)', ', ')); sprintf('%d', info.nCombinations); ...
    yesno(info.exact); num(st.Mean); num(st.SD); num(st.Min); num(st.P10); num(st.Median); num(st.P90); ...
    num(st.P99); num(st.Max); num(st.V50); num(st.V80); num(st.Leq_min); num(st.Leq_mean); num(st.Leq_P99)}, ...
    {''; ''; ''; ''; ''; 'm3'; 'm3'; 'm3'; 'm3'; 'm3'; 'm3'; 'm3'; 'm3'; 'm3'; 'm3'; 'm'; 'm'; 'm'}, ...
    'VariableNames', {'Statistic', 'Value', 'Unit'});

TB.Triplets = table(G.name, G.q, G.palmstrom, retained, nComb, meanT, share, ...
    'VariableNames', {'Triplet', 'q', 'Palmstrom_factor', 'Retained', 'N_combinations', ...
    'Mean_volume_m3', 'Share_of_volume_perc'});

TB.Sets = table(O.Set, nSp(:), cellfun(@mean, S(:)), cellfun(@median, S(:)), cellfun(@min, S(:)), ...
    cellfun(@max, S(:)), O.Dip, O.DipDirection, ...
    'VariableNames', {'Set', 'N_spacings', 'Mean_spacing_m', 'Median_spacing_m', 'Min_spacing_m', ...
    'Max_spacing_m', 'Dip', 'DipDirection'});

TB.Curves = table(opt.volumeGrid(:), 100 * st.cumN, 100 * st.cumV, ...
    'VariableNames', {'Volume_m3', 'CDF_perc', 'CDV_perc'});

R.version = tribelib.version();
R.date = char(datetime('now'));
R.opt = opt;
R.file = D.file;
R.O = O;
R.G = G;
R.label = label;
R.retained = retained;
R.nSpacings = sum(nSp);
R.info = info;
R.stats = st;
R.tables = TB;
end

function s = num(x)
s = sprintf('%.4g', x);
end

function s = yesno(b)
if b
    s = 'yes';
else
    s = 'no (Monte Carlo sample)';
end
end
