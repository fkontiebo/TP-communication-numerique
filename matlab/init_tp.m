%% init_tp.m - Initialisation du TP (à lancer une fois par session Matlab)
% Se place dans le dossier matlab/ du projet (dossier de travail attendu par
% les scripts), ajoute les sous-dossiers au chemin et charge les paramètres
% personnels figés (mes_parametres.mat) : voir Parametres.m.
cd(fileparts(mfilename('fullpath')));
Parametres
