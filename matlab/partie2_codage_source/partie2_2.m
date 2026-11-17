%% partie2_2.m - Entropie d'un texte et codage de Huffman (questions 3 à 6)
clear; close all; clc;
chemins_tp;                         % dossiers du projet sur le chemin
fichier = 'candide.txt';            % <-- nom de ton fichier nettoyé

%% Lecture du texte en UTF-8
fid = fopen(fichier, 'r', 'n', 'UTF-8');
if fid < 0
    error('Fichier %s introuvable : vérifier le Current Folder.', fichier);
end
txt = fread(fid, '*char').';
fclose(fid);
txt(txt == char(13)) = [];          % fins de ligne Windows (CRLF -> LF)
if ~isempty(txt) && txt(1) == char(65279), txt(1) = []; end   % BOM UTF-8
N = numel(txt);

%% Q3 : entropie, alphabet, longueur fixe, redondance
[H, symb, prob] = entropie_empirique(txt);
M     = numel(symb);
nFixe = ceil(log2(M));

fprintf('=== Q3 : %s ===\n', fichier);
fprintf('Nombre de caractères    : %d\n', N);
fprintf('Taille de l''alphabet M  : %d\n', M);
fprintf('Entropie d''ordre 0 H    : %.4f bit/caractère\n', H);
fprintf('Code de longueur fixe   : %d bits/caractère\n', nFixe);
fprintf('Redondance / 8 bits     : %.4f bit/car. (%.1f %%)\n', 8 - H, 100*(1 - H/8));
fprintf('Redondance / %d bits     : %.4f bit/car. (%.1f %%)\n', nFixe, nFixe - H, 100*(1 - H/nFixe));

% Fréquences des 20 caractères les plus fréquents
[ps, ord] = sort(prob, 'descend');
nT = min(20, M);
etiq = arrayfun(@etiquette, symb(ord(1:nT)), 'UniformOutput', false);
figure;
bar(ps(1:nT));  grid on;
set(gca, 'XTick', 1:nT, 'XTickLabel', etiq, 'TickLabelInterpreter', 'none');
xlabel('Caractère');  ylabel('Fréquence d''apparition');
title(sprintf('Les %d caractères les plus fréquents (%s)', nT, fichier), ...
      'Interpreter', 'none');

%% Q4 : validation du code de Huffman sur un exemple connu
pv = [0.4 0.2 0.2 0.1 0.1];
cv = huffman_code(pv);
lv = cellfun(@numel, cv);
fprintf('\n=== Q4 : validation sur p = [0.4 0.2 0.2 0.1 0.1] ===\n');
for i = 1:numel(pv)
    fprintf('  p = %.1f  ->  %s\n', pv(i), cv{i});
end
fprintf('Préfixe        : %d\n', est_prefixe(cv));
fprintf('Somme de Kraft : %.4f (attendu 1)\n', sum(2.^-lv));
fprintf('Longueur moy.  : %.4f bits (attendu 2.2)\n', sum(pv(:) .* lv(:)));
if exist('huffmandict', 'file') == 2
    [~, Lref] = huffmandict(1:numel(pv), pv);
    fprintf('huffmandict    : %.4f bits\n', Lref);
end

%% Q5 : code de Huffman du texte, codeur et décodeur
code = huffman_code(prob);
len  = cellfun(@numel, code);
Lmoy = sum(prob .* len);

fprintf('\n=== Q5 : Huffman du texte ===\n');
fprintf('Préfixe        : %d | Kraft = %.4f\n', est_prefixe(code), sum(2.^-len));
fprintf('Longueur moy.  : %.4f bit/caractère\n', Lmoy);
fprintf('Efficacité H/L : %.4f (%.2f %%)\n', H/Lmoy, 100*H/Lmoy);
fprintf('H <= L < H+1   : %.4f <= %.4f < %.4f -> %d\n', H, Lmoy, H+1, ...
        H <= Lmoy && Lmoy < H + 1);
fprintf('Mots de %d à %d bits\n', min(len), max(len));

tic;
bits    = huffman_enc(txt, symb, code);
txt_dec = huffman_dec(bits, symb, code);
t = toc;
fprintf('Codage + décodage : %.2f s\n', t);
fprintf('Texte restitué sans erreur : %d\n', isequal(txt, txt_dec));

d = dir(which(fichier));            % which : le texte est sur le chemin Matlab
fprintf('Taille codée            : %d bits = %.0f octets\n', numel(bits), numel(bits)/8);
fprintf('Taux / 8 bits par car.  : %.4f (gain %.1f %%)\n', ...
        numel(bits)/(8*N), 100*(1 - numel(bits)/(8*N)));
fprintf('Taux / fichier UTF-8    : %.4f (%d octets sur disque)\n', ...
        numel(bits)/(8*d.bytes), d.bytes);

%% Q6 : coût de transmission de la table de codage
bSymb = ceil(log2(max(double(symb)) + 1));  % bits pour un caractère (code Unicode)
bLong = ceil(log2(max(len) + 1));           % bits pour une longueur de mot
C_tab   = M * (bSymb + bLong) + sum(len);   % symbole + longueur + mot
C_canon = M * (bSymb + bLong);              % Huffman canonique : longueurs seules
N_1pc   = ceil(100 * C_tab / Lmoy);         % table < 1 % du message codé

fprintf('\n=== Q6 : coût de la table ===\n');
fprintf('Table complète   : %d bits (%d symboles x (%d + %d) + %d bits de mots)\n', ...
        C_tab, M, bSymb, bLong, sum(len));
fprintf('Huffman canonique: %d bits\n', C_canon);
fprintf('Part de la table pour ce texte : %.3f %%\n', 100 * C_tab / numel(bits));
fprintf('Table < 1 %% du message dès N >= %d caractères\n', N_1pc);

%% ------------------------------------------------------------------------
function s = etiquette(c)
% Libellé lisible d'un caractère pour l'axe des abscisses
switch c
    case ' ',      s = 'esp';
    case char(10), s = '\n';
    otherwise,     s = c;
end
end
