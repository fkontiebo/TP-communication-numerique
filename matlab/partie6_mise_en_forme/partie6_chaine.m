%% partie6_chaine.m - Partie 6 : filtres dans la chaîne QPSK (questions 1, 5 et 6)
% Modèle : chaine_P6.slx.
% Filtres d'énergie unité -> bruit après filtre adapté de variance sigma2 par voie :
% même convention qu'en partie 5, d'où Te_bruit = Ts dans trace_TEB.
clear; close all; clc;
Parametres
modele = 'chaine_P6';
load_system(modele);
Qf = @(x) 0.5*erfc(x/sqrt(2));
N0_de = @(x) 0.5 / 10^(x/10);                  % Eb vrai = 1/2 (Es = 1)

% Filtres étudiés : nom, coefficients, alignement (échantillons)
% Porte : pic de h*h au bout de L-1 échantillons -> +1 pour retomber sur un multiple de L
% RRC   : pic au bout de N-1 = span*L échantillons -> déjà multiple de L
F.porte = {ones(1, L)/sqrt(L), 1};
F.rrc   = {rrc_coef(alpha, L, span), 0};

%% Retard D7 pour chaque filtre (bruit nul)
fprintf('=== Recherche des retards (sigma2 = 0) ===\n');
noms = {'porte', 'rrc'};
for f = 1:2
    choisir_filtre(F.(noms{f}){:});
    D7 = NaN;
    for d = 0:60
        e = simuler(modele, 0, 2000*Tb, d, 'err');  e = e(end, :);
        % Bon retard : seulement les erreurs du transitoire de remplissage des
        % filtres (au plus ~2 bits par symbole de span) ; mauvais : ~50 % -> arrêt à 100
        if e(2) <= 2*span + 4, D7 = d; break; end
    end
    if isnan(D7), error('Aucun retard D7 ne convient pour le filtre %s.', noms{f}); end
    F.(noms{f}){3} = D7;
    fprintf('%-5s : D7 = %2d (%d erreurs / %d bits)\n', noms{f}, D7, e(2), e(3));
end

%% Q1 et Q5 : TEB porte et RRC
choisir_filtre(F.porte{:});
res_p = trace_TEB(modele, EbN0_vec, Ts, 'Legende', 'Filtre porte (simulé)', ...
                  'Theorie', @(x) Qf(sqrt(2*x)));
fig_teb = gcf;
choisir_filtre(F.rrc{:});
res_r = trace_TEB(modele, EbN0_vec, Ts, 'Figure', fig_teb, 'Theorie', [], ...
                  'Legende', sprintf('RRC \\alpha = %.2f (simulé)', alpha));
ylim([1e-6 1]);  title('QPSK filtrée : TEB en fonction de E_b/N_0');

%% Q5 : diagrammes de l'oeil (sans bruit) et constellations (10 dB)
figure('Position', [50 80 1200 650]);
for f = 1:2
    choisir_filtre(F.(noms{f}){:});
    y  = simuler(modele, 0, 1000*Ts, F.(noms{f}){3}, 'y_rx');
    iq = simuler(modele, N0_de(10)/2, 1000*Ts, F.(noms{f}){3}, 'iq_rx');
    subplot(2, 2, f);       oeil(y, L, sprintf('Oeil, filtre %s', noms{f}));
    subplot(2, 2, f + 2);   constellation(iq, sprintf('Constellation à 10 dB, %s', noms{f}));
end

%% Q6 : décalage de T/4, alpha = 0.22 et alpha = 1
alphas = [0.22 1];
fig_q6 = figure('Position', [50 80 1200 650]);
for a = 1:2
    h6a = rrc_coef(alphas(a), L, span);
    for dec = 0:1
        choisir_filtre(h6a, dec*L/4);
        y  = simuler(modele, 0, 1000*Ts, F.rrc{3}, 'y_rx');
        figure(fig_q6);
        subplot(2, 4, (a - 1)*4 + 1 + dec);
        libelles = {'sans décalage', 'décalage T/4'};
        oeil(y, L, sprintf('\\alpha = %.2f, %s', alphas(a), libelles{dec + 1}));
        if dec == 1
            iq = simuler(modele, N0_de(10)/2, 1000*Ts, F.rrc{3}, 'iq_rx');
            subplot(2, 4, (a - 1)*4 + 3);
            constellation(iq, sprintf('\\alpha = %.2f, T/4, 10 dB', alphas(a)));
        end
    end
end

% TEB avec décalage T/4
assignin('base', 'D7', F.rrc{3});
choisir_filtre(rrc_coef(alphas(1), L, span), L/4);
res_022 = trace_TEB(modele, EbN0_vec, Ts, 'Legende', '\alpha = 0.22, décalage T/4', ...
                    'Theorie', @(x) Qf(sqrt(2*x)));
fig_teb6 = gcf;
choisir_filtre(rrc_coef(alphas(2), L, span), L/4);
res_1 = trace_TEB(modele, EbN0_vec, Ts, 'Figure', fig_teb6, 'Theorie', [], ...
                  'Legende', '\alpha = 1, décalage T/4');
ylim([1e-6 1]);  title('Effet d''un décalage d''échantillonnage de T/4');

fprintf('\n=== Q6 : TEB à 6 dB ===\n');
i6 = find(EbN0_vec == 6);
fprintf('Théorie (sans décalage) : %.2e\n', Qf(sqrt(2*10^(6/10))));
fprintf('alpha = 0.22, T/4       : %.2e\n', res_022.teb(i6));
fprintf('alpha = 1,    T/4       : %.2e\n', res_1.teb(i6));

% Retour au filtre RRC nominal
choisir_filtre(F.rrc{:});
fprintf('\n-> reporter dans Parametres.m : h6 = rrc_coef(alpha, L, span); decal6 = 0; D7 = %d\n', F.rrc{3});
fprintf('   (filtre porte : decal6 = 1, D7 = %d)\n', F.porte{3});

%% ------------------------------------------------------------------------
function choisir_filtre(h, decal, varargin)
% Place les coefficients et l'alignement dans le workspace de base
assignin('base', 'h6', h);
assignin('base', 'decal6', decal);
if ~isempty(varargin), assignin('base', 'D7', varargin{1}); end
end

function v = simuler(modele, s2, duree, d7, nom)
% Une simulation de durée fixée ; renvoie la variable To Workspace demandée
in = Simulink.SimulationInput(modele);
in = in.setVariable('sigma2', s2);  in = in.setVariable('D7', d7);
in = in.setVariable('nErrMax', inf);
in = in.setModelParameter('StopTime', num2str(duree));
out = sim(in);
v = squeeze(double(out.get(nom)));
if size(v, 1) == 2 && size(v, 2) ~= 2, v = v.'; end
end

function oeil(y, L, titre)
% Diagramme de l'oeil de la voie I : tranches de 2 symboles centrées sur les
% instants d'échantillonnage (échantillons d'indice 1 + kL)
yi = y(:, 1);
pics = 1 + (30:numel(yi)/L - 30) * L;            % on évite le transitoire
x = (-L:L) / L;
hold on;  grid on;  box on;
for p = pics(1:min(200, end))
    plot(x, yi(p - L : p + L), 'Color', [0 0.45 0.74 0.25]);
end
xline(0, 'r', 'LineWidth', 1.2);
yline(0, 'k');
xlabel('t / T (0 = instant d''échantillonnage)');  ylabel('Voie I');
title(titre);  xlim([-1 1]);
end

function constellation(iq, titre)
hold on;  grid on;  box on;  axis equal;
plot(iq(:, 1), iq(:, 2), '.', 'MarkerSize', 4);
plot([1 1 -1 -1]/sqrt(2), [1 -1 1 -1]/sqrt(2), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
xline(0, 'k');  yline(0, 'k');
xlim([-1.8 1.8]);  ylim([-1.8 1.8]);
xlabel('I');  ylabel('Q');  title(titre);
end
