function H = entropie_binaire(p)
%ENTROPIE_BINAIRE  H(p) = -p log2 p - (1-p) log2(1-p), en bit/symbole.
%   Accepte un scalaire ou un vecteur. Convention 0*log2(0) = 0.
H = -p .* log2(p) - (1 - p) .* log2(1 - p);
H(p == 0 | p == 1) = 0;
end