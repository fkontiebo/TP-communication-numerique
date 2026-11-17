%% partie5_qpsk.m - Partie 5 : modulation QPSK (questions 1 à 5)
% Modèle : chaine_P5.slx.
% Symboles e^{j k pi/4}, k = 1, 3, 5, 7  ->  |s| = 1, Es = 1, Eb = Es/2 = 1/2.
% Bruit complexe : variance N0/2 par voie, un échantillon par symbole.
%
% Remarque sur trace_TEB : il lit Eb = A^2 Tb = 1 dans le workspace et injecte
% sigma2 = N0/(2 Te_bruit). Avec Te_bruit = Ts = 2 :
%   sigma2 = (1/10^(x/10)) / 4 = (0.5/10^(x/10)) / 2 = N0_vrai / 2   (Eb vrai = 1/2)
% -> c'est exactement la variance N0/2 par voie demandée.
clear; close all; clc;
Parametres
modele = 'chaine_P5';
load_system(modele);
Qf = @(x) 0.5*erfc(x/sqrt(2));
r  = 1/sqrt(2);

% Tables des deux mappings (index tx = 2 b1 + b2 ; quadrant rx = 2 (I<0) + (Q<0))
%            tab_I          tab_Q          tab_b1      tab_b2
MAP.gray = {[r r -r -r],   [r -r r -r],   [0 0 1 1],  [0 1 0 1]};
MAP.nat  = {[r -r -r r],   [r r -r -r],   [0 1 0 1],  [0 1 1 0]};
choisir = @(m) cellfun(@(nom, v) assignin('base', nom, v), ...
                       {'tab_I', 'tab_Q', 'tab_b1', 'tab_b2'}, m);

%% Q1 : mapping de Gray
choisir(MAP.gray);
fprintf('=== Q1 : mapping de Gray ===\n');
fprintf('b1 b2 | k | symbole\n');
for idx = 0:3
    s = tab_I(idx+1) + 1j*tab_Q(idx+1);
    fprintf(' %d  %d | %d | %+.3f %+.3fj\n', bitshift(idx, -1), bitand(idx, 1), ...
            round(mod(angle(s), 2*pi) / (pi/4)), real(s), imag(s));
end
fprintf('I = (1 - 2 b1)/sqrt(2), Q = (1 - 2 b2)/sqrt(2) : deux BPSK indépendantes\n');
fprintf('Es = |s|^2 = %.2f -> Eb = Es/2 = %.2f\n\n', abs(tab_I(1) + 1j*tab_Q(1))^2, 0.5);

%% Q2 : validation et retard D5 (bruit nul)
D5 = NaN;
for d = 0:10
    in = Simulink.SimulationInput(modele);
    in = in.setVariable('sigma2', 0);  in = in.setVariable('D5', d);
    in = in.setModelParameter('StopTime', num2str(2000*Tb));
    out = sim(in);
    e = out.get('err');  e = e(end, :);
    if e(2) <= 2, D5 = d; break; end
end
if isnan(D5), error('Aucun retard D5 ne donne 0 erreur : vérifier le modèle.'); end
fprintf('=== Q2 : validation sans bruit ===\n');
fprintf('D5 = %d : %d erreurs / %d bits -> reporter D5 = %d dans Parametres.m\n\n', ...
        D5, e(2), e(3), D5);
assignin('base', 'D5', D5);

%% Q3 : constellations reçues à Eb/N0 = 0, 5, 10 dB
EbN0_c = [0 5 10];
figure('Position', [100 100 1100 380]);
for i = 1:3
    N0v = 0.5 / 10^(EbN0_c(i)/10);           % Eb vrai = 1/2
    in = Simulink.SimulationInput(modele);
    in = in.setVariable('sigma2', N0v/2);  in = in.setVariable('nErrMax', inf);
    in = in.setModelParameter('StopTime', num2str(4000*Tb));
    out = sim(in);
    iq = squeeze(double(out.get('iq_rx')));
    if size(iq, 1) == 2, iq = iq.'; end
    subplot(1, 3, i);  hold on;  grid on;  box on;  axis equal;
    plot(iq(:, 1), iq(:, 2), '.', 'MarkerSize', 4);
    plot(tab_I, tab_Q, 'r+', 'MarkerSize', 14, 'LineWidth', 2);
    xline(0, 'k');  yline(0, 'k');
    xlim([-2.2 2.2]);  ylim([-2.2 2.2]);
    xlabel('I');  ylabel('Q');
    title(sprintf('E_b/N_0 = %d dB (\\sigma = %.2f)', EbN0_c(i), sqrt(N0v/2)));
end
sgtitle('Constellations QPSK reçues (2000 symboles)');

%% Q4 et Q5 : TEB, Gray puis naturel
choisir(MAP.gray);
res_g = trace_TEB(modele, EbN0_vec, Ts, 'Legende', 'QPSK Gray (simulé)', ...
                  'Theorie', @(x) Qf(sqrt(2*x)));
fig = gcf;

choisir(MAP.nat);
Pnat = @(x) (3*Qf(sqrt(2*x)) - 2*Qf(sqrt(2*x)).^2) / 2;
res_n = trace_TEB(modele, EbN0_vec, Ts, 'Figure', fig, ...
                  'Legende', 'QPSK naturel (simulé)', 'Theorie', Pnat);
lg = legend;
lg.String{2} = 'Gray (= BPSK) : Q(\surd(2E_b/N_0))';
lg.String{4} = 'Naturel : p(3 - 2p)/2';
ylim([1e-6 1]);
title('QPSK : mapping de Gray et mapping naturel');

x = linspace(0, 12, 4001);  xl = 10.^(x/10);
xg = interp1(log10(Qf(sqrt(2*xl))), x, -4);
xn = interp1(log10(Pnat(xl)), x, -4);
fprintf('\n=== Q5 ===\n');
fprintf('TEB = 1e-4 : Gray %.2f dB | naturel %.2f dB -> écart %.2f dB\n', xg, xn, xn - xg);
fprintf('Rapport des TEB à fort Eb/N0 : naturel / Gray -> 1.5\n');

choisir(MAP.gray);                           % on laisse Gray par défaut
