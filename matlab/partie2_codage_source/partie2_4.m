%% partie2_4.m - Sources avec mémoire et compresseurs réels (questions 8 et 9)
clear; close all; clc;
chemins_tp;                         % dossiers du projet sur le chemin
fichier = 'candide.txt';
txt = lire_texte(fichier);

%% Q8 : comparaison texte complet / 5000 premiers caractères
R(1) = analyse(txt,         'Texte complet');
R(2) = analyse(txt(1:5000), '5000 premiers car.');

methodes = {'Longueur fixe', 'Entropie H0', 'Huffman', 'H(X1X2)/2', ...
            'gzip', 'bzip2', '7z (LZMA)'};
fprintf('=== Q8 : bits par caractère (%s) ===\n', fichier);
fprintf('%-16s | %13s | %18s\n', 'Méthode', R(1).nom, R(2).nom);
fprintf('-----------------+---------------+-------------------\n');
for m = 1:numel(methodes)
    fprintf('%-16s | %13.4f | %18.4f\n', methodes{m}, R(1).v(m), R(2).v(m));
end
fprintf('\nH(X2|X1) = H(X1X2) - H(X1)  : %.4f | %.4f bit/car.\n', R(1).Hcond, R(2).Hcond);
fprintf('Paires distinctes observées : %d sur %d possibles | %d sur %d\n', ...
        R(1).nPaires, R(1).M^2, R(2).nPaires, R(2).M^2);
if isnan(R(1).v(6))
    fprintf('\n7-Zip introuvable : compresser %s à la main (bzip2 et 7z) et\n', fichier);
    fprintf('calculer 8 x taille(octets) / N pour compléter le tableau.\n');
end

figure;
bar(categorical(methodes, methodes), [R(1).v(:), R(2).v(:)]);
grid on;  ylabel('Bits par caractère');
legend(R(1).nom, R(2).nom, 'Location', 'northeast');
title(sprintf('Comparaison des méthodes de codage (%s)', fichier), 'Interpreter', 'none');

%% Q9 : statistiques des bits en sortie du codeur de Huffman (texte complet)
[~, symb, prob] = entropie_empirique(txt);
code = huffman_code(prob);
bits = double(huffman_enc(txt, symb, code));

f1 = mean(bits);
nb = floor(numel(bits) / 2);
v  = 2*bits(1:2:2*nb) + bits(2:2:2*nb);         % paires disjointes 00..11
[Hp, vp, pp] = entropie_empirique(v);

fprintf('\n=== Q9 : sortie du codeur de Huffman (%d bits) ===\n', numel(bits));
fprintf('Proportion de 1          : %.4f (idéal 0.5)\n', f1);
fprintf('Entropie d''un bit H(f1)  : %.4f bit/bit\n', entropie_binaire(f1));
fprintf('Entropie des paires / 2  : %.4f bit/bit (idéal 1)\n', Hp/2);
for i = 1:numel(vp)
    fprintf('  P(%s) = %.4f (idéal 0.25)\n', dec2bin(vp(i), 2), pp(i));
end

%% ------------------------------------------------------------------------
function txt = lire_texte(f)
% Lecture UTF-8, suppression des \r (CRLF) et du BOM éventuel
fid = fopen(f, 'r', 'n', 'UTF-8');
if fid < 0, error('Fichier %s introuvable.', f); end
txt = fread(fid, '*char').';
fclose(fid);
txt(txt == char(13)) = [];
if ~isempty(txt) && txt(1) == char(65279), txt(1) = []; end
end

function R = analyse(txt, nom)
% Toutes les mesures de la Q8 pour un texte donné, en bit/caractère
N = numel(txt);
[H0, symb, prob] = entropie_empirique(txt);
M    = numel(symb);
code = huffman_code(prob);
Lh   = sum(prob .* cellfun(@numel, code));      % table de codage non comptée

% Entropie des paires de caractères consécutifs (paires chevauchantes)
[~, ~, id] = unique(txt(:));
paires = (id(1:end-1) - 1) * M + id(2:end);     % une paire -> un entier
H12 = entropie_empirique(paires);               % H(X1X2)

% Compresseurs réels : on écrit le texte (UTF-8, sans \r) puis on compresse
f = fullfile(tempdir, 'tp_texte.txt');
fid = fopen(f, 'w', 'n', 'UTF-8');  fwrite(fid, txt, 'char');  fclose(fid);
g  = gzip(f, tempdir);
dg = dir(g{1});

R.nom     = nom;
R.M       = M;
R.nPaires = numel(unique(paires));
R.Hcond   = H12 - H0;                           % H(X2|X1), H(X1) ~ H0
R.v = [ceil(log2(M)), H0, Lh, H12/2, 8*dg.bytes/N, ...
       compresse_7z(f, 'bzip2', N), compresse_7z(f, '7z', N)];
end

function r = compresse_7z(f, type, N)
% Taux en bit/caractère avec 7-Zip (NaN si 7-Zip n'est pas installé)
exe = 'C:\Program Files\7-Zip\7z.exe';
r = NaN;
if exist(exe, 'file') ~= 2, return; end
switch type
    case 'bzip2', out = [f '.bz2'];
    otherwise,    out = [f '.7z'];
end
if exist(out, 'file') == 2, delete(out); end
[st, ~] = system(sprintf('"%s" a -t%s -mx=9 -y "%s" "%s"', exe, type, out, f));
if st == 0
    d = dir(out);
    r = 8 * d.bytes / N;
end
end
