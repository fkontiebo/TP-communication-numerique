function code = huffman_code(prob)
%HUFFMAN_CODE  Code de Huffman binaire d'une source de probabilités prob.
%   code = huffman_code(prob) rend un tableau de cellules : code{i} est le
%   mot binaire (chaîne de '0' et '1') associé au symbole i.
%
%   Principe : on fusionne de proche en proche les deux noeuds les moins
%   probables. Chaque noeud mémorise la liste des symboles (feuilles) qu'il
%   contient ; lors d'une fusion, on ajoute '0' en tête des mots du premier
%   noeud et '1' en tête des mots du second. On remonte ainsi l'arbre des
%   feuilles vers la racine.
prob = prob(:);
M = numel(prob);
code = repmat({''}, M, 1);
if M == 1
    code{1} = '0';                      % cas dégénéré : 1 symbole
    return;
end

noeuds = num2cell((1:M).');             % noeud k -> symboles qu'il contient
p = prob;
while numel(p) > 1
    [p, ord] = sort(p, 'ascend');       % les deux moins probables en tête
    noeuds = noeuds(ord);
    for m = noeuds{1}, code{m} = ['0' code{m}]; end
    for m = noeuds{2}, code{m} = ['1' code{m}]; end
    p      = [p(1) + p(2); p(3:end)];   % fusion
    noeuds = [{[noeuds{1}, noeuds{2}]}; noeuds(3:end)];
end
end
