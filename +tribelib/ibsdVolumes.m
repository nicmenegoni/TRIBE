function [v, info] = ibsdVolumes(S, trips, g, maxExact, nMC)
%IBSDVOLUMES Block volumes of all the combinations of measured spacings.
%   [v, info] = tribelib.ibsdVolumes(S, trips, g) returns the volumes
%   V = Si*Sj*Sk/g(t) of every combination of one spacing of each set of the
%   triplets in trips (rows of set indices). S is a 1 x nSets cell array of
%   spacings and g(t) is the correction factor of triplet t (q for Umili et
%   al., 2024; the product of the sines of the inter-set angles for
%   Palmström, 2005).
%
%   If the number of combinations exceeds maxExact (default Inf), nMC
%   combinations (default 1e6) are drawn at random instead: each draw picks a
%   triplet with probability proportional to its number of combinations and
%   one spacing of each set with equal probability, which samples the same
%   distribution as the full enumeration.
%
%   info.nCombinations is the number of combinations and info.exact tells
%   whether the full enumeration was used.

if nargin < 4 || isempty(maxExact)
    maxExact = Inf;
end
if nargin < 5 || isempty(nMC)
    nMC = 1e6;
end

w = zeros(size(trips, 1), 1);
for t = 1:size(trips, 1)
    w(t) = prod(cellfun(@numel, S(trips(t, :))));
end
ok = w > 0;
trips = trips(ok, :);
g = g(ok);
w = w(ok);

info.nCombinations = sum(w);
info.exact = info.nCombinations <= maxExact;
if info.nCombinations == 0
    v = zeros(0, 1);
    return
end

if info.exact
    v = zeros(info.nCombinations, 1);
    p = 0;
    for t = 1:size(trips, 1)
        a = S{trips(t, 1)}(:);
        b = S{trips(t, 2)}(:);
        c = S{trips(t, 3)}(:);
        ab = a * b.';
        abc = ab(:) * c.';
        m = numel(abc);
        v(p+1:p+m) = abc(:) / g(t);
        p = p + m;
        clear ab abc
    end
else
    k = discretize(rand(nMC, 1), [0; cumsum(w) / sum(w)]);
    v = zeros(nMC, 1);
    for t = 1:size(trips, 1)
        m = (k == t);
        c = nnz(m);
        if c == 0
            continue
        end
        x = ones(c, 1);
        for j = 1:3
            s = S{trips(t, j)}(:);
            x = x .* s(randi(numel(s), c, 1));
        end
        v(m) = x / g(t);
    end
end
end
