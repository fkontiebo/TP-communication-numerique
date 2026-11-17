function h = rrc_coef(alpha, L, span)
%RRC_COEF  Coefficients d'un filtre en racine de cosinus surélevé.
%   h = rrc_coef(alpha, L, span)
%   alpha : roll-off (0 < alpha <= 1)
%   L     : échantillons par symbole
%   span  : troncature en symboles -> N = span*L + 1 coefficients
%   h     : vecteur ligne normalisé à énergie unité (sum(h.^2) = 1), de sorte
%           que mise en forme + filtre adapté + échantillonnage rendent le
%           symbole émis à l'instant optimal.
%
%   h(t) = 1/sqrt(T) * [cos(pi(1+a)t/T) + (1-a) sinc((1-a)t/T) * pi/(4a)]
%                      / [pi/(4a) * (1 - (4a t/T)^2)] ... écrit sous la forme
%   h(t) = (4a/(pi sqrt(T))) [cos(pi(1+a)t/T) + (1-a)pi/(4a) sinc((1-a)t/T)]
%          / (1 - (4a t/T)^2)
%   avec les limites (question 2) :
%   t = 0       : h = (1/sqrt(T)) (1 - a + 4a/pi)
%   t = ±T/(4a) : h = (a/sqrt(2T)) [(1 + 2/pi) sin(pi/(4a)) + (1 - 2/pi) cos(pi/(4a))]
if mod(span*L, 2) ~= 0
    error('rrc_coef:parite', 'span*L doit être pair (filtre symétrique, retard entier).');
end
T = 1;
t = (-span*L/2 : span*L/2) / L;              % temps en durées symbole
h = zeros(size(t));
sincn = @(x) sin(pi*x) ./ (pi*x + (x == 0)) + (x == 0);   % sinc(0) = 1 (cas alpha = 1)

for i = 1:numel(t)
    ti = t(i);
    if abs(ti) < 1e-12                                   % limite en t = 0
        h(i) = (1/sqrt(T)) * (1 - alpha + 4*alpha/pi);
    elseif abs(abs(ti) - T/(4*alpha)) < 1e-12            % limite en t = ±T/(4a)
        h(i) = (alpha/sqrt(2*T)) * ((1 + 2/pi)*sin(pi/(4*alpha)) + ...
                                    (1 - 2/pi)*cos(pi/(4*alpha)));
    else
        h(i) = (4*alpha/(pi*sqrt(T))) * ...
               (cos(pi*(1 + alpha)*ti/T) + (1 - alpha)*pi/(4*alpha)*sincn((1 - alpha)*ti/T)) ...
               / (1 - (4*alpha*ti/T)^2);
    end
end
h = h / sqrt(sum(h.^2));                     % énergie unité
end
