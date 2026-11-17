function ok = est_prefixe(code)
%EST_PREFIXE  Vrai si aucun mot de code n'est le début d'un autre mot.
M = numel(code);
ok = true;
for i = 1:M
    for j = 1:M
        if i ~= j && numel(code{i}) <= numel(code{j}) && ...
                strncmp(code{i}, code{j}, numel(code{i}))
            ok = false;
            return;
        end
    end
end
end
