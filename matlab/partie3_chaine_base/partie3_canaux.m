%% partie3_canaux.m - Chaîne de base : CBS, bruit uniforme, bruit gaussien
% Questions 1 à 9 de la partie 3. Un échantillon par bit : r_k = x_k + n_k,
% x_k = ±A. Les mêmes bits et le même bruit servent pour tous les seuils
% (comparaison à réalisation égale, calcul rapide).
clear; close all; clc;
Parametres
Qf = @(x) 0.5*erfc(x/sqrt(2));
N  = 1e6;                                   % bits simulés par canal
ic95 = @(p, n) 1.96*sqrt(p.*(1-p)./n);

rng(graine);
b = source(N, p1);                          % source de la partie 2 (P(1) = p1)
x = A*(2*b - 1);                            % 0 -> -A, 1 -> +A

%% Q1-Q2 : canal binaire symétrique
erreur = rand(N, 1) < pe_cbs;               % 1 = le canal inverse le bit
b_cbs  = xor(b, erreur);
teb_cbs = mean(b_cbs ~= b);
fprintf('=== Q1-Q2 : CBS (%d bits) ===\n', N);
fprintf('pe = %.4f | TEB simulé = %.5f | IC 95 %% = [%.5f ; %.5f] -> compatible : %d\n', ...
        pe_cbs, teb_cbs, teb_cbs - ic95(teb_cbs, N), teb_cbs + ic95(teb_cbs, N), ...
        abs(teb_cbs - pe_cbs) <= ic95(teb_cbs, N));

%% Q3 : capacité du CBS
C = 1 - entropie_binaire(pe_cbs);
R = 4/7;
fprintf('\n=== Q3 : capacité ===\n');
fprintf('C(pe) = %.4f bit/utilisation | R = 4/7 = %.4f -> R < C : %d\n', C, R, R < C);
pe_lim = fzero(@(p) 1 - entropie_binaire(p) - R, [1e-6 0.5-1e-6]);
fprintf('R = 4/7 possible tant que pe < %.4f | C(0.5) = %g\n', pe_lim, 1 - entropie_binaire(0.5));

pp = linspace(0, 1, 501);
figure; hold on; grid on; box on;
plot(pp, 1 - entropie_binaire(pp), 'LineWidth', 1.5, 'DisplayName', 'C(p_e) = 1 - H(p_e)');
plot(pe_cbs, C, 'o', 'MarkerSize', 8, 'LineWidth', 1.5, ...
     'DisplayName', sprintf('Votre canal : p_e = %.3f, C = %.3f', pe_cbs, C));
yline(R, '--', 'LineWidth', 1.2, 'DisplayName', 'Rendement Hamming R = 4/7');
xlabel('p_e');  ylabel('C (bit par bit émis)');
title('Capacité du canal binaire symétrique');  legend('Location', 'north');

%% Q4 : densités pour le bruit uniforme sur [-a, a]
a = a_unif;
fprintf('\n=== Q4 : bruit uniforme, a = %.2f, A = %g ===\n', a, A);
if a <= A
    fprintf('a <= A : supports disjoints, aucune erreur possible.\n');
else
    fprintf('Zone de recouvrement [A-a, a-A] = [%.2f ; %.2f], f(r|0) = f(r|1) = 1/(2a)\n', A-a, a-A);
    if p0 > p1
        fprintf('p0 > p1 : on décide 0 sur toute la zone -> seuil optimal s* = a - A = %.2f\n', a-A);
    elseif p1 > p0
        fprintf('p1 > p0 : on décide 1 sur toute la zone -> seuil optimal s* = A - a = %.2f\n', A-a);
    else
        fprintf('p0 = p1 : tout seuil de [A-a, a-A] est optimal (non unique)\n');
    end
end
r = linspace(-A-a-0.3, A+a+0.3, 2000);
f0 = (abs(r + A) <= a) / (2*a);
f1 = (abs(r - A) <= a) / (2*a);
figure; hold on; grid on; box on;
plot(r, p0*f0, 'LineWidth', 1.5, 'DisplayName', 'p_0 f(r|0)');
plot(r, p1*f1, 'LineWidth', 1.5, 'DisplayName', 'p_1 f(r|1)');
plot(r, f0, ':', 'LineWidth', 1, 'DisplayName', 'f(r|0)');
plot(r, f1, ':', 'LineWidth', 1, 'DisplayName', 'f(r|1)');
xline(A - a, '--k', 'HandleVisibility', 'off');
xline(a - A, '--k', 'HandleVisibility', 'off');
xlabel('r');  ylabel('Densité');  legend('Location', 'north');
title(sprintf('Bruit uniforme sur [-%.2f ; %.2f], A = %g', a, a, A));

%% Q5-Q6 : probabilité d'erreur en fonction du seuil (uniforme)
clip = @(v) min(max(v, 0), 1);
Pe_unif = @(s) p0*clip((a - A - s)/(2*a)) + p1*clip((s - A + a)/(2*a));

n_u = a*(2*rand(N, 1) - 1);
r_u = x + n_u;
s_u = linspace(-(a - A) - 0.2, (a - A) + 0.2, 31);
teb_u = arrayfun(@(s) mean((r_u > s) ~= b), s_u);

[~, iu] = min(teb_u);
fprintf('\n=== Q5-Q6 : uniforme ===\n');
fprintf('Pe théorique : s = 0 -> %.5f | s = a-A -> %.5f\n', Pe_unif(0), Pe_unif(a - A));
fprintf('Simulé       : s = 0 -> %.5f | meilleur seuil testé %.3f -> %.5f\n', ...
        mean((r_u > 0) ~= b), s_u(iu), teb_u(iu));

ss = linspace(min(s_u), max(s_u), 400);
figure; hold on; grid on; box on;
plot(ss, Pe_unif(ss), 'LineWidth', 1.5, 'DisplayName', 'P_e(s) théorique');
errorbar(s_u, teb_u, ic95(teb_u, N), 'o', 'DisplayName', sprintf('TEB simulé (%g bits)', N));
xline(a - A, '--k', 's* = a - A', 'HandleVisibility', 'off');
xlabel('Seuil s');  ylabel('Probabilité d''erreur');
title(sprintf('Bruit uniforme (a = %.2f) : P_e en fonction du seuil', a));
legend('Location', 'north');

%% Q7-Q8 : bruit gaussien, écart-type sigma
Pe_gauss = @(s) p0*Qf((s + A)/sigma) + p1*Qf((A - s)/sigma);
s_star = sigma^2/(2*A) * log(p0/p1);

r_g = x + sigma*randn(N, 1);
s_g = linspace(-0.3, 0.6, 37);
teb_g = arrayfun(@(s) mean((r_g > s) ~= b), s_g);
[~, ig] = min(teb_g);

teb0  = mean((r_g > 0) ~= b);
tebS  = mean((r_g > s_star) ~= b);
fprintf('\n=== Q7-Q8 : gaussien, sigma = %.2f ===\n', sigma);
fprintf('Seuil optimal s* = sigma^2/(2A) ln(p0/p1) = %.4f\n', s_star);
fprintf('Théorie : Pe(0) = %.5f | Pe(s*) = %.5f | gain = %.2f %%\n', ...
        Pe_gauss(0), Pe_gauss(s_star), 100*(1 - Pe_gauss(s_star)/Pe_gauss(0)));
fprintf('Simulé  : TEB(0) = %.5f | TEB(s*) = %.5f | meilleur seuil testé %.3f\n', ...
        teb0, tebS, s_g(ig));
fprintf('IC 95 %% sur TEB(s*) : ±%.5f\n', ic95(tebS, N));

ss = linspace(min(s_g), max(s_g), 400);
figure; hold on; grid on; box on;
plot(ss, Pe_gauss(ss), 'LineWidth', 1.5, 'DisplayName', 'P_e(s) théorique');
errorbar(s_g, teb_g, ic95(teb_g, N), 'o', 'DisplayName', sprintf('TEB simulé (%g bits)', N));
xline(s_star, '--k', sprintf('s* = %.3f', s_star), 'HandleVisibility', 'off');
xline(0, ':k', 's = 0', 'HandleVisibility', 'off');
xlabel('Seuil s');  ylabel('Probabilité d''erreur');
title(sprintf('Bruit gaussien (\\sigma = %.2f) : P_e en fonction du seuil', sigma));
legend('Location', 'northeast');

%% Q9 : synthèse des trois canaux
fprintf('\n=== Q9 : comparaison ===\n');
fprintf('%-12s | %-22s | %10s\n', 'Canal', 'Seuil optimal', 'TEB');
fprintf('%-12s | %-22s | %10.5f\n', 'CBS', '(pas de seuil)', teb_cbs);
fprintf('%-12s | %-22s | %10.5f\n', 'Uniforme', sprintf('a - A = %.3f', a - A), Pe_unif(a - A));
fprintf('%-12s | %-22s | %10.5f\n', 'Gaussien', sprintf('s* = %.4f', s_star), Pe_gauss(s_star));
