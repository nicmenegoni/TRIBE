function outDir = exportIBSD(R, parentFolder, logLines)
%EXPORTIBSD Save the tables and the figure of a TRIBE analysis.
%   outDir = tribelib.exportIBSD(R, parentFolder) creates a new folder
%   TRIBE_results_<date_time> inside parentFolder (existing files are never
%   overwritten) and saves:
%     TRIBE_results.xlsx  sheets Statistics, Triplets, Sets, Curves (CDF and
%                         CDV on the volume grid) and Options
%     IBSD.png, IBSD.fig  histogram, CDF and CDV
%     TRIBE_results.mat   the results structure R
%     TRIBE_log.txt       the log of the session (if logLines is given)

stamp = char(datetime('now', 'Format', 'yyyyMMdd_HHmmss'));
outDir = fullfile(parentFolder, ['TRIBE_results_' stamp]);
mkdir(outDir);

xls = fullfile(outDir, 'TRIBE_results.xlsx');
writetable(R.tables.Statistics, xls, 'Sheet', 'Statistics');
writetable(R.tables.Triplets, xls, 'Sheet', 'Triplets');
writetable(R.tables.Sets, xls, 'Sheet', 'Sets');
writetable(R.tables.Curves, xls, 'Sheet', 'Curves');
vg = R.opt.volumeGrid;
opts = table({'Spacing file'; 'Formulation'; 'q threshold'; 'Max. combinations (full enumeration)'; ...
    'Monte Carlo combinations'; 'Volume grid'; 'Random seed'; 'TRIBE version'; 'Date'}, ...
    {R.file; R.label; num2str(R.opt.qThreshold); num2str(R.opt.maxExact); num2str(R.opt.nMonteCarlo); ...
    sprintf('%d values from %.3g to %.3g m3 (logarithmic)', numel(vg), min(vg), max(vg)); ...
    num2str(R.opt.seed); R.version; R.date}, 'VariableNames', {'Option', 'Value'});
writetable(opts, xls, 'Sheet', 'Options');

fig = figure('Visible', 'off', 'Color', 'w', 'Units', 'centimeters', 'Position', [2 2 16 18]);
tl = tiledlayout(fig, 2, 1, 'TileSpacing', 'compact', 'Padding', 'compact');
a1 = nexttile(tl);
a2 = nexttile(tl);
tribelib.plotIBSD(a1, a2, R);
exportgraphics(fig, fullfile(outDir, 'IBSD.png'), 'Resolution', 300);
set(fig, 'Visible', 'on');      % so that the .fig file opens visible
savefig(fig, fullfile(outDir, 'IBSD.fig'));
close(fig);

save(fullfile(outDir, 'TRIBE_results.mat'), 'R');
if nargin > 2 && ~isempty(logLines)
    fid = fopen(fullfile(outDir, 'TRIBE_log.txt'), 'w', 'n', 'UTF-8');
    fprintf(fid, '%s\n', string(logLines));
    fclose(fid);
end
end
