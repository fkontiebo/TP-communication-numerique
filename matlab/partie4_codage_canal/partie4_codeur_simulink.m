%% partie4_codeur_simulink.m - Q5 : validation du codeur à registre (codeur_hamming.slx)
% Le codeur série reçoit, à chaque trame de 7 coups d'horloge :
%   entrée : m3 m2 m1 m0 0 0 0          (poids fort d'abord, puis 3 cases vides)
%   sortie : m3 m2 m1 m0 r2 r1 r0       (message puis redondance, chacun poids fort d'abord)
clear; close all; clc;
Parametres
% G = [I4 | P] est défini dans Parametres.m (identique à partie4_hamming.m)
modele = 'codeur_hamming';
Tc_reg = 1;                               % horloge du registre (modèle autonome)

%% Séquence d'entrée : les 16 messages, dans l'ordre 0..15
msgs   = dec2bin(0:15, 4) - '0';          % une ligne = [m0 m1 m2 m3]
trames = [fliplr(msgs) zeros(16, 3)];     % [m3 m2 m1 m0 0 0 0]
seq_in = reshape(trames.', 1, []);        % 112 valeurs, lues par Repeating Sequence Stair

% Sortie attendue : mot-code matriciel retourné
mots     = hamming_enc(msgs, G);          % [m0 m1 m2 m3 r0 r1 r2]
attendu  = [fliplr(mots(:, 1:4)) fliplr(mots(:, 5:7))];   % [m3 m2 m1 m0 r2 r1 r0]
attendu  = reshape(attendu.', [], 1);

%% Simulation
in  = Simulink.SimulationInput(modele);
in  = in.setVariable('seq_in', seq_in);
in  = in.setVariable('Tc_reg', Tc_reg);
in  = in.setModelParameter('StopTime', num2str((numel(seq_in) - 1) * Tc_reg));
out = sim(in);
c_sl  = double(out.get('c_sl'));    c_sl = c_sl(:);
etat  = double(out.get('etat_sl')); etat = reshape(etat, [], 3);

%% Comparaison
fprintf('=== Q5 : codeur à registre (Simulink) vs codeur matriciel ===\n');
fprintf('Échantillons comparés : %d / attendus : %d\n', numel(c_sl), numel(attendu));
nb = min(numel(c_sl), numel(attendu));
ok = c_sl(1:nb) == attendu(1:nb);
fprintf('16 mots-codes identiques : %d\n', all(ok) && nb == numel(attendu));
if ~all(ok)
    faux = unique(ceil(find(~ok) / 7));
    fprintf('Messages en erreur (indices 0..15) : %s\n', mat2str(faux.' - 1));
end

%% Table des états pour m = [1 0 1 1] (message n° 13 = 1 + 4 + 8)
i13 = find(ismember(msgs, [1 0 1 1], 'rows'));
t0  = (i13 - 1) * 7;                      % début de la trame
fprintf('\nTable des états, m = [m0 m1 m2 m3] = [1 0 1 1]\n');
fprintf('Coup | entrée | s0 s1 s2 (après le coup) | sortie\n');
for t = 1:7
    e = seq_in(t0 + t);
    s = etat(t0 + t + 1, :);              % état visible au coup suivant
    fprintf('  %d  |   %d    |        %d  %d  %d          |   %d\n', t, e, s, c_sl(t0 + t));
end
