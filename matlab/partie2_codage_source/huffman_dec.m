function x = huffman_dec(bits, symb, code)
%HUFFMAN_DEC  Décodage de Huffman par parcours de l'arbre binaire.
%   x = huffman_dec(bits, symb, code)
%   Le code étant préfixe, on descend dans l'arbre bit par bit ; dès qu'on
%   atteint une feuille, le symbole est émis et on repart de la racine
%   (décodage instantané).

%% Reconstruction de l'arbre à partir des mots de code
% fils(n, b+1) : noeud atteint depuis n avec le bit b (0 = pas de fils)
% feuille(n)   : indice du symbole si n est une feuille, 0 sinon
fils = [0 0];  feuille = 0;  nNoeuds = 1;      % noeud 1 = racine
for s = 1:numel(code)
    n = 1;
    for c = code{s}
        b = (c == '1') + 1;
        if fils(n, b) == 0
            nNoeuds = nNoeuds + 1;
            fils(nNoeuds, :) = [0 0];
            feuille(nNoeuds) = 0;
            fils(n, b) = nNoeuds;
        end
        n = fils(n, b);
    end
    feuille(n) = s;
end

%% Parcours
out = zeros(1, numel(bits));
k = 0;  n = 1;
for i = 1:numel(bits)
    n = fils(n, bits(i) + 1);
    if feuille(n) > 0
        k = k + 1;
        out(k) = feuille(n);
        n = 1;
    end
end
if n ~= 1
    warning('huffman_dec:fin', 'Train binaire terminé au milieu d''un mot.');
end
x = symb(out(1:k));
end
