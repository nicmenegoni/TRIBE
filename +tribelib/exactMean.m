function m = exactMean(S, trips, g)
%EXACTMEAN Exact mean block volume of all spacing combinations.
%   m = tribelib.exactMean(S, trips, g) computes the mean of V = Si*Sj*Sk/g
%   over all combinations without enumerating them: for each triplet the sum
%   of the volumes equals the product of the sums of the spacings divided by
%   g. Used to report the exact mean when the distribution is sampled by
%   Monte Carlo.
num = 0;
den = 0;
for t = 1:size(trips, 1)
    num = num + prod(cellfun(@sum, S(trips(t, :)))) / g(t);
    den = den + prod(cellfun(@numel, S(trips(t, :))));
end
if den == 0
    m = NaN;
else
    m = num / den;
end
end
