%% partie7_canal.m - Partie 7 : canal à deux trajets, égalisation, transmission d'un texte
% Modèle : chaine_P7.slx = chaine_P6 (QPSK + RRC) + canal hc + égaliseur ZF optionnel
%          + source From Workspace / bits reçus To Workspace.
% Canal : hc(t) = delta(t) + beta*delta(t - tau*Ts)   (beta, tau : paramètres personnels)
% Convention : Eb/N0 est défini par l'énergie émise sur le trajet principal
% (le gain de l'écho n'est pas compté), comme pour un canal réel non normalisé.
clear; close all; clc;
Parametres
modele = 'chaine_P7';
load_system(modele);
Qf = @(x) 0.5*erfc(x/sqrt(2));
N0_de = @(x) 0.5 / 10^(x/10);                  % Eb vrai = 1/2 (Es = 1), cf. partie 6

hc_echo = [1 zeros(1, tau*L - 1) beta];        % canal à 2 trajets au pas Te_s
cas = struct('nom',  {'sans écho', 'écho', 'écho + égaliseur ZF'}, ...
             'hc',   {1, hc_echo, hc_echo}, ...
             'eq',   {1, 1, hc_echo});
fprintf('Canal : beta = %.2f, tau = %d T (%d échantillons)\n', beta, tau, tau*L);

%% Retard D7 (sigma2 = 0) : le trajet principal n'est pas retardé -> D7 de la partie 6
fprintf('\n=== Recherche du retard (sigma2 = 0, canal à 2 trajets) ===\n');
choisir(cas(2));
D7 = NaN;
for d = 0:60
    e = simuler(modele, 0, 2000*Tb, d, 'err');  e = e(end, :);
    if e(2) <= 2*span + 4, D7 = d; break; end
end
if isnan(D7), error('Aucun retard D7 ne convient.'); end
assignin('base', 'D7', D7);
fprintf('D7 = %d (%d erreurs de remplissage / %d bits)\n', D7, e(2), e(3));

%% Q1 : réponse globale échantillonnée g = h * hc * h(-t) aux instants kT
g0 = conv(h6, fliplr(h6));                     % cosinus surélevé (Nyquist)
g1 = conv(g0, hc_echo);                         % avec l'écho
pic = numel(h6);                                % instant optimal (indice du maximum de g0)
kk = -4:6;
s0 = g0(pic + kk*L);
s1 = g1(pic + kk*L);
fprintf('\n=== Q1 : réponse globale aux instants kT (k = %d..%d) ===\n', kk(1), kk(end));
fprintf('sans écho : %s\n', mat2str(round(s0, 3)));
fprintf('avec écho : %s\n', mat2str(round(s1, 3)));
fprintf('-> IES = beta = %.2f au symbole k = tau = %d : critère de Nyquist non vérifié\n', beta, tau);
fprintf('Ouverture de l''œil (voie I, sans bruit) : %.3f -> %.3f (facteur 1 - beta = %.2f)\n', ...
        1/sqrt(2), (1 - beta)/sqrt(2), 1 - beta);

%% Figure 1 : réponse globale, yeux et constellations
fig1 = figure('Position', [40 60 1300 700]);
subplot(2, 3, 4);  hold on;  grid on;  box on;
t0 = ((1:numel(g0)) - pic)/L;  t1 = ((1:numel(g1)) - pic)/L;
plot(t0, g0, 'Color', [0.6 0.6 0.6], 'DisplayName', 'sans écho');
plot(t1, g1, 'Color', [0 0.45 0.74], 'LineWidth', 1.1, 'DisplayName', 'avec écho');
stem(kk, s1, 'filled', 'Color', [0.85 0.33 0.1], 'DisplayName', 'échantillons en kT');
xlim([-4 6]);  xlabel('t / T');  ylabel('amplitude');
title(sprintf('Réponse globale h*h_c*h(-t) (\\beta = %.2f, \\tau = %dT)', beta, tau));
legend('Location', 'northeast');

yeux = cell(1, 3);
for c = 1:3
    choisir(cas(c));
    yeux{c} = simuler(modele, 0, 1000*Ts, D7, 'y_rx');
    subplot(2, 3, c);  oeil(yeux{c}, L, sprintf('Oeil sans bruit, %s', cas(c).nom));
end
% ouvertures mesurées (voie I, instants d'échantillonnage hors transitoire)
fprintf('\nOuverture mesurée de l''œil (min |y_I| aux instants de décision) :\n');
for c = 1:3
    yi = yeux{c}(:, 1);  ech = yi(1 + (30:numel(yi)/L - 30)*L);
    fprintf('  %-22s : %.3f\n', cas(c).nom, min(abs(ech)));
end
for c = 2:3
    choisir(cas(c));
    iq = simuler(modele, N0_de(10)/2, 1000*Ts, D7, 'iq_rx');
    subplot(2, 3, 3 + c);
    constellation(iq, sprintf('Constellation à 10 dB, %s', cas(c).nom));
end

%% Q1 / Q2 : TEB (simulés et théoriques)
% Écho : sur chaque voie, z = a_k + beta a_{k-tau} + n, a = ±1/sqrt(2) équiprobables
%   -> TEB = [Q((1+beta)sqrt(2x)) + Q((1-beta)sqrt(2x))] / 2
% ZF : 1/Hc(z) rend la réponse de Nyquist, mais amplifie le bruit :
%   variance sigma2 * sum beta^(2i) = sigma2/(1-beta^2)  -> TEB = Q(sqrt(2x(1-beta^2)))
th = {@(x) Qf(sqrt(2*x)), ...
      @(x) 0.5*(Qf((1 + beta)*sqrt(2*x)) + Qf((1 - beta)*sqrt(2*x))), ...
      @(x) Qf(sqrt(2*x*(1 - beta^2)))};
res = cell(1, 3);  fig_teb = [];
for c = 1:3
    choisir(cas(c));
    fprintf('\n--- TEB, %s ---\n', cas(c).nom);
    args = {'Theorie', [], 'Legende', sprintf('%s (simulé)', cas(c).nom)};
    if ~isempty(fig_teb), args = [args, {'Figure', fig_teb}]; end %#ok<AGROW>
    res{c} = trace_TEB(modele, EbN0_vec, Ts, args{:});
    fig_teb = gcf;
end
figure(fig_teb);  set(gca, 'ColorOrderIndex', 1);
xf = linspace(min(EbN0_vec), max(EbN0_vec), 200);
noms_th = {'théorie sans écho', 'théorie écho', 'théorie ZF'};
for c = 1:3
    semilogy(xf, th{c}(10.^(xf/10)), '-', 'LineWidth', 1.1, 'DisplayName', noms_th{c});
end
ylim([1e-6 1]);  legend('Location', 'southwest');
title(sprintf('QPSK + RRC sur canal à 2 trajets (\\beta = %.2f, \\tau = %dT)', beta, tau));

fprintf('\n=== Synthèse TEB ===\n');
fprintf('%-8s %-26s %-26s %-26s\n', 'Eb/N0', cas.nom);
for i = 1:numel(EbN0_vec)
    fprintf('%4d dB ', EbN0_vec(i));
    for c = 1:3
        if i <= numel(res{c}.teb) && ~isnan(res{c}.teb(i))
            fprintf('  sim %.2e / th %.2e  ', res{c}.teb(i), th{c}(10^(EbN0_vec(i)/10)));
        else
            fprintf('  %-24s', '-');
        end
    end
    fprintf('\n');
end
cible = 1e-4;
fprintf('\nEb/N0 théorique pour TEB = 1e-4 :\n');
for c = 1:3
    fprintf('  %-22s : %.2f dB\n', cas(c).nom, 10*log10(fzero(@(x) log(th{c}(x)/cible), [1 100])));
end
fprintf('Pénalité ZF théorique : 10 log10(1/(1-beta^2)) = %.2f dB\n', -10*log10(1 - beta^2));

%% Q3 : transmission d'un texte (From Workspace -> chaîne -> To Workspace)
texte = fileread('candide.txt');
i0 = strfind(texte, 'Il y avait en Vestphalie');
extrait = regexprep(texte(i0(1) : i0(1) + 299), '\s+', ' ');
octets = unicode2native(extrait, 'UTF-8');
bits = reshape((dec2bin(octets, 8) - '0').', [], 1);          % MSB en tête
fprintf('\n=== Q3 : transmission d''un texte ===\n');
fprintf('%d caractères -> %d octets (UTF-8) -> %d bits\n', numel(extrait), numel(octets), numel(bits));
fprintf('Texte émis :\n  %s\n', extrait);

canaux = cas(1:2);                              % sans écho, puis avec écho (sans égaliseur)
assignin('base', 'choix_source', 1);
for c = 1:2
    choisir(canaux(c));
    for EbN0 = [3 6]
        for code = 0:1
            if code, tx = hamming_enc(bits, G); Rc = k/n; else, tx = bits; Rc = 1; end
            s2 = (0.5/Rc) / 10^(EbN0/10) / 2;   % Eb d'information = Eb canal / R
            rx = transmettre(modele, tx, s2, D7, Tb);
            if code, rb = hamming_dec(rx, H); else, rb = rx; end
            ne = sum(rb ~= bits);
            oct_rx = uint8(bin2dec(char(reshape(rb, 8, []).' + '0'))).';
            recu = native2unicode(oct_rx, 'UTF-8');
            libc = {'sans Hamming', 'avec Hamming'};
            fprintf('\n[%s, %d dB, %s] TEB = %.2e (%d/%d), octets faux = %d/%d (%.1f %%)\n', ...
                    canaux(c).nom, EbN0, libc{code + 1}, ne/numel(bits), ne, numel(bits), ...
                    sum(oct_rx ~= octets), numel(octets), 100*mean(oct_rx ~= octets));
            fprintf('  %s\n', recu);
        end
    end
end
assignin('base', 'choix_source', 0);
choisir(cas(1));

%% ------------------------------------------------------------------------
function choisir(c)
assignin('base', 'hc', c.hc);
assignin('base', 'eq_den', c.eq);
end

function v = simuler(modele, s2, duree, d7, nom)
in = Simulink.SimulationInput(modele);
in = in.setVariable('sigma2', s2);  in = in.setVariable('D7', d7);
in = in.setVariable('nErrMax', inf);
in = in.setModelParameter('StopTime', num2str(duree));
out = sim(in);
v = squeeze(double(out.get(nom)));
if size(v, 1) == 2 && size(v, 2) ~= 2, v = v.'; end
end

function rx = transmettre(modele, tx, s2, d7, Tb)
% Injecte les bits tx (From Workspace), récupère les bits décidés (To Workspace)
% et compense le retard d7 de la chaîne.
N = numel(tx);
in = Simulink.SimulationInput(modele);
in = in.setVariable('src_bits', [(0:N-1).'*Tb, double(tx(:))]);
in = in.setVariable('choix_source', 1);
in = in.setVariable('sigma2', s2);  in = in.setVariable('D7', d7);
in = in.setVariable('nErrMax', inf);
in = in.setModelParameter('StopTime', num2str((N + d7 + 4)*Tb));
out = sim(in);
r = squeeze(double(out.get('bits_rx')));
rx = r(d7 + 1 : d7 + N);
rx = rx(:);
end

function oeil(y, L, titre)
yi = y(:, 1);
pics = 1 + (30:numel(yi)/L - 30) * L;
x = (-L:L) / L;
hold on;  grid on;  box on;
for p = pics(1:min(200, end))
    plot(x, yi(p - L : p + L), 'Color', [0 0.45 0.74 0.25]);
end
xline(0, 'r', 'LineWidth', 1.2);  yline(0, 'k');
xlabel('t / T (0 = instant d''échantillonnage)');  ylabel('Voie I');
title(titre);  xlim([-1 1]);  ylim([-1.6 1.6]);
end

function constellation(iq, titre)
hold on;  grid on;  box on;  axis equal;
plot(iq(:, 1), iq(:, 2), '.', 'MarkerSize', 4);
plot([1 1 -1 -1]/sqrt(2), [1 -1 1 -1]/sqrt(2), 'r+', 'MarkerSize', 12, 'LineWidth', 2);
xline(0, 'k');  yline(0, 'k');
xlim([-1.8 1.8]);  ylim([-1.8 1.8]);
xlabel('I');  ylabel('Q');  title(titre);
end
