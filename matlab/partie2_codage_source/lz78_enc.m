function [idx, sym, A, nbits] = lz78_enc(x)
%LZ78_ENC  Codage de Lempel-Ziv 78.
%   [idx, sym, A, nbits] = lz78_enc(x)
%   x     : séquence de symboles (texte char, vecteur numérique...)
%   idx   : indices des phrases connues (0 = phrase vide)
%   sym   : symbole ajouté, en indice dans l'alphabet A (0 = aucun, pour
%           une éventuelle phrase finale déjà présente dans le dictionnaire)
%   A     : alphabet de la séquence
%   nbits : coût total, ceil(log2 i) + ceil(log2 |A|) bits pour le i-ème couple
%
%   Le dictionnaire est un arbre (trie) : fils(n, c) est la ligne de la
%   phrase obtenue en prolongeant la phrase n par le symbole c.
%   Ligne 1 = phrase vide (indice 0), ligne k+1 = phrase d'indice k.
[A, ~, s] = unique(x(:));
nA  = numel(A);
cap = 1024;
fils = zeros(cap, nA, 'int32');
nPh  = 0;                               % nombre de phrases du dictionnaire
idx  = zeros(numel(s), 1);
sym  = zeros(numel(s), 1);
nc   = 0;                               % nombre de couples émis
noeud = 1;                              % on part de la phrase vide

for t = 1:numel(s)
    c = s(t);
    suiv = fils(noeud, c);
    if suiv > 0                         % phrase connue : on la prolonge
        noeud = suiv;
    else                                % nouvelle phrase : on émet le couple
        nc = nc + 1;
        idx(nc) = noeud - 1;
        sym(nc) = c;
        nPh = nPh + 1;
        if nPh + 1 > cap                % agrandissement du dictionnaire
            cap = 2 * cap;
            fils(cap, nA) = 0;
        end
        fils(noeud, c) = nPh + 1;
        noeud = 1;
    end
end
if noeud ~= 1                           % fin du message au milieu d'une phrase
    nc = nc + 1;
    idx(nc) = noeud - 1;
    sym(nc) = 0;
end
idx = idx(1:nc);
sym = sym(1:nc);

i = (1:nc).';
nbits = sum(ceil(log2(i))) + nc * ceil(log2(max(nA, 2)));
end
