%RUN_EXAMPLE Run TRIBE without the graphical interface on the example data.
%   example_spacings.txt contains synthetic spacings of four sets in the
%   format of the DICE output Spacing_Values_per_set.txt; example_orientations.csv
%   contains their mean orientations. The files only illustrate the input
%   formats and the workflow.

clear; clc;
here = fileparts(mfilename('fullpath'));
addpath(fileparts(here));                         % TRIBE root folder

D = tribelib.readDICESpacings(fullfile(here, 'data', 'example_spacings.txt'));
O = tribelib.readOrientations(fullfile(here, 'data', 'example_orientations.csv'));

opt = tribelib.defaultOptions();
opt.formulation = 'Umili';      % or 'Palmstrom'
opt.qThreshold = 0.5;

R = tribelib.computeIBSD(D, O, opt);
disp(R.tables.Statistics);
disp(R.tables.Triplets);

outDir = tribelib.exportIBSD(R, here);
fprintf('Tables and figure saved in %s\n', outDir);
