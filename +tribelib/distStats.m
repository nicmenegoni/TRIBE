function st = distStats(v, grid)
%DISTSTATS Number- and volume-weighted statistics of a set of block volumes.
%   st = tribelib.distStats(v, grid) returns:
%     N, Total, Mean, SD, Min, Max
%     P10, Median, P90, P99   percentiles of the number distribution (CDF)
%     V50, V80                volumes below which 50% and 80% of the total
%                             volume is contained (cumulative volume
%                             distribution, CDV)
%     Leq_min, Leq_mean, Leq_P99
%                             side of the cube with the minimum, mean and
%                             P99 volume (equivalent length)
%     cumN, cumV              CDF and CDV evaluated on grid: fraction of
%                             blocks, and of volume, smaller than each value
%   Percentiles use the nearest-rank method.

grid = grid(:);
nG = numel(grid);
st = struct('N', 0, 'Total', NaN, 'Mean', NaN, 'SD', NaN, 'Min', NaN, 'Max', NaN, ...
    'P10', NaN, 'Median', NaN, 'P90', NaN, 'P99', NaN, 'V50', NaN, 'V80', NaN, ...
    'Leq_min', NaN, 'Leq_mean', NaN, 'Leq_P99', NaN, ...
    'cumN', zeros(nG, 1), 'cumV', zeros(nG, 1));
if isempty(v)
    return
end

v = sort(double(v(:)));
n = numel(v);
cs = cumsum(v);
tot = cs(end);
pr = @(p) v(max(1, ceil(p * n)));

st.N = n;
st.Total = tot;
st.Mean = tot / n;
st.SD = std(v);
st.Min = v(1);
st.Max = v(end);
st.P10 = pr(0.10);
st.Median = pr(0.50);
st.P90 = pr(0.90);
st.P99 = pr(0.99);
st.V50 = v(find(cs >= 0.5 * tot, 1));
st.V80 = v(find(cs >= 0.8 * tot, 1));
st.Leq_min = st.Min^(1/3);
st.Leq_mean = st.Mean^(1/3);
st.Leq_P99 = st.P99^(1/3);

c = histcounts(v, [-Inf; grid; Inf]);
kk = cumsum(c(:));
kk = kk(1:nG);                       % kk(i) = number of volumes smaller than grid(i)
st.cumN = kk / n;
st.cumV(kk > 0) = cs(kk(kk > 0)) / tot;
end
