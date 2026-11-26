function plotIBSD(axHist, axCum, R)
%PLOTIBSD Histogram, CDF and CDV of the in-situ block size distribution.
%   tribelib.plotIBSD(axHist, axCum, R) draws, for the results R of
%   tribelib.computeIBSD, the histogram of the spacing combinations in
%   logarithmic volume classes (axHist) and the cumulative frequency (CDF)
%   and cumulative volume (CDV) distributions (axCum).

s = R.stats;
vg = R.opt.volumeGrid(:);
cla(axHist);
cla(axCum);

% One class every ten grid values (0.2 log units)
ce = vg(1:10:end);
dn = diff(s.cumN(1:10:end)) * s.N;
histogram(axHist, 'BinEdges', ce', 'BinCounts', dn', 'FaceColor', [0.55 0.55 0.55], 'EdgeColor', 'w');
set(axHist, 'XScale', 'log');
grid(axHist, 'on');
box(axHist, 'on');
if R.info.exact
    ylabel(axHist, 'Number of combinations');
else
    ylabel(axHist, 'Number of sampled combinations');
end
title(axHist, sprintf('IBSD, %s, q > %g (%s)', R.label, R.opt.qThreshold, R.file), ...
    'FontWeight', 'normal', 'Interpreter', 'none');

plot(axCum, vg, 100 * s.cumN, '-', 'Color', [0.16 0.47 0.84], 'LineWidth', 1.8);
hold(axCum, 'on');
plot(axCum, vg, 100 * s.cumV, '-', 'Color', [0.92 0.41 0.20], 'LineWidth', 1.8);
hold(axCum, 'off');
set(axCum, 'XScale', 'log');
grid(axCum, 'on');
box(axCum, 'on');
ylim(axCum, [0 100]);
xlabel(axCum, 'Block volume V_b (m^3)');
ylabel(axCum, 'Cumulative (%)');
legend(axCum, {'CDF (number of blocks)', 'CDV (block volume)'}, 'Location', 'southeast');
txt = {sprintf('Spacings: %d', R.nSpacings), ...
    sprintf('Combinations: %.3g', R.info.nCombinations), ...
    sprintf('Mean: %.3g m^3', s.Mean), ...
    sprintf('Median: %.3g m^3', s.Median), ...
    sprintf('V_{50}: %.3g m^3', s.V50)};
text(axCum, 0.02, 0.97, txt, 'Units', 'normalized', 'VerticalAlignment', 'top', 'FontSize', 9);

xl = [max(vg(1), s.Min / 3), min(vg(end), s.Max * 3)];
xlim(axHist, xl);
xlim(axCum, xl);
end
