%% partie2_1.m - Source binaire et entropie (questions 1 et 2)
clear; close all; clc;
Parametres

%% Q2 : vérification de la fréquence empirique sur 1e5 bits
N = 1e5;
rng(graine);
b = source(N, p1);

f1 = mean(b);                                 % fréquence empirique des 1
ic = 1.96 * sqrt(p1 * (1 - p1) / N);          % IC à 95 % autour de p1
fprintf('\n--- Source binaire, N = %d bits ---\n', N);
fprintf('p1 théorique   : %.4f\n', p1);
fprintf('f1 empirique   : %.4f\n', f1);
fprintf('IC 95 %%        : [%.4f ; %.4f]\n', p1 - ic, p1 + ic);
if abs(f1 - p1) <= ic
    fprintf('-> f1 compatible avec p1\n');
else
    fprintf('-> f1 hors IC (arrive dans 5 %% des tirages)\n');
end

%% Q2 : entropie de la source et débit d'information
H1 = entropie_binaire(p1);
Db = 1;                                       % débit binaire : 1 bit/s
fprintf('\nEntropie H(p1)          : %.4f bit/symbole\n', H1);
fprintf('Entropie empirique H(f1): %.4f bit/symbole\n', entropie_binaire(f1));
fprintf('Débit d''information     : %.4f bit/s (pour %d bit/s émis)\n', H1*Db, Db);
fprintf('Redondance 1 - H        : %.4f bit/symbole\n', 1 - H1);

%% Q2 : tracé de H(p)
p = linspace(0, 1, 501);
figure; hold on; grid on; box on;
plot(p, entropie_binaire(p), 'LineWidth', 1.5, 'DisplayName', 'H(p)');
plot(p1, H1, 'o', 'MarkerSize', 8, 'LineWidth', 1.5, ...
     'DisplayName', sprintf('Source : p_1 = %.2f, H = %.3f', p1, H1));
plot([p1 p1], [0 H1], ':k', 'HandleVisibility', 'off');
xlabel('p = P(1)');  ylabel('H(p) (bit/symbole)');
title('Entropie d''une source binaire sans mémoire');
legend('Location', 'south');  ylim([0 1.05]);