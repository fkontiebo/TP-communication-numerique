%% partie2_3.m - Extension de la source binaire (question 7)
% Huffman sur des blocs de k bits d'une source très déséquilibrée p1_ext.
clear; close all; clc;
Parametres

p    = p1_ext;                  % P(1) de la source très déséquilibrée
H    = entropie_binaire(p);     % entropie par bit de source
kmax = 10;
Nsrc = 1e5;                     % bits de source pour la vérification

rng(graine);
b = source(Nsrc, p);            % même séquence pour tous les k

Lth  = zeros(1, kmax);          % L_k / k théorique
Lmes = zeros(1, kmax);          % L_k / k mesuré sur Nsrc bits
lmax = zeros(1, kmax);          % plus long mot de code
ok   = false(1, kmax);          % décodage sans erreur

fprintf('Source : p1_ext = %.2f, H = %.4f bit/bit de source\n\n', p, H);
fprintf('  k | 2^k  | Lk/k théo | Lk/k mesuré | H + 1/k | Efficacité | lmax | décod.\n');
fprintf('----+------+-----------+-------------+---------+------------+------+-------\n');

for k = 1:kmax
    %% Probabilités des 2^k blocs : p^w (1-p)^(k-w), w = nombre de 1
    symb = 0:2^k - 1;
    w    = sum(dec2bin(symb, k) == '1', 2);
    prob = p.^w .* (1 - p).^(k - w);

    %% Code de Huffman de la k-ième extension
    code = huffman_code(prob);
    len  = cellfun(@numel, code);
    Lth(k)  = sum(prob .* len) / k;
    lmax(k) = max(len);

    %% Vérification : codage de Nsrc bits groupés par blocs de k
    nb   = floor(Nsrc / k);
    blocs = reshape(b(1:nb*k), k, nb).';         % une ligne = un bloc
    val  = blocs * 2.^(k-1:-1:0).';              % bloc -> entier (MSB d'abord)
    bits = huffman_enc(val, symb, code);
    Lmes(k) = numel(bits) / (nb * k);
    ok(k)   = isequal(huffman_dec(bits, symb, code).', val);

    fprintf(' %2d | %4d |  %.4f   |   %.4f    | %.4f  |   %5.1f %%  |  %2d  |   %d\n', ...
            k, 2^k, Lth(k), Lmes(k), H + 1/k, 100*H/Lth(k), lmax(k), ok(k));
end

%% Tracé
kk = 1:kmax;
figure; hold on; grid on; box on;
plot(kk, Lth,  'o-', 'LineWidth', 1.5, 'DisplayName', 'L_k/k théorique');
plot(kk, Lmes, 'x',  'MarkerSize', 9, 'LineWidth', 1.5, ...
     'DisplayName', sprintf('L_k/k mesuré (%g bits)', Nsrc));
plot(kk, H + 1./kk, '--', 'LineWidth', 1.2, 'DisplayName', 'Borne H + 1/k');
yline(H, '-k', 'LineWidth', 1.2, 'DisplayName', sprintf('Entropie H = %.4f', H));
xlabel('Taille des blocs k (bits)');
ylabel('Longueur moyenne par bit de source (bit)');
title(sprintf('Codage de Huffman de la k-ième extension (p_1 = %.2f)', p));
legend('Location', 'northeast');  xlim([1 kmax]);  ylim([0 1.1]);
