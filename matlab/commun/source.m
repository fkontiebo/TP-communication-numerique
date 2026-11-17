function b = source(N, p1)
%SOURCE  Source binaire sans mémoire : N bits, P(1) = p1, P(0) = 1 - p1.
%   b = source(N, p1) rend un vecteur colonne de N bits (0/1, double).
%   Principe : u ~ U[0,1]  ->  b = 1 si u < p1, donc P(b = 1) = p1.
%   La graine est fixée par l'appelant : rng(graine) avant l'appel.
if p1 < 0 || p1 > 1
    error('source:p1', 'p1 doit être compris entre 0 et 1.');
end
b = double(rand(N, 1) < p1);
end