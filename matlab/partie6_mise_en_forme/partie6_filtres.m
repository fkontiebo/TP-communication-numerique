%% partie6_filtres.m - Partie 6 : filtres de mise en forme (questions 2 à 4)
% Calculs Matlab seuls (pas de Simulink). Temps en durées symbole T.
clear; close all; clc;
Parametres                                    % alpha, L, span
T = 1;
N = span*L + 1;
t = (-(N-1)/2 : (N-1)/2) / L;

%% Q2 : limites et coefficients
h0   = (1/sqrt(T)) * (1 - alpha + 4*alpha/pi);
hlim = (alpha/sqrt(2*T)) * ((1 + 2/pi)*sin(pi/(4*alpha)) + (1 - 2/pi)*cos(pi/(4*alpha)));
fprintf('=== Q2 : alpha = %.2f, L = %d, span = %d -> N = %d coefficients ===\n', alpha, L, span, N);
fprintf('h(0)         = (1 - a + 4a/pi)/sqrt(T)                            = %.5f\n', h0);
fprintf('h(+-T/(4a))  = a/sqrt(2T) [(1+2/pi) sin(pi/4a) + (1-2/pi) cos(pi/4a)] = %.5f\n', hlim);

% Vérification de la continuité : valeur de la formule générale très près des singularités
f = @(x) (4*alpha/pi) * (cos(pi*(1 + alpha)*x) + (1 - alpha)*pi/(4*alpha) .* ...
         sin(pi*(1 - alpha)*x) ./ (pi*(1 - alpha)*x)) ./ (1 - (4*alpha*x).^2);
fprintf('Continuité : h(1e-6) = %.5f | h(T/(4a) + 1e-6) = %.5f\n', f(1e-6), f(1/(4*alpha) + 1e-6));

h = rrc_coef(alpha, L, span);
fprintf('Énergie après normalisation : sum(h^2) = %.6f\n', sum(h.^2));
if exist('rcosdesign', 'file') == 2
    href = rcosdesign(alpha, span, L, 'sqrt');
    fprintf('Écart max avec rcosdesign (Signal Processing Toolbox) : %.2e\n', ...
            max(abs(h - href/sqrt(sum(href.^2)))));
end

%% Q3 : h et h*h, critère de Nyquist
g  = conv(h, h);                              % cosinus surélevé (2N-1 points)
tg = (-(N-1) : (N-1)) / L;
k  = -span:span;                              % multiples de T
ik_h = (N+1)/2 + k(abs(k) <= span/2) * L;     % indices des kT dans h
ik_g = N + k * L;                             % indices des kT dans h*h

figure('Position', [100 100 1100 420]);
subplot(1, 2, 1);  hold on;  grid on;  box on;
plot(t, h, 'LineWidth', 1.4);
stem(t(ik_h), h(ik_h), 'filled');
xlabel('t / T');  ylabel('h(t)');
title(sprintf('Racine de cosinus surélevé, \\alpha = %.2f', alpha));
legend('h', 'échantillons en kT');
subplot(1, 2, 2);  hold on;  grid on;  box on;
plot(tg, g, 'LineWidth', 1.4);
stem(tg(ik_g), g(ik_g), 'filled');
xlabel('t / T');  ylabel('(h*h)(t)');
title('h * h = cosinus surélevé');
legend('h*h', 'échantillons en kT');

kz = ik_g(k ~= 0);
kh = ik_h(k(abs(k) <= span/2) ~= 0);
fprintf('\n=== Q3 : critère de Nyquist ===\n');
fprintf('(h*h)(0) = %.4f\n', g(N));
fprintf('max |h*h(kT)|, k ~= 0 : %.2e  (IES résiduelle, due à la troncature)\n', max(abs(g(kz))));
fprintf('max |h(kT)|,   k ~= 0 : %.2e  (h seul n''est pas de Nyquist)\n', max(abs(h(kh))));

% Effet de la troncature : IES résiduelle en fonction de span
fprintf('Troncature : span | IES max h*h\n');
for sp = [4 6 8 10 16 24]
    hs = rrc_coef(alpha, L, sp);  gs = conv(hs, hs);  Ns = sp*L + 1;
    ks = Ns + (-sp:sp) * L;  ks(sp + 1) = [];
    fprintf('             %3d | %.2e\n', sp, max(abs(gs(ks))));
end

%% Q4 : densités spectrales de puissance, porte vs RRC
rng(graine);
Nsym = 2e4;
s = (2*randi([0 1], Nsym, 1) - 1 + 1j*(2*randi([0 1], Nsym, 1) - 1)) / sqrt(2);
x0 = zeros(Nsym*L, 1);  x0(1:L:end) = s;      % symboles tous les L échantillons
h_porte = ones(1, L) / sqrt(L);
x_porte = filter(h_porte, 1, x0);
x_rrc   = filter(h, 1, x0);

nfft = 4096;
[S_p, fn] = pwelch(x_porte, hann(nfft), nfft/2, nfft, L, 'centered');   % f en 1/T
[S_r, ~ ] = pwelch(x_rrc,   hann(nfft), nfft/2, nfft, L, 'centered');

% Bande contenant 99 % de la puissance (bilatérale -> on donne la demi-bande)
bande = @(S) interp1(cumsum(S(fn >= 0)) / sum(S(fn >= 0)), fn(fn >= 0), 0.99);
B_p = bande(S_p);  B_r = bande(S_r);

figure; hold on; grid on; box on;
plot(fn, 10*log10(S_p / max(S_p)), 'LineWidth', 1.2, 'DisplayName', 'Porte');
plot(fn, 10*log10(S_r / max(S_r)), 'LineWidth', 1.2, ...
     'DisplayName', sprintf('RRC, \\alpha = %.2f', alpha));
xline((1 + alpha)/2, '--', '(1+\alpha)/2T', 'HandleVisibility', 'off');
xline(-(1 + alpha)/2, '--', 'HandleVisibility', 'off');
xline(1, ':', '1/T', 'HandleVisibility', 'off');
xlim([-3 3]);  ylim([-70 5]);
xlabel('f \times T');  ylabel('DSP normalisée (dB)');
title('Densité spectrale de puissance du signal émis');
legend('Location', 'south');

fprintf('\n=== Q4 : bande occupée (99 %% de la puissance, f > 0) ===\n');
fprintf('Porte : %.3f / T   (1er zéro du sinc^2 en 1/T)\n', B_p);
fprintf('RRC   : %.3f / T   (théorie (1+a)/(2T) = %.3f / T)\n', B_r, (1 + alpha)/2);
fprintf('-> bande réduite d''un facteur %.1f\n', B_p / B_r);
