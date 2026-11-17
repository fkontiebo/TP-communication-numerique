%% partie3_simulink.m - Questions 10 à 12 : chaîne de base sous Simulink
% Modèle attendu : chaine_P3.slx (voir la liste des blocs).
% Bits équiprobables, seuil nul, L échantillons par bit.
clear; close all; clc;
Parametres
modele = 'chaine_P3';
load_system(modele);

%% Étape 1 : recherche du retard (bruit nul)
% Sans bruit, le seul réglage de D qui donne (presque) 0 erreur est le bon.
h_rx = ones(1, L) / L;                      % intégrateur : moyenne sur un bit
fprintf('=== Recherche du retard D (sigma2 = 0, 1000 bits) ===\n');
for D = 0:3
    in = Simulink.SimulationInput(modele);
    in = in.setVariable('sigma2', 0);
    in = in.setVariable('D', D);
    in = in.setModelParameter('StopTime', num2str(1000*Tb));
    out = sim(in);
    e = out.get('err');  e = e(end, :);
    fprintf('D = %d : %4d erreurs / %d bits\n', D, e(2), e(3));
end
fprintf('-> reporter la bonne valeur dans D ci-dessous.\n\n');

%% Étape 2 : courbes de TEB (Q12)
D = 2;                                      % <-- valeur trouvée à l'étape 1
assignin('base', 'D', D);

h_rx = ones(1, L) / L;                      % avec intégration
res_int = trace_TEB(modele, EbN0_vec, Te, 'Legende', 'Simulink, avec intégrateur');
fig = gcf;

h_rx = zeros(1, L);  h_rx(L - floor(L/2)) = 1;   % un seul échantillon (milieu du bit)
res_ech = trace_TEB(modele, EbN0_vec, Te, 'Figure', fig, 'Theorie', [], ...
                    'Legende', 'Simulink, échantillon central');

Qf = @(x) 0.5*erfc(x/sqrt(2));
xf = linspace(min(EbN0_vec), max(EbN0_vec), 200);
semilogy(xf, Qf(sqrt(2*10.^(xf/10)/L)), '--', 'LineWidth', 1.2, ...
         'DisplayName', sprintf('Théorie sans intégration (-%.1f dB)', 10*log10(L)));
ylim([1e-6 1]);
title('Chaîne de base sous Simulink : TEB en fonction de E_b/N_0');
