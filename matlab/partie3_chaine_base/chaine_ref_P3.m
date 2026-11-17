function [nerr, nbits] = chaine_ref_P3(sigma2, A, L, nBitsMax, nErrMax, integrer)
%CHAINE_REF_P3  Chaîne de base en Matlab pur (référence pour Simulink).
%   Bits équiprobables, ±A répété L fois, bruit gaussien par échantillon,
%   intégrateur à remise à zéro (moyenne sur L) ou échantillon central,
%   seuil nul. Traitement par blocs pour limiter la mémoire.
if nargin < 6, integrer = true; end
nerr = 0;  nbits = 0;  bloc = 1e5;
while nbits < nBitsMax && nerr < nErrMax
    b = rand(bloc, 1) < 0.5;
    r = repmat(A*(2*b - 1), 1, L) + sqrt(sigma2)*randn(bloc, L);
    if integrer
        z = mean(r, 2);                    % z_k = (1/L) sum r_{kL+i}
    else
        z = r(:, floor(L/2) + 1);          % un échantillon au milieu du bit
    end
    nerr  = nerr + sum((z > 0) ~= b);
    nbits = nbits + bloc;
end
end