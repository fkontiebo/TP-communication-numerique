function x = lz78_dec(idx, sym, A)
%LZ78_DEC  Décodage de Lempel-Ziv 78.
%   x = lz78_dec(idx, sym, A) reconstruit la séquence à partir des couples
%   (idx, sym) produits par lz78_enc. Le décodeur reconstruit le même
%   dictionnaire que le codeur : la phrase k vaut phrase(idx(k)) + sym(k).
nc     = numel(idx);
lenp   = zeros(nc, 1);                  % longueur de chaque phrase émise
for k = 1:nc
    lp = 0;
    if idx(k) > 0, lp = lenp(idx(k)); end
    lenp(k) = lp + (sym(k) > 0);
end

out = zeros(sum(lenp), 1);
fin = 0;
for k = 1:nc
    fin = fin + lenp(k);
    q = fin;                            % on remplit la phrase de la fin
    if sym(k) > 0                       % vers le début, en remontant
        out(q) = sym(k);                % la chaîne des préfixes
        q = q - 1;
    end
    p = idx(k);
    while p > 0
        out(q) = sym(p);
        q = q - 1;
        p = idx(p);
    end
end
x = reshape(A(out), 1, []);
end
