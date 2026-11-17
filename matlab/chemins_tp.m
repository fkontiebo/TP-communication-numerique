function racine = chemins_tp()
%CHEMINS_TP  Ajoute au chemin Matlab tous les dossiers du projet.
%   racine = chemins_tp() rend le dossier matlab/ du projet. Appelée par
%   Parametres.m et par les scripts qui n'utilisent pas les paramètres
%   (partie2_2, partie2_4) : chaque script peut ainsi être lancé seul.
racine = fileparts(mfilename('fullpath'));
dossiers = {'', 'commun', 'partie2_codage_source', 'partie3_chaine_base', ...
            'partie4_codage_canal', 'partie5_modulation_qpsk', 'partie6_mise_en_forme', 'partie7_canal'};
for i = 1:numel(dossiers)
    addpath(fullfile(racine, dossiers{i}));
end
end
