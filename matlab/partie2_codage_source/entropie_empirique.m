function [H, symb, prob] = entropie_empirique(x)
%ENTROPIE_EMPIRIQUE  Entropie d'ordre 0 d'une séquence de symboles.
%   [H, symb, prob] = entropie_empirique(x)
%   x    : séquence (texte char, vecteur numérique...)
%   H    : entropie empirique en bit/symbole, H = -sum p log2 p
%   symb : alphabet observé (vecteur ligne, trié)
%   prob : probabilités estimées par les fréquences (vecteur colonne)
[symb, ~, idx] = unique(x(:));
symb = reshape(symb, 1, []);
prob = accumarray(idx, 1) / numel(x);
H = -sum(prob .* log2(prob));
end
