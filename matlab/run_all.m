function run_all(scripts)
%RUN_ALL  Rejoue tout le TP et enregistre figures et sorties console.
%   run_all             % toutes les parties (plusieurs dizaines de minutes)
%   run_all({'partie2_2', 'partie4_chaine'})   % sous-ensemble
%
%   Chaque script est exécuté dans le workspace de base (les modèles
%   Simulink y lisent leurs paramètres). Après chaque script :
%     - les figures ouvertes sont exportées en PNG dans ../figures/
%       sous le nom <script>_<n>.png ;
%     - la sortie console est enregistrée dans ../resultats/<script>.txt.
%   Les schémas des modèles Simulink sont exportés dans ../figures/modeles/.

tous = {'partie2_1', 'partie2_2', 'partie2_3', 'partie2_4', 'partie2_5', ...
        'partie3_canaux', 'test_P3', 'partie3_simulink', ...
        'partie4_hamming', 'partie4_codeur_simulink', ...
        'partie4_decodeur_simulink', 'partie4_chaine', ...
        'partie5_qpsk', 'partie5_q6', ...
        'partie6_filtres', 'partie6_chaine', 'partie7_canal'};
if nargin < 1, scripts = tous; end

racine = fileparts(mfilename('fullpath'));
evalin('base', sprintf('run(''%s'')', fullfile(racine, 'init_tp.m')));
dfig = fullfile(racine, '..', 'figures');
dres = fullfile(racine, '..', 'resultats');
if ~exist(dfig, 'dir'), mkdir(dfig); end
if ~exist(dres, 'dir'), mkdir(dres); end

for i = 1:numel(scripts)
    executer(scripts{i}, dfig, dres);
end
if nargin < 1, exporter_modeles(fullfile(dfig, 'modeles')); end
fprintf('\nTerminé : figures dans %s, sorties dans %s\n', dfig, dres);
end

%% ------------------------------------------------------------------------
function executer(nom, dfig, dres)
close all force;
journal = fullfile(dres, [nom '.txt']);
if exist(journal, 'file'), delete(journal); end
diary(journal);
fprintf('##### %s (%s) #####\n', nom, char(datetime('now')));
t = tic;
try
    evalin('base', nom);            % le script fait lui-même clear / close all
catch err
    fprintf(2, 'ERREUR dans %s : %s\n', nom, err.getReport('basic'));
end
fprintf('##### %s : %.1f s #####\n', nom, toc(t));
diary off;

figs = flipud(findobj(0, 'Type', 'figure'));   % ordre de création
for k = 1:numel(figs)
    exportgraphics(figs(k), fullfile(dfig, sprintf('%s_%d.png', nom, k)), ...
                   'Resolution', 200);
end
close all force;
end

function exporter_modeles(d)
if ~exist(d, 'dir'), mkdir(d); end
modeles = {'chaine_P3', 'codeur_hamming', 'decodeur_hamming', 'chaine_P4', ...
           'chaine_P5', 'chaine_P5c', 'chaine_P6', 'chaine_P7'};
for i = 1:numel(modeles)
    try
        load_system(modeles{i});
        print(['-s' modeles{i}], '-dpng', '-r200', fullfile(d, [modeles{i} '.png']));
    catch err
        fprintf(2, 'Export de %s impossible : %s\n', modeles{i}, err.message);
    end
end
end
