%% partie2_5.m - Complément : codage de Lempel-Ziv 78 (questions 10 et 11)
clear; close all; clc;
Parametres
fichier = 'candide.txt';

%% Q10 : validation sur l'exemple de l'énoncé
x = 'ABAABABAABAB';
[idx, sym, A, nb] = lz78_enc(x);
fprintf('=== Q10 : validation sur %s ===\n', x);
for k = 1:numel(idx)
    if sym(k) > 0, s = A(sym(k)); else, s = '-'; end
    fprintf('(%d,%c) ', idx(k), s);
end
fprintf('\nAttendu : (0,A) (0,B) (1,A) (2,A) (4,A) (4,B)\n');
fprintf('Décodage correct : %d | coût : %d bits pour %d symboles\n', ...
        isequal(lz78_dec(idx, sym, A), x), nb, numel(x));

% Test aléatoire : codage + décodage de 1e4 symboles quelconques
rng(graine);
y = char('a' + randi(4, 1, 1e4) - 1);
[i2, s2, A2] = lz78_enc(y);
fprintf('Test aléatoire (1e4 symboles, 4 lettres) : %d\n', isequal(lz78_dec(i2, s2, A2), y));

%% Q11 : texte complet et 5000 premiers caractères
fid = fopen(fichier, 'r', 'n', 'UTF-8');
txt = fread(fid, '*char').';  fclose(fid);
txt(txt == char(13)) = [];
if ~isempty(txt) && txt(1) == char(65279), txt(1) = []; end

fprintf('\n=== Q11 : LZ78 sur %s ===\n', fichier);
fprintf('%-20s | %8s | %7s | %10s | %8s | %6s\n', ...
        'Extrait', 'N', 'Couples', 'LZ78 b/car', 'H0', 'Décod.');
extraits = {txt, txt(1:5000)};
noms     = {'Texte complet', '5000 premiers car.'};
for e = 1:2
    t = extraits{e};
    [ie, se, Ae, nbe] = lz78_enc(t);
    fprintf('%-20s | %8d | %7d | %10.4f | %8.4f | %6d\n', noms{e}, numel(t), ...
            numel(ie), nbe/numel(t), entropie_empirique(t), ...
            isequal(lz78_dec(ie, se, Ae), t));
end

%% Q11 : source binaire p1_ext, messages de 1e3 à 1e6 bits
Hb   = entropie_binaire(p1_ext);
Nvec = round(logspace(3, 6, 13));
taux = zeros(size(Nvec));
rng(graine);
b = source(Nvec(end), p1_ext);              % un seul tirage, préfixes croissants
fprintf('\n=== Q11 : source binaire p1_ext = %.2f, H = %.4f ===\n', p1_ext, Hb);
fprintf('%9s | %8s | %10s | %8s\n', 'N bits', 'Couples', 'LZ78 b/bit', 'LZ78/H');
for j = 1:numel(Nvec)
    [ib, ~, ~, nbb] = lz78_enc(b(1:Nvec(j)));
    taux(j) = nbb / Nvec(j);
    fprintf('%9d | %8d | %10.4f | %8.3f\n', Nvec(j), numel(ib), taux(j), taux(j)/Hb);
end

figure;
semilogx(Nvec, taux, 'o-', 'LineWidth', 1.5, 'DisplayName', 'LZ78');  hold on;
yline(Hb, '-k', 'LineWidth', 1.2, 'DisplayName', sprintf('Entropie H = %.4f', Hb));
yline(1, '--', 'LineWidth', 1, 'DisplayName', 'Sans codage (1 bit/bit)');
grid on;  box on;
xlabel('Longueur du message (bits)');  ylabel('Bits codés par bit de source');
title(sprintf('LZ78 sur une source binaire sans mémoire (p_1 = %.2f)', p1_ext));
legend('Location', 'northeast');
