function c = hamming_enc(m, G)
%HAMMING_ENC  Codage en bloc systématique par produit matriciel modulo 2.
%   c = hamming_enc(m, G)
%   m : vecteur de bits (longueur multiple de k) ou matrice (une ligne = un message)
%   G : matrice génératrice k x n, G = [I_k | P]
%   c : mots-codes, même format que m (vecteur de longueur n*N/k, ou N x n)
[k, n] = size(G);
vecteur = isvector(m);
if vecteur
    if mod(numel(m), k) ~= 0
        error('hamming_enc:taille', 'La longueur du message doit être un multiple de %d.', k);
    end
    M = reshape(m(:), k, []).';          % une ligne = un message de k bits
else
    M = m;
end
C = mod(double(M) * G, 2);
if vecteur
    c = reshape(C.', [], 1);
    if isrow(m), c = c.'; end
else
    c = C;
end
end
