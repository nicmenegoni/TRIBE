function G = setGeometry(O)
%SETGEOMETRY Geometry of the triplets of discontinuity sets.
%   G = tribelib.setGeometry(O) uses the mean orientations in O (see
%   tribelib.readOrientations) to compute, for every combination of three
%   sets:
%     q          non-orthogonality coefficient of Umili et al. (2024),
%                q = |n1 . (n2 x n3)|, i.e. the volume of the parallelepiped
%                built on the unit normals. q = 1 for mutually orthogonal sets
%                and q -> 0 for co-zonal sets, which do not bound closed blocks.
%     palmstrom  product of the sines of the three inter-set angles, used by
%                Palmström (2005) to correct the block volume.
%   The block volume of a spacing triplet is V = S1*S2*S3/q (Umili et al.,
%   2024) or V = S1*S2*S3/(sin g12 * sin g13 * sin g23) (Palmström, 2005).

n = height(O);
N = zeros(n, 3);
for k = 1:n
    d = deg2rad(O.Dip(k));
    a = deg2rad(O.DipDirection(k));
    N(k, :) = [sin(d)*sin(a), sin(d)*cos(a), cos(d)];   % upward unit normal (E, N, Up)
end

trips = nchoosek(1:n, 3);
nT = size(trips, 1);
q = zeros(nT, 1);
pf = zeros(nT, 1);
name = strings(nT, 1);
for t = 1:nT
    i = trips(t, 1); j = trips(t, 2); k = trips(t, 3);
    q(t) = abs(dot(N(i, :), cross(N(j, :), N(k, :))));
    % |ni x nj| is the sine of the angle between two planes
    pf(t) = norm(cross(N(i, :), N(j, :))) * norm(cross(N(i, :), N(k, :))) * norm(cross(N(j, :), N(k, :)));
    name(t) = strjoin(O.Set(trips(t, :))', '-');
end

ang = zeros(n);
for i = 1:n
    for j = 1:n
        ang(i, j) = acosd(min(1, abs(dot(N(i, :), N(j, :)))));
    end
end

G.sets = O.Set(:)';
G.normals = N;
G.triplets = trips;
G.q = q;
G.palmstrom = pf;
G.name = name;
G.angles = ang;
G.table = table(name, q, pf, pf ./ q, ...
    'VariableNames', {'Triplet', 'q', 'Palmstrom_factor', 'Palmstrom_over_q'});
end
