%% partie4_hamming.m - Code de Hamming C(7,4), g(x) = 1 + x + x^3
% Questions 1 à 3 (théorie + codeur/décodeur matriciels de référence)
% et table du registre à décalage de la question 5 (référence pour Simulink).
clear; close all; clc;
Parametres                                % n, k, g_poly = [1 1 0 1]

%% Q1 : restes x^3 m(x) mod g(x) pour les messages de poids 1
% Polynômes en coefficients croissants : [a0 a1 a2 ...] = a0 + a1 x + ...
fprintf('=== Q1 : restes x^3 m(x) mod g(x), g(x) = 1 + x + x^3 ===\n');
P = zeros(k, n - k);
for i = 0:k-1
    xm = [zeros(1, 3 + i) 1];             % x^3 * x^i
    reste = mod_poly2(xm, g_poly);        % degré < 3
    P(i+1, :) = reste;
    fprintf('m(x) = x^%d -> x^%d mod g = %s  -> r = [%d %d %d]\n', ...
            i, 3 + i, poly2str2(reste), reste);
end
G = [eye(k) P];
H = [P.' eye(n - k)];
disp('G = [I4 | P] ='); disp(G);
disp('H = [P'' | I3] ='); disp(H);
fprintf('G H'' = 0 : %d\n', all(all(mod(G * H.', 2) == 0)));

%% Q2 : colonnes de H, distance minimale
fprintf('\n=== Q2 : colonnes de H ===\n');
col = (2.^(n-k-1:-1:0)) * H;              % chaque colonne lue comme un entier
fprintf('Colonnes de H (en décimal) : %s\n', mat2str(col));
fprintf('Non nulles : %d | distinctes : %d | toutes les valeurs 1..7 : %d\n', ...
        all(col > 0), numel(unique(col)) == n, isequal(sort(col), 1:7));

msgs  = dec2bin(0:2^k-1, k) - '0';        % les 16 messages
mots  = hamming_enc(msgs, G);
poids = sum(mots, 2);
dmin  = min(poids(2:end));                % code linéaire : dmin = poids min non nul
fprintf('Distance minimale dmin = %d -> détecte %d erreurs, corrige %d erreur\n', ...
        dmin, dmin - 1, floor((dmin - 1)/2));
fprintf('Distribution des poids : %s (poids 0..7)\n', mat2str(histcounts(poids, -0.5:1:7.5)));

%% Q3 : validation du codeur et du décodeur
fprintf('\n=== Q3 : validation ===\n');
% Sans erreur
[m_hat, ~, s] = hamming_dec(mots, H);
fprintf('Sans erreur : syndromes nuls %d | messages retrouvés %d\n', ...
        all(s(:) == 0), isequal(m_hat, msgs));

% Une erreur à chacune des 7 positions, pour les 16 messages
ok = true(n, 1);
fprintf('Position | syndrome | 16 messages corrigés\n');
for j = 1:n
    e = zeros(1, n);  e(j) = 1;
    r = mod(mots + e, 2);
    [m_hat, c_hat, s] = hamming_dec(r, H);
    ok(j) = isequal(m_hat, msgs) && isequal(c_hat, mots);
    fprintf('   %d     |  %d%d%d    | %d\n', j, s(1, :), ok(j));
end
fprintf('Toutes les erreurs simples corrigées : %d\n', all(ok));

% Deux erreurs : le décodeur se trompe (il corrige un 3e bit)
e2 = [1 1 0 0 0 0 0];
r = mod(mots + e2, 2);
[m_hat, c_hat] = hamming_dec(r, H);
fprintf('Deux erreurs (positions 1 et 2) : messages faux %d/16, bits faux par mot = %s\n', ...
        sum(any(m_hat ~= msgs, 2)), mat2str(unique(sum(c_hat ~= mots, 2)).'));

% Version vecteur (format utilisé dans la chaîne) sur 4e4 bits aléatoires
rng(graine);
b  = randi([0 1], 4e4, 1);
cb = hamming_enc(b, G);
fprintf('Train de 4e4 bits : codé en %d bits | décodé sans erreur %d\n', ...
        numel(cb), isequal(hamming_dec(cb, H), b));

%% Q5 (référence) : registre à décalage pour m = [1 0 1 1]
m = [1 0 1 1];                             % [m0 m1 m2 m3]
fprintf('\n=== Q5 : registre, m = [m0 m1 m2 m3] = %s ===\n', mat2str(m));
fprintf('Coup | entrée | f = e xor s2 | s0 s1 s2\n');
fprintf('  0  |   -    |      -       |  0  0  0\n');
s_reg = [0 0 0];
for t = 1:4
    e_in = m(5 - t);                       % poids fort d'abord : m3, m2, m1, m0
    f = xor(e_in, s_reg(3));
    s_reg = [f, xor(s_reg(1), f), s_reg(2)];
    fprintf('  %d  |   %d    |      %d       |  %d  %d  %d\n', t, e_in, f, s_reg);
end
fprintf('Registre final (r0 r1 r2) = %s | codeur matriciel : %s\n', ...
        mat2str(s_reg), mat2str(hamming_enc(m, G)));


%% ------------------------------------------------------------------------
function r = mod_poly2(a, g)
% Reste de la division de a(x) par g(x) dans GF(2), coefficients croissants
dg = numel(g) - 1;
a = [a zeros(1, max(0, dg - numel(a)))];
for i = numel(a):-1:dg+1                   % on élimine les degrés >= deg g
    if a(i) == 1
        a(i-dg:i) = mod(a(i-dg:i) + g, 2);
    end
end
r = a(1:dg);
end

function s = poly2str2(c)
% Affichage d'un polynôme GF(2) en coefficients croissants
t = {};
for i = 1:numel(c)
    if c(i)
        switch i - 1
            case 0, t{end+1} = '1';
            case 1, t{end+1} = 'x';
            otherwise, t{end+1} = sprintf('x^%d', i - 1);
        end
    end
end
if isempty(t), s = '0'; else, s = strjoin(t, ' + '); end
end
