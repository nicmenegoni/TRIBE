function D = readDICESpacings(file)
%READDICESPACINGS Read the spacings of each discontinuity set written by DICE.
%   D = tribelib.readDICESpacings(file) reads a text file in the format of the
%   DICE output Spacing_Values_per_set.txt (Menegoni et al., 2023): the name
%   of each set followed by its spacings (m), separated by spaces or tabs.
%   The values of a set may continue on the following lines until the next
%   set name. Sets can contain different numbers of spacings.
%
%   D.sets is a string array with the set names, D.S a cell array with the
%   spacings of each set and D.file the name of the file.

txt = fileread(file);
lines = regexp(txt, '\r?\n', 'split');
names = strings(1, 0);
S = cell(1, 0);
k = 0;
for i = 1:numel(lines)
    tok = regexp(strtrim(lines{i}), '\s+', 'split');
    if isempty(tok) || isempty(tok{1})
        continue
    end
    if isnan(str2double(strrep(tok{1}, ',', '.')))
        % new set name
        name = string(tok{1});
        k = find(names == name, 1);
        if isempty(k)
            names(end+1) = name; %#ok<AGROW>
            S{end+1} = zeros(0, 1); %#ok<AGROW>
            k = numel(names);
        end
        tok = tok(2:end);
    end
    if k == 0
        error('TRIBE:dice', ['No set name found before the first spacing in %s. ' ...
            'Each set must start with its name (e.g. "S0  0.53  1.21 ...").'], file);
    end
    v = str2double(strrep(tok, ',', '.'));
    v = v(isfinite(v) & v > 0);
    S{k} = [S{k}; v(:)];
end
if isempty(names)
    error('TRIBE:dice', 'No spacing found in %s.', file);
end
[~, f, e] = fileparts(file);
D.sets = names;
D.S = S;
D.file = [f e];
end
