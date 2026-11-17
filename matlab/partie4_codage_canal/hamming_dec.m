function [m_hat, c_hat, s] = hamming_dec(r, H)
%HAMMING_DEC  Décodage par syndrome d'un code de Hamming systématique.
%   [m_hat, c_hat, s] = hamming_dec(r, H)
%   r     : bits reçus (vecteur de longueur multiple de n, ou matrice N x n)
%   H     : matrice de contrôle (n-k) x n, H = [P' | I_{n-k}]
%   m_hat : messages décodés (k premiers bits de chaque mot corrigé)
%   c_hat : mots-codes corrigés
%   s     : syndromes (N x (n-k))
%
%   Principe : s = r H' (mod 2). Si s = 0, aucun erreur détectée. Sinon,
%   s est égal à la colonne de H correspondant à la position erronée (erreur
%   simple) : on inverse ce bit.
[nk, n] = size(H);
k = n - nk;
vecteur = isvector(r);
if vecteur
    R = reshape(r(:), n, []).';
else
    R = r;
end
R = double(R);
s = mod(R * H.', 2);                      % syndromes, une ligne par mot

% Table syndrome -> position : la colonne j de H, lue comme un entier
poids = 2.^(nk-1:-1:0);
num_col = poids * H;                      % 1 x n
table = zeros(1, 2^nk - 1);
table(num_col) = 1:n;

num_s = s * poids.';                      % N x 1
c_hat = R;
err = find(num_s > 0);
pos = table(num_s(err));
lin = sub2ind(size(R), err(:), pos(:));
c_hat(lin) = 1 - c_hat(lin);              % correction de l'erreur simple

M_hat = c_hat(:, 1:k);                    % code systématique : message en tête
if vecteur
    m_hat = reshape(M_hat.', [], 1);
    c_hat = reshape(c_hat.', [], 1);
    if isrow(r), m_hat = m_hat.'; c_hat = c_hat.'; end
else
    m_hat = M_hat;
end
end
