%% partie5_q6.m - Partie 5, question 6 : Hamming (7,4) + QPSK (Gray)
% Modèle : chaine_P5c.slx.
% Un symbole QPSK (|s| = 1) porte 2 bits codés : Ec = 1/2, Eb = (7/4) Ec = 7/8.
% Bruit N0/2 par voie. Avec trace_TEB (Eb = 1 lu dans le workspace) et
% Te_bruit = Ts_c = 2 Tc = 8/7 : sigma2 = (1/10^(x/10)) * 7/16
%                                       = ((7/8)/10^(x/10)) / 2 = N0_vrai / 2.
clear; close all; clc;
Parametres
modele = 'chaine_P5c';
load_system(modele);
Qf = @(x) 0.5*erfc(x/sqrt(2));

%% Étape 1a : alignement des mots-codes (K7c)
in = Simulink.SimulationInput(modele);
in = in.setVariable('sigma2', 0);  in = in.setVariable('K7c', 0);
in = in.setVariable('D6', 0);      in = in.setVariable('nErrMax', inf);
in = in.setModelParameter('StopTime', num2str(500*Tb));
out = sim(in);
ctx = double(out.get('c_tx'));  ctx = ctx(:);
crx = double(out.get('c_rx'));  crx = crx(:);
nb  = min(numel(ctx), numel(crx)) - 40;
dc  = NaN;
for d = 0:40
    if isequal(crx(d+1:d+nb), ctx(1:nb)), dc = d; break; end
end
if isnan(dc), error('Retard sur les bits codés introuvable : vérifier le modèle.'); end
K7c = mod(-dc, 7);
assignin('base', 'K7c', K7c);
fprintf('=== Étape 1 : alignement ===\n');
fprintf('Retard des bits codés : %d bits codés -> K7c = %d\n', dc, K7c);

%% Étape 1b : retard D6 sur les bits d'information
D6 = NaN;
for d = 0:30
    in = Simulink.SimulationInput(modele);
    in = in.setVariable('sigma2', 0);  in = in.setVariable('K7c', K7c);
    in = in.setVariable('D6', d);
    in = in.setModelParameter('StopTime', num2str(2000*Tb));
    out = sim(in);
    e = out.get('err');  e = e(end, :);
    if e(2) <= 4, D6 = d; break; end
end
if isnan(D6), error('Aucun retard D6 ne donne 0 erreur.'); end
assignin('base', 'D6', D6);
fprintf('Retard des bits d''information : D6 = %d (%d erreurs / %d bits)\n', D6, e(2), e(3));
fprintf('-> reporter K7c = %d et D6 = %d dans Parametres.m\n\n', K7c, D6);

%% Étape 2 : TEB (Q6)
% Théorie exacte du Hamming (même calcul qu'en partie 4) : avec Gray, chaque
% bit codé voit une BPSK d'énergie Ec -> p = Q(sqrt(2 (4/7) Eb/N0)).
pc  = @(x) Qf(sqrt(2*(4/7)*x));
A_w = zeros(1, 8);
for v = 0:127
    ev = dec2bin(v, 7) - '0';
    A_w(sum(ev) + 1) = A_w(sum(ev) + 1) + sum(hamming_dec(ev, H)) / 4;
end
w = 0:7;
Pb_ex = @(x) arrayfun(@(xx) sum(A_w .* pc(xx).^w .* (1 - pc(xx)).^(7 - w)), x);

res = trace_TEB(modele, EbN0_vec, Ts_c, 'Legende', 'Hamming + QPSK (simulé)', ...
                'Theorie', Pb_ex);
xf = linspace(min(EbN0_vec), max(EbN0_vec), 300);
semilogy(xf, Qf(sqrt(2*10.^(xf/10))), '--', 'LineWidth', 1.2, ...
         'DisplayName', 'Sans codage (BPSK = QPSK Gray)');
lg = legend;  lg.String{2} = 'Hamming : théorie exacte (= partie 4)';
ylim([1e-6 1]);
title('Hamming (7,4) + QPSK : TEB en fonction de E_b/N_0');

%% Comparaison des débits et de la bande (Tb = 1)
fprintf('\n=== Q6 : comparaison (débit utile fixé à 1/Tb) ===\n');
fprintf('%-24s | %-10s | %-14s | %s\n', 'Chaîne', 'TEB', 'Durée symbole', 'Bande relative');
fprintf('%-24s | %-10s | %-14s | %.3f\n', 'Binaire (P3)',         'Q(..)',   'Tb',      1);
fprintf('%-24s | %-10s | %-14s | %.3f\n', 'Hamming binaire (P4)', 'P4',      '4Tb/7',   7/4);
fprintf('%-24s | %-10s | %-14s | %.3f\n', 'QPSK (P5)',            'Q(..)',   '2Tb',     1/2);
fprintf('%-24s | %-10s | %-14s | %.3f\n', 'Hamming + QPSK',       '= P4',    '8Tb/7',   7/8);
