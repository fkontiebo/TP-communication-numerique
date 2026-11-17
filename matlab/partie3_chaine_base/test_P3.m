%% test_P3.m - Validation de trace_TEB avec la chaîne de référence Matlab
% Partie 3, question 12 : TEB avec intégrateur vs échantillon central.
clear; close all; clc;
Parametres                                  % charge A, L, Te, nErrMax...

% Chaîne avec intégrateur (détecteur optimal)
f = @(s2, ~) chaine_ref_P3(s2, A, L, nBitsMax, nErrMax, true);
res_int = trace_TEB(f, EbN0_vec, Te, 'Legende', 'Avec intégrateur');
fig = gcf;

% Chaîne sans intégration : un échantillon au milieu du bit
g = @(s2, ~) chaine_ref_P3(s2, A, L, nBitsMax, nErrMax, false);
res_ech = trace_TEB(g, EbN0_vec, Te, 'Figure', fig, 'Theorie', [], ...
                    'Legende', 'Échantillon central');

% Courbe théorique attendue sans intégration : perte de 10*log10(L) dB
xf = linspace(min(EbN0_vec), max(EbN0_vec), 200);
semilogy(xf, Q(sqrt(2*10.^(xf/10)/L)), '--', 'LineWidth', 1.2, ...
         'DisplayName', sprintf('Théorie sans intégration (-%.1f dB)', 10*log10(L)));
ylim([1e-6 1]);