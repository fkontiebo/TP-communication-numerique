%% partie4_chaine.m - Questions 10 et 11 : chaîne avec / sans codage de Hamming
% Modèles : chaine_P3.slx (sans codage) et chaine_P4.slx (avec codage).
% Convention de l'énoncé : amplitude d'un bit codé Ac = A*sqrt(4/7), L échantillons
% par bit codé, variance du bruit par échantillon sigma2 = N0/(2 Te) (même Te que
% la chaîne non codée)  ->  p = Q(sqrt(2*(4/7)*Eb/N0)) sur un bit codé.
clear; close all; clc;
Parametres
modele = 'chaine_P4';
load_system(modele);

%% Étape 1a : retard sur les bits codés -> alignement des trames (K7)
% Sans bruit, c_rx est une copie retardée de c_tx. Le Buffer de réception doit
% couper les trames au début des mots-codes : il faut un retard total multiple de 7.
in = Simulink.SimulationInput(modele);
in = in.setVariable('sigma2', 0);   in = in.setVariable('K7', 0);
in = in.setVariable('D4', 0);       in = in.setVariable('nErrMax', inf);
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
K7 = mod(-dc, 7);
fprintf('=== Étape 1 : alignement ===\n');
fprintf('Retard des bits codés : %d bits codés -> K7 = %d\n', dc, K7);
assignin('base', 'K7', K7);

%% Étape 1b : retard D4 sur les bits d'information (bruit nul)
D4 = NaN;
for d = 0:30
    in = Simulink.SimulationInput(modele);
    in = in.setVariable('sigma2', 0);  in = in.setVariable('K7', K7);
    in = in.setVariable('D4', d);
    in = in.setModelParameter('StopTime', num2str(2000*Tb));
    out = sim(in);
    e = out.get('err');  e = e(end, :);
    if e(2) <= 4, D4 = d; break; end        % quelques erreurs de démarrage tolérées
end
if isnan(D4), error('Aucun retard D4 ne donne 0 erreur.'); end
fprintf('Retard des bits d''information : D4 = %d (%d erreurs / %d bits)\n', D4, e(2), e(3));
fprintf('-> reporter K7 = %d et D4 = %d dans Parametres.m\n\n', K7, D4);
assignin('base', 'D4', D4);

%% Étape 2 : courbes de TEB (Q10)
Qf = @(x) 0.5*erfc(x/sqrt(2));

% Théorie avec codage (approximation de la question 8)
pc = @(x) Qf(sqrt(2*(4/7)*x));             % TEB sur un bit codé
j  = 2:7;  Cj = arrayfun(@(t) nchoosek(7, t), j);
Pb = @(x) arrayfun(@(xx) sum(j/7 .* Cj .* pc(xx).^j .* (1 - pc(xx)).^(7 - j)), x);

% Théorie exacte : énumération des 128 motifs d'erreur. A(w+1) = somme, sur
% les motifs de poids w, de la proportion de bits du message faux après décodage.
A_w = zeros(1, 8);
for v = 0:127
    e = dec2bin(v, 7) - '0';
    m_hat = hamming_dec(e, H);              % mot émis = 0 (code linéaire)
    A_w(sum(e) + 1) = A_w(sum(e) + 1) + sum(m_hat) / 4;
end
w = 0:7;
Pb_ex = @(x) arrayfun(@(xx) sum(A_w .* pc(xx).^w .* (1 - pc(xx)).^(7 - w)), x);
fprintf('Coefficients A_w (w = 0..7) : %s\n', mat2str(A_w));

% Sans codage (modèle de la partie 3)
h_rx = ones(1, L) / L;
res0 = trace_TEB('chaine_P3', EbN0_vec, Te, 'Legende', 'Sans codage (simulé)', ...
                 'Theorie', @(x) Qf(sqrt(2*x)));
fig = gcf;
% Avec codage : même Te que la chaîne non codée (convention de l'énoncé)
res1 = trace_TEB(modele, EbN0_vec, Te, 'Figure', fig, ...
                 'Legende', 'Hamming (7,4) (simulé)', 'Theorie', Pb);

xf = linspace(-2, max(EbN0_vec), 300);
semilogy(xf, Pb_ex(10.^(xf/10)), '-.', 'LineWidth', 1.5, 'DisplayName', 'Hamming : théorie exacte');

% Limites de Shannon
R = 4/7;
lim_R   = 10*log10((2^(2*R) - 1) / (2*R));
lim_abs = 10*log10(log(2));
xline(lim_R,   '--', sprintf('Shannon R = 4/7 : %.2f dB', lim_R), 'HandleVisibility', 'off');
xline(lim_abs, ':',  sprintf('ln 2 : %.2f dB', lim_abs), 'HandleVisibility', 'off');
xlim([-2 max(EbN0_vec)]);  ylim([1e-6 1]);
title('TEB avec et sans codage de Hamming (7,4)');
lg = legend;  lg.String{2} = 'Sans codage : Q(\surd(2E_b/N_0))';
lg.String{4} = 'Hamming : approximation (Q8)';

%% Q11 : point de croisement et gain de codage à 1e-4
x  = linspace(0, 12, 4001);  xl = 10.^(x/10);
t0 = Qf(sqrt(2*xl));
x0 = interp1(log10(t0), x, -4);
fprintf('\n=== Q11 (théorie) ===\n');
noms = {'approximation Q8', 'théorie exacte'};
courbes = {Pb(xl), Pb_ex(xl)};
for c = 1:2
    t1 = courbes{c};
    ix = find(t1 < t0, 1);
    x1 = interp1(log10(t1), x, -4);
    fprintf('[%s] avantageux dès %.2f dB | TEB 1e-4 : %.2f dB (sans codage %.2f) -> gain %.2f dB | écart Shannon %.2f dB\n', ...
            noms{c}, x(ix), x1, x0, x0 - x1, x1 - lim_R);
end
