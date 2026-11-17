function res = trace_TEB(cible, EbN0_dB, Te_bruit, varargin)
%TRACE_TEB  Courbe de TEB simulé en fonction de Eb/N0, avec courbe théorique.
%
%   res = trace_TEB('chaine_P3', 0:9, Te)          % modèle Simulink
%   res = trace_TEB(@(s2,eb) f(s2), 0:9, Te)       % chaîne Matlab pure
%
%   Te_bruit : période des échantillons de bruit (Te, Te_c, Ts...).
%              La variance injectée vaut sigma2 = N0/(2*Te_bruit).
%   Lancer Parametres.m avant (Eb, Tb, graine, nErrMax, nBitsMax lus
%   dans le workspace de base).
%
%   Contrat côté Simulink :
%     - le bloc de bruit utilise la variable 'sigma2' (variance) ;
%     - un bloc To Workspace nommé 'err' (format Array) reçoit la sortie
%       [TEB ; nb erreurs ; nb bits] de l'Error Rate Calculation
%       (ou d'un compteur maison respectant le même format).
%   Contrat côté Matlab : [nerr, nbits] = f(sigma2, EbN0_dB).
%
%   Options (nom/valeur) :
%     'Theorie'  handle @(ebn0_lin) TEB théorique  (défaut Q(sqrt(2x)), [] = aucune)
%     'Legende'  texte de légende de la courbe simulée
%     'Figure'   handle de figure, pour superposer plusieurs chaînes
%     'Variable' nom de la variable To Workspace     (défaut 'err')
%     'StopTime' durée max de simulation             (défaut 1.05*nBitsMax*Tb)
%     'ArretSiZero' arrête la boucle au 1er point sans erreur (défaut true)

%% Lecture du workspace de base
lire  = @(v) evalin('base', v);
Eb     = lire('Eb');      Tb       = lire('Tb');
graine = lire('graine');  nBitsMax = lire('nBitsMax');

%% Options
p = inputParser;
p.addParameter('Theorie', @(x) 0.5*erfc(sqrt(x)));   % Q(sqrt(2x))
p.addParameter('Legende', 'TEB simulé');
p.addParameter('Figure', []);
p.addParameter('Variable', 'err');
p.addParameter('StopTime', 1.05*nBitsMax*Tb);
p.addParameter('ArretSiZero', true);
p.parse(varargin{:});
opt = p.Results;

%% Boucle sur Eb/N0
nP   = numel(EbN0_dB);
nerr = nan(1, nP);  nbits = nan(1, nP);
for i = 1:nP
    N0 = Eb / 10^(EbN0_dB(i)/10);
    s2 = N0 / (2*Te_bruit);

    if isa(cible, 'function_handle')                 % chaîne Matlab
        rng(graine);
        [nerr(i), nbits(i)] = cible(s2, EbN0_dB(i));
    else                                             % modèle Simulink
        in = Simulink.SimulationInput(cible);
        in = in.setVariable('sigma2',  s2);
        in = in.setVariable('EbN0_dB', EbN0_dB(i));
        in = in.setModelParameter('StopTime', num2str(opt.StopTime));
        out = sim(in);
        e = lire_err(out.get(opt.Variable));
        nerr(i) = e(2);  nbits(i) = e(3);
    end

    fprintf('Eb/N0 = %4.1f dB : %6d erreurs / %8d bits -> TEB = %.3e\n', ...
            EbN0_dB(i), nerr(i), nbits(i), nerr(i)/nbits(i));
    if opt.ArretSiZero && nerr(i) == 0, break; end
end

%% Résultats et intervalle de confiance à 95 %
ok  = nerr > 0;                       % points exploitables en échelle log
teb = nerr ./ nbits;
ic  = 1.96 * sqrt(teb .* (1 - teb) ./ nbits);

res = struct('EbN0_dB', EbN0_dB, 'teb', teb, 'nerr', nerr, ...
             'nbits', nbits, 'ic95', ic);

%% Tracé
if isempty(opt.Figure), figure; else, figure(opt.Figure); end
hold on; grid on; box on;
x = EbN0_dB(ok);  y = teb(ok);
neg = min(ic(ok), 0.99*y);            % borne basse > 0 en échelle log
errorbar(x, y, neg, ic(ok), 'o', 'LineWidth', 1.2, ...
         'DisplayName', opt.Legende);

if ~isempty(opt.Theorie)
    xf = linspace(min(EbN0_dB), max(EbN0_dB), 200);
    semilogy(xf, opt.Theorie(10.^(xf/10)), '-', 'LineWidth', 1.2, ...
             'DisplayName', 'TEB théorique');
    res.teb_th = opt.Theorie(10.^(EbN0_dB/10));
end

set(gca, 'YScale', 'log');
xlabel('E_b/N_0 (dB)');  ylabel('TEB');
title('Taux d''erreur binaire en fonction de E_b/N_0');
legend('Location', 'southwest');
end

%% ------------------------------------------------------------------------
function e = lire_err(v)
% Récupère le dernier vecteur [TEB nerr nbits] quel que soit le format
% de sauvegarde du bloc To Workspace.
if isa(v, 'timeseries'), v = v.Data; end
if isstruct(v),          v = v.signals.values; end
v = squeeze(v);
if isvector(v)
    e = v(:);
elseif size(v, 2) == 3
    e = v(end, :).';
else
    e = v(:, end);
end
end