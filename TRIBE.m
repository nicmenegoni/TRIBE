classdef TRIBE < handle
    %TRIBE TRIplet-based Block size Estimation.
    %   TRIBE opens the graphical interface for the estimation of the in-situ
    %   block size distribution (IBSD) from the spacings of the discontinuity
    %   sets. Two inputs are needed:
    %     1. the spacings of each set, in the format of the DICE output
    %        Spacing_Values_per_set.txt (set name followed by its spacings);
    %     2. the mean orientation (dip, dip direction) of each set, typed in
    %        the table or loaded from a CSV/Excel file.
    %   For every triplet of sets with q above the threshold, the volume of each
    %   combination of one spacing per set is computed with the formulation of
    %   Umili et al. (2024) or Palmström (2005). TRIBE returns the statistics of
    %   the volumes, the cumulative frequency (CDF) and cumulative volume (CDV)
    %   distributions and the contribution of each triplet. Results can be
    %   exported to Excel, so that different IBSDs, or an IBSD and a rockfall
    %   block size distribution, can be compared by the user.
    %
    %   The same calculation can be scripted with tribelib.readDICESpacings and
    %   tribelib.computeIBSD (see examples/run_example.m).
    %
    %   Requires MATLAB R2021a or later; no toolbox is needed.

    properties (Access = public)
        UIFigure
    end

    properties (Access = private)
        LblFile
        TblSets
        DdForm
        EdQ
        EdMaxExact
        EdNMC
        BtnRun
        BtnExport
        TblStats
        TblTrip
        AxHist
        AxCum
        TabResults
        Tabs
        TxtLog
        Spacing = []
        Results = []
    end

    methods (Access = public)
        function app = TRIBE()
            app.buildUI();
            app.addLog(sprintf(['TRIBE %s ready. Load the DICE spacing file, enter the mean ' ...
                'orientation of the sets and press Run.'], tribelib.version()));
            if nargout == 0
                clear app
            end
        end

        function delete(app)
            if ~isempty(app.UIFigure) && isvalid(app.UIFigure)
                delete(app.UIFigure);
            end
        end
    end

    methods (Access = private)
        %% Interface
        function buildUI(app)
            app.UIFigure = uifigure('Name', sprintf('TRIBE %s - TRIplet-based Block size Estimation', ...
                tribelib.version()), 'Position', [60 60 1280 760], 'CloseRequestFcn', @(~, ~) delete(app));
            main = uigridlayout(app.UIFigure, [1 2]);
            main.ColumnWidth = {400, '1x'};

            left = uipanel(main, 'Title', 'Input');
            L = uigridlayout(left, [14 2]);
            L.ColumnWidth = {170, '1x'};
            L.RowHeight = {22, 26, 22, 34, '1x', 26, 22, 24, 24, 24, 24, 8, 32, 26};
            L.RowSpacing = 6;

            app.place(uilabel(L, 'Text', '1. Spacings of the sets (DICE output)', 'FontWeight', 'bold'), 1, [1 2]);
            app.place(uibutton(L, 'Text', 'Load spacing file...', ...
                'ButtonPushedFcn', @(~, ~) app.onLoadSpacing()), 2, 1);
            app.LblFile = app.place(uilabel(L, 'Text', 'no file', 'FontColor', [0.4 0.4 0.4]), 2, 2);

            app.place(uilabel(L, 'Text', '2. Mean orientation of the sets', 'FontWeight', 'bold'), 3, [1 2]);
            app.place(uilabel(L, 'Text', ['Type dip and dip direction (degrees) and select the sets to use ' ...
                '(at least three).'], 'WordWrap', 'on'), 4, [1 2]);
            app.TblSets = app.place(uitable(L, 'ColumnEditable', [false false true true true]), 5, [1 2]);
            app.place(uibutton(L, 'Text', 'Load orientations from file...', ...
                'ButtonPushedFcn', @(~, ~) app.onLoadOrient()), 6, [1 2]);

            app.place(uilabel(L, 'Text', '3. Options', 'FontWeight', 'bold'), 7, [1 2]);
            app.place(uilabel(L, 'Text', 'Volume formulation'), 8, 1);
            app.DdForm = app.place(uidropdown(L, 'Items', {'Umili et al. (2024)', 'Palmström (2005)'}, ...
                'ItemsData', {'Umili', 'Palmstrom'}), 8, 2);
            app.place(uilabel(L, 'Text', 'q threshold'), 9, 1);
            app.EdQ = app.place(uieditfield(L, 'numeric', 'Value', 0.5, 'Limits', [0 1], ...
                'UpperLimitInclusive', 'off'), 9, 2);
            app.place(uilabel(L, 'Text', 'Max. combinations (exact)'), 10, 1);
            app.EdMaxExact = app.place(uieditfield(L, 'numeric', 'Value', 2e8, 'Limits', [1 Inf], ...
                'ValueDisplayFormat', '%.3g'), 10, 2);
            app.place(uilabel(L, 'Text', 'Monte Carlo combinations'), 11, 1);
            app.EdNMC = app.place(uieditfield(L, 'numeric', 'Value', 1e6, 'Limits', [1e3 Inf], ...
                'ValueDisplayFormat', '%.3g'), 11, 2);

            app.BtnRun = app.place(uibutton(L, 'Text', 'Run', 'FontWeight', 'bold', ...
                'BackgroundColor', [0.16 0.47 0.84], 'FontColor', [1 1 1], ...
                'ButtonPushedFcn', @(~, ~) app.onRun()), 13, [1 2]);
            app.BtnExport = app.place(uibutton(L, 'Text', 'Export results...', 'Enable', 'off', ...
                'ButtonPushedFcn', @(~, ~) app.onExport()), 14, 1);
            app.place(uibutton(L, 'Text', 'About', 'ButtonPushedFcn', @(~, ~) app.onAbout()), 14, 2);

            app.Tabs = uitabgroup(main);
            app.TabResults = uitab(app.Tabs, 'Title', 'Results');
            g = uigridlayout(app.TabResults, [4 2]);
            g.RowHeight = {22, '1x', 22, '1.4x'};
            g.ColumnWidth = {'1x', '1.3x'};
            app.place(uilabel(g, 'Text', 'Statistics of the block volumes', 'FontWeight', 'bold'), 1, 1);
            app.place(uilabel(g, 'Text', 'Triplets of sets', 'FontWeight', 'bold'), 1, 2);
            app.TblStats = app.place(uitable(g), 2, 1);
            app.TblTrip = app.place(uitable(g), 2, 2);
            app.place(uilabel(g, 'Text', 'In-situ block size distribution', 'FontWeight', 'bold'), 3, [1 2]);
            app.AxHist = app.place(uiaxes(g), 4, 1);
            app.AxCum = app.place(uiaxes(g), 4, 2);

            t = uitab(app.Tabs, 'Title', 'Log');
            gl = uigridlayout(t, [1 1]);
            app.TxtLog = uitextarea(gl, 'Editable', 'off', 'FontName', 'Courier New', 'Value', {''});
        end

        function c = place(~, c, row, col)
            c.Layout.Row = row;
            c.Layout.Column = col;
        end

        %% Callbacks
        function onLoadSpacing(app)
            [f, p] = uigetfile({'*.txt;*.dat;*.csv', 'DICE spacing file (*.txt)'}, ...
                'Select the spacing file (e.g. Spacing_Values_per_set.txt)');
            figure(app.UIFigure);
            if isequal(f, 0)
                return
            end
            try
                D = tribelib.readDICESpacings(fullfile(p, f));
            catch ME
                uialert(app.UIFigure, ME.message, 'Spacing file');
                return
            end
            n = numel(D.sets);
            T = table(cellstr(D.sets(:)), cellfun(@numel, D.S(:)), nan(n, 1), nan(n, 1), true(n, 1), ...
                'VariableNames', {'Set', 'Spacings', 'Dip', 'DipDirection', 'Use'});
            % keep the orientations already typed for sets with the same name
            old = app.TblSets.Data;
            if istable(old) && ~isempty(old)
                [tf, j] = ismember(T.Set, old.Set);
                T.Dip(tf) = old.Dip(j(tf));
                T.DipDirection(tf) = old.DipDirection(j(tf));
                T.Use(tf) = old.Use(j(tf));
            end
            app.Spacing = D;
            app.TblSets.Data = T;
            app.LblFile.Text = f;
            app.resetResults();
            app.addLog(sprintf('Spacing file %s: %d sets (%s)', f, n, ...
                strjoin(compose('%s %d', D.sets(:), cellfun(@numel, D.S(:)))', ', ')));
        end

        function onLoadOrient(app)
            if isempty(app.Spacing)
                uialert(app.UIFigure, 'Load the spacing file first.', 'TRIBE');
                return
            end
            [f, p] = uigetfile({'*.csv;*.txt;*.xlsx;*.xls', 'Set orientations (*.csv, *.txt, *.xlsx)'}, ...
                'Select the file with the columns Set, Dip and DipDirection');
            figure(app.UIFigure);
            if isequal(f, 0)
                return
            end
            try
                O = tribelib.readOrientations(fullfile(p, f));
            catch ME
                uialert(app.UIFigure, ME.message, 'Set orientations');
                return
            end
            T = app.TblSets.Data;
            [tf, j] = ismember(string(T.Set), O.Set);
            T.Dip(tf) = O.Dip(j(tf));
            T.DipDirection(tf) = O.DipDirection(j(tf));
            app.TblSets.Data = T;
            app.resetResults();
            missing = setdiff(O.Set, string(T.Set));
            msg = sprintf('Orientations from %s assigned to %d sets', f, nnz(tf));
            if ~isempty(missing)
                msg = [msg sprintf('; sets not in the spacing file: %s', strjoin(missing(:)', ', '))];
            end
            app.addLog(msg);
        end

        function onRun(app)
            if isempty(app.Spacing)
                uialert(app.UIFigure, 'Load the spacing file first.', 'TRIBE');
                return
            end
            T = app.TblSets.Data;
            use = logical(T.Use);
            if nnz(use) < 3
                uialert(app.UIFigure, 'Select at least three sets.', 'TRIBE');
                return
            end
            bad = use & (~isfinite(T.Dip) | ~isfinite(T.DipDirection) | T.Dip < 0 | T.Dip > 90);
            if any(bad)
                uialert(app.UIFigure, sprintf(['Enter a valid dip (0-90) and dip direction for the ' ...
                    'sets: %s'], strjoin(T.Set(bad)', ', ')), 'TRIBE');
                return
            end
            O = table(string(T.Set(use)), T.Dip(use), mod(T.DipDirection(use), 360), ...
                'VariableNames', {'Set', 'Dip', 'DipDirection'});
            opt = tribelib.defaultOptions();
            opt.formulation = app.DdForm.Value;
            opt.qThreshold = app.EdQ.Value;
            opt.maxExact = app.EdMaxExact.Value;
            opt.nMonteCarlo = round(app.EdNMC.Value);

            app.BtnRun.Enable = 'off';
            dlg = uiprogressdlg(app.UIFigure, 'Title', 'TRIBE', 'Message', 'Computing the block volumes', ...
                'Indeterminate', 'on');
            try
                R = tribelib.computeIBSD(app.Spacing, O, opt);
                close(dlg);
                app.Results = R;
                app.showResults();
                app.BtnExport.Enable = 'on';
                app.logResults();
            catch ME
                if isvalid(dlg)
                    close(dlg);
                end
                app.addLog(['Error: ' ME.message]);
                uialert(app.UIFigure, ME.message, 'TRIBE error');
            end
            app.BtnRun.Enable = 'on';
        end

        function onExport(app)
            if isempty(app.Results)
                return
            end
            folder = uigetdir(pwd, 'Folder in which TRIBE will create the results folder');
            figure(app.UIFigure);
            if isequal(folder, 0)
                return
            end
            try
                out = tribelib.exportIBSD(app.Results, folder, app.TxtLog.Value);
                app.addLog(['Results saved in ' out]);
                uialert(app.UIFigure, sprintf('Results saved in:\n%s', out), 'Export', 'Icon', 'success');
            catch ME
                uialert(app.UIFigure, ME.message, 'Export error');
            end
        end

        function onAbout(app)
            msg = sprintf(['TRIBE %s - TRIplet-based Block size Estimation\n\n' ...
                'TRIBE estimates the in-situ block size distribution (IBSD) from the spacings of the ' ...
                'discontinuity sets measured with DICE. For every triplet of sets, the volume of each ' ...
                'combination of one spacing per set is computed with the formulation of Umili et al. ' ...
                '(2024) or Palmström (2005); triplets with a low non-orthogonality coefficient q can be ' ...
                'excluded.\n\nIf you use TRIBE, please cite:\nFoletti, M.G., Menegoni, N., et al. ' ...
                'Estimating rock block volume using drone and open-source fractured rock mass ' ...
                'characterization tools. Engineering Geology (submitted).'], tribelib.version());
            uialert(app.UIFigure, msg, 'About TRIBE', 'Icon', 'info');
        end

        %% Display
        function showResults(app)
            R = app.Results;
            app.TblStats.Data = R.tables.Statistics;
            app.TblTrip.Data = R.tables.Triplets;
            tribelib.plotIBSD(app.AxHist, app.AxCum, R);
            app.Tabs.SelectedTab = app.TabResults;
        end

        function logResults(app)
            R = app.Results;
            s = R.stats;
            app.addLog(sprintf('%s, q > %g, sets %s', R.label, R.opt.qThreshold, strjoin(R.O.Set', ', ')));
            for t = 1:numel(R.G.q)
                app.addLog(sprintf('  %-16s q = %.3f  Palmstrom factor = %.3f  %s', R.G.name(t), R.G.q(t), ...
                    R.G.palmstrom(t), app.ifelse(R.retained(t), 'retained', 'excluded')));
            end
            app.addLog(sprintf(['  %.4g combinations%s: mean = %.4g, median = %.4g, P90 = %.4g, ' ...
                'V50 = %.4g, V80 = %.4g m3'], R.info.nCombinations, ...
                app.ifelse(R.info.exact, '', ' (Monte Carlo)'), s.Mean, s.Median, s.P90, s.V50, s.V80));
        end

        function resetResults(app)
            app.Results = [];
            app.BtnExport.Enable = 'off';
        end

        %% Utilities
        function addLog(app, s)
            if isempty(app.TxtLog) || ~isvalid(app.TxtLog)
                fprintf('%s\n', s);
                return
            end
            v = app.TxtLog.Value;
            if ischar(v)
                v = {v};
            end
            if numel(v) == 1 && isempty(v{1})
                v = {};
            end
            app.TxtLog.Value = [v(:); cellstr(s)];
            try
                scroll(app.TxtLog, 'bottom');
            catch
            end
            drawnow limitrate
        end

        function out = ifelse(~, cond, a, b)
            if cond
                out = a;
            else
                out = b;
            end
        end
    end
end
