function demo_video(etapes, attendre)
%DEMO_VIDEO  Démonstrations courtes pour la vidéo de présentation du TP.
%   demo_video            % toutes les étapes, pause (touche Entrée) entre chacune
%   demo_video(4)         % une seule étape (ici : Hamming)
%   demo_video(1:7, false)% sans pause (vérification)
%
%   Chaque étape dure quelques secondes : elle montre un calcul ou une
%   simulation représentative de la partie, sans refaire les courbes
%   complètes (celles-ci sont produites par run_all.m, environ 8 min).
%     1 : paramètres personnels et reproductibilité
%     2 : codage de source (entropie, Huffman, Candide)
%     3 : chaîne de base Simulink (détecteur optimal)
%     4 : code de Hamming (7,4)
%     5 : modulation QPSK
%     6 : filtre en racine de cosinus surélevé
%     7 : canal à deux trajets et transmission d'un texte
if nargin < 1 || isempty(etapes), etapes = 1:7; end
if nargin < 2, attendre = true; end

racine = fileparts(mfilename('fullpath'));
evalin('base', sprintf('run(''%s'')', fullfile(racine, 'init_tp.m')));
lire = @(v) evalin('base', v);
close all;

for e = etapes
    switch e
        case 1, etape1(lire);
        case 2, etape2(lire);
        case 3, etape3(lire);
        case 4, etape4(lire);
        case 5, etape5(lire);
        case 6, etape6(lire);
        case 7, etape7(lire);
    end
    if attendre && e ~= etapes(end)
        input(sprintf('\n--- Entrée pour passer à l''étape %d ---', e + 1), 's');
    end
end
fprintf('\nFin de la démonstration.\n');
end

%% ------------------------------------------------------------------------
function titre(n, texte)
fprintf('\n=============================================================\n');
fprintf('  ÉTAPE %d : %s\n', n, texte);
fprintf('=============================================================\n');
end

%% 1 - Paramètres --------------------------------------------------------
function etape1(lire)
titre(1, 'Paramètres personnels et reproductibilité');
P = lire('P');
disp(P);
fprintf('Ces valeurs ont été tirées une seule fois (parametres_perso) puis figées\n');
fprintf('dans mes_parametres.mat : toutes les simulations utilisent rng(graine)\n');
fprintf('ou le paramètre Seed des blocs Simulink -> résultats identiques à chaque exécution.\n');
end

%% 2 - Codage de source ---------------------------------------------------
function etape2(lire)
titre(2, 'Codage de source : entropie et Huffman');
p1 = lire('p1');  graine = lire('graine');
rng(graine);
b = source(1e5, p1);
fprintf('Source binaire : fréquence des 1 sur 1e5 bits = %.4f (p1 = %.2f)\n', mean(b), p1);
fprintf('Entropie H(p1) = %.4f bit/symbole\n\n', entropie_binaire(p1));

pr = [0.4 0.2 0.2 0.1 0.1];
code = huffman_code(pr);
lg = cellfun(@numel, code(:)).';
fprintf('Huffman de (0,4 ; 0,2 ; 0,2 ; 0,1 ; 0,1) :\n');
for i = 1:numel(code), fprintf('   symbole %d -> %s\n', i, code{i}); end
fprintf('   longueur moyenne = %.2f bits, somme de Kraft = %.2f\n\n', sum(pr .* lg), sum(2.^-lg));

fid = fopen('candide.txt', 'r', 'n', 'UTF-8');  texte = fread(fid, '*char').';  fclose(fid);
texte(texte == char(13)) = [];                       % comme partie2_2 : CRLF -> LF
if texte(1) == char(65279), texte(1) = []; end       % BOM UTF-8
[H, symb, prob] = entropie_empirique(texte);
code = huffman_code(prob);
Lm = sum(prob(:) .* cellfun(@numel, code(:)));
fprintf('Candide : %d caractères, %d symboles, H = %.3f bit/car.\n', numel(texte), numel(symb), H);
fprintf('Huffman : L moyen = %.3f bit/car., efficacité = %.1f %%\n', Lm, 100*H/Lm);
extrait = texte(1:2000);
bits = huffman_enc(extrait, symb, code);
retour = huffman_dec(bits, symb, code);
fprintf('Codage/décodage de 2000 caractères : %d bits, restitution exacte = %d\n', ...
        numel(bits), isequal(char(retour(:).'), extrait));
end

%% 3 - Chaîne de base -----------------------------------------------------
function etape3(lire)
titre(3, 'Chaîne de base Simulink : détecteur optimal (intégrateur)');
modele = 'chaine_P3';  open_system(modele);
L = lire('L');  Te = lire('Te');  Eb = lire('Eb');
EbN0 = 6;  N0 = Eb / 10^(EbN0/10);  Q = @(x) 0.5*erfc(x/sqrt(2));
for cas = 1:2
    if cas == 1, h = ones(1, L)/L; nom = 'avec intégrateur';
    else, h = zeros(1, L); h(L - floor(L/2)) = 1; nom = 'un seul échantillon'; end
    in = Simulink.SimulationInput(modele);
    in = in.setVariable('h_rx', h);  in = in.setVariable('sigma2', N0/(2*Te));
    in = in.setModelParameter('StopTime', '2e5');
    out = sim(in);  e = out.err(end, :);
    fprintf('%-20s : TEB = %.2e (%d erreurs / %d bits)\n', nom, e(1), e(2), e(3));
end
fprintf('Théorie Q(sqrt(2 Eb/N0)) à %d dB = %.2e\n', EbN0, Q(sqrt(2*10^(EbN0/10))));
fprintf('Sans intégration, la variance du bruit est L = %d fois plus grande : 12 dB perdus.\n', L);
end

%% 4 - Hamming -------------------------------------------------------------
function etape4(lire)
titre(4, 'Code de Hamming (7,4)');
G = lire('G');  H = lire('H');
disp('G = ');  disp(G);  disp('H = ');  disp(H);
m = [1 0 1 1];
c = hamming_enc(m, G);
fprintf('message %s -> mot-code %s\n', sprintf('%d', m), sprintf('%d', c));
r = c;  r(3) = 1 - r(3);
[mh, ~, s] = hamming_dec(r, H);
fprintf('1 erreur (bit 3)  : reçu %s, syndrome %s -> message %s (corrigé)\n', ...
        sprintf('%d', r), sprintf('%d', s), sprintf('%d', mh));
r = c;  r([3 6]) = 1 - r([3 6]);
[~, ch, s] = hamming_dec(r, H);
fprintf('2 erreurs (3 et 6): reçu %s, syndrome %s -> mot %s : %d bits faux au lieu de 2\n', ...
        sprintf('%d', r), sprintf('%d', s), sprintf('%d', ch), sum(ch ~= c));
open_system('codeur_hamming');
end

%% 5 - QPSK ----------------------------------------------------------------
function etape5(lire)
titre(5, 'Modulation QPSK (mapping de Gray)');
modele = 'chaine_P5';  open_system(modele);
figure('Name', 'QPSK');
ebn0 = [0 5 10];
for i = 1:3
    N0 = 0.5 / 10^(ebn0(i)/10);
    in = Simulink.SimulationInput(modele);
    in = in.setVariable('sigma2', N0/2);  in = in.setVariable('nErrMax', inf);
    in = in.setModelParameter('StopTime', num2str(2000*lire('Ts')));
    out = sim(in);
    iq = squeeze(double(out.get('iq_rx')));  if size(iq, 1) == 2, iq = iq.'; end
    subplot(1, 3, i);  plot(iq(:, 1), iq(:, 2), '.', 'MarkerSize', 4);  hold on;
    plot(lire('tab_I'), lire('tab_Q'), 'r+', 'MarkerSize', 14, 'LineWidth', 2);
    axis equal;  grid on;  xlim([-2 2]);  ylim([-2 2]);
    title(sprintf('E_b/N_0 = %d dB', ebn0(i)));  xlabel('I');  ylabel('Q');
end
fprintf('Gray : 00 -> pi/4, 10 -> 3pi/4, 11 -> 5pi/4, 01 -> 7pi/4\n');
fprintf('I = (1-2 b1)/sqrt(2), Q = (1-2 b2)/sqrt(2) : deux BPSK en quadrature.\n');
fprintf('Même TEB que la chaîne binaire, bande divisée par 2.\n');
end

%% 6 - RRC -----------------------------------------------------------------
function etape6(lire)
titre(6, 'Filtre en racine de cosinus surélevé');
alpha = lire('alpha');  L = lire('L');  span = lire('span');
h = rrc_coef(alpha, L, span);
g = conv(h, fliplr(h));
t = (0:numel(g) - 1)/L - span;
k = -5:5;  pic = numel(h);
figure('Name', 'RRC');
subplot(1, 2, 1);  plot((0:numel(h) - 1)/L - span/2, h, 'LineWidth', 1.2);  grid on;
hold on;  stem(-5:5, h(numel(h)/2 + 0.5 + (-5:5)*L), 'filled');
title(sprintf('h (RRC, \\alpha = %.2f) : ne s''annule pas en kT', alpha));  xlabel('t / T');
subplot(1, 2, 2);  plot(t, g, 'LineWidth', 1.2);  grid on;  hold on;
stem(k, g(pic + k*L), 'filled');
title('h * h(-t) : s''annule en kT, k \neq 0 (Nyquist)');  xlabel('t / T');
fprintf('h(kT), k = 1..3       : %s\n', mat2str(round(h(numel(h)/2 + 0.5 + (1:3)*L), 3)));
fprintf('(h*h)(kT), k = 1..3   : %s\n', mat2str(round(g(pic + (1:3)*L), 4)));
open_system('chaine_P6');
end

%% 7 - Canal à deux trajets + texte --------------------------------------
function etape7(lire)
titre(7, 'Canal à deux trajets et transmission d''un texte');
modele = 'chaine_P7';  open_system(modele);
beta = lire('beta');  tau = lire('tau');  L = lire('L');  Tb = lire('Tb');
G = lire('G');  H = lire('H');
hc = [1 zeros(1, tau*L - 1) beta];
fprintf('Canal hc(t) = delta(t) + %.2f delta(t - %dT)\n', beta, tau);
D7 = 24;                                   % retard trouvé par partie7_canal

texte = fileread('candide.txt');
i0 = strfind(texte, 'Il y avait en Vestphalie');
extrait = regexprep(texte(i0(1) : i0(1) + 149), '\s+', ' ');
octets = unicode2native(extrait, 'UTF-8');
bits = reshape((dec2bin(octets, 8) - '0').', [], 1);
fprintf('\nÉmis : %s\n', extrait);

configs = {'sans égaliseur', hc, 1; 'avec égaliseur ZF', hc, hc};
for c = 1:2
    for EbN0 = [3 6]
        for code = 0:1
            if code, tx = hamming_enc(bits, G); R = 4/7; else, tx = bits; R = 1; end
            s2 = (0.5/R) / 10^(EbN0/10) / 2;
            N = numel(tx);
            in = Simulink.SimulationInput(modele);
            in = in.setVariable('hc', configs{c, 2});  in = in.setVariable('eq_den', configs{c, 3});
            in = in.setVariable('src_bits', [(0:N-1).'*Tb, double(tx(:))]);
            in = in.setVariable('choix_source', 1);  in = in.setVariable('sigma2', s2);
            in = in.setVariable('D7', D7);  in = in.setVariable('nErrMax', inf);
            in = in.setModelParameter('StopTime', num2str((N + D7 + 4)*Tb));
            out = sim(in);
            r = squeeze(double(out.get('bits_rx')));  rx = r(D7 + 1 : D7 + N);  rx = rx(:);
            if code, rx = hamming_dec(rx, H); end
            oct = uint8(bin2dec(char(reshape(rx, 8, []).' + '0'))).';
            libc = {'non codé', 'Hamming '};
            fprintf('\n[%s, %d dB, %s] %d bits faux / %d\n  %s\n', configs{c, 1}, EbN0, ...
                    libc{code + 1}, sum(rx ~= bits), numel(bits), native2unicode(oct, 'UTF-8'));
        end
    end
end
end
