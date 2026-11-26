function opt = defaultOptions()
%DEFAULTOPTIONS Default options of TRIBE.
%   opt = tribelib.defaultOptions() returns the options used by
%   tribelib.computeIBSD. Edit the fields before calling computeIBSD to
%   change the analysis.

% Volume formulation: 'Umili' (V = S1*S2*S3/q; Umili et al., 2024) or
% 'Palmstrom' (V = S1*S2*S3/(sin g12 sin g13 sin g23); Palmström, 2005).
opt.formulation = 'Umili';

% Only the triplets of sets with q > qThreshold are used. q is the
% non-orthogonality coefficient of Umili et al. (2024); values close to zero
% identify nearly co-zonal triplets, which do not bound closed blocks.
% qThreshold = 0 retains all the triplets.
opt.qThreshold = 0.5;

% The volumes of all spacing combinations are computed when their number is
% <= maxExact; otherwise nMonteCarlo combinations are drawn at random and
% the mean volume is still computed exactly.
opt.maxExact = 2e8;
opt.nMonteCarlo = 1e6;

% Volume grid (m^3) on which the cumulative distributions are evaluated.
opt.volumeGrid = logspace(-8, 5, 651)';

% Seed of the random number generator (used only by the Monte Carlo option).
opt.seed = 1;
end
