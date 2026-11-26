function O = readOrientations(file)
%READORIENTATIONS Read the mean orientations of the discontinuity sets.
%   O = tribelib.readOrientations(file) reads a CSV, TXT or XLSX file with
%   one row per set and the columns Set, Dip and DipDirection (degrees).
%   DipDir, Dip_Direction, DD and Azimuth are also accepted for the dip
%   direction. At least three sets are required.

opts = detectImportOptions(file, 'VariableNamingRule', 'preserve');
T0 = readtable(file, opts);
names = lower(regexprep(string(T0.Properties.VariableNames), '[\s_\-\.()°]', ''));

jSet = find(names == "set" | names == "sets" | names == "name", 1);
jDD = find(startsWith(names, "dipdir") | names == "dd" | startsWith(names, "azimuth"), 1);
jDip = find(startsWith(names, "dip") & ~startsWith(names, "dipdir"), 1);
if isempty(jSet) || isempty(jDD) || isempty(jDip)
    error('TRIBE:orientations', ...
        'The orientation file must contain the columns Set, Dip and DipDirection.');
end

O = table(strtrim(string(T0{:, jSet})), toNumber(T0{:, jDip}), toNumber(T0{:, jDD}), ...
    'VariableNames', {'Set', 'Dip', 'DipDirection'});
O(ismissing(O.Set) | O.Set == "" | ~isfinite(O.Dip) | ~isfinite(O.DipDirection), :) = [];

if height(O) < 3
    error('TRIBE:orientations', 'At least three discontinuity sets are needed.');
end
if numel(unique(O.Set)) < height(O)
    error('TRIBE:orientations', 'Set names must be unique.');
end
if any(O.Dip < 0 | O.Dip > 90)
    error('TRIBE:orientations', 'Dip values must be between 0 and 90 degrees.');
end
end

function x = toNumber(x)
if ~isnumeric(x)
    x = str2double(strrep(string(x), ',', '.'));
end
x = double(x(:));
end
