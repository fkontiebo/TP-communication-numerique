%% partie4_decodeur_simulink.m - Q6 : validation du décodeur (decodeur_hamming.slx)
% 16 messages x 8 cas (sans erreur + erreur simple à chacune des 7 positions)
% + un test à deux erreurs. Format série : m3 m2 m1 m0 r2 r1 r0.
clear; close all; clc;
Parametres
% G et H sont définis dans Parametres.m (identiques à partie4_hamming.m)
modele = 'decodeur_hamming';
Tc_reg = 1;

msgs = dec2bin(0:15, 4) - '0';                       % [m0 m1 m2 m3]
mots = hamming_enc(msgs, G);                         % [m0 m1 m2 m3 r0 r1 r2]
serie = @(c) [fliplr(c(:, 1:4)) fliplr(c(:, 5:7))];  % ordre de transmission
noms_pos = {'m0','m1','m2','m3','r0','r1','r2'};     % position dans c

%% Construction des trames : cas 0 = sans erreur, cas j = erreur sur c_j
nCas = 8;
trames = zeros(16*nCas, 7);  ref = zeros(16*nCas, 4);  cas = zeros(16*nCas, 1);
for j = 0:7
    e = zeros(1, 7);  if j > 0, e(j) = 1; end
    idx = j*16 + (1:16);
    trames(idx, :) = serie(mod(mots + e, 2));
    ref(idx, :) = msgs;  cas(idx) = j;
end
% Test à deux erreurs (m0 et m1) : 16 trames de plus
e2 = [1 1 0 0 0 0 0];
trames = [trames; serie(mod(mots + e2, 2))];
ref = [ref; msgs];  cas = [cas; 99*ones(16, 1)];

seq_rx = reshape(trames.', 1, []);

%% Simulation
in  = Simulink.SimulationInput(modele);
in  = in.setVariable('seq_rx', seq_rx);
in  = in.setVariable('Tc_reg', Tc_reg);
in  = in.setModelParameter('StopTime', num2str((numel(seq_rx) - 1) * Tc_reg));
out = sim(in);
ph  = double(out.get('phase'));  ph = ph(:);
md  = double(out.get('m_dec'));  md = reshape(md, [], 4);
S   = double(out.get('S_sl'));   S = S(:);

% Décisions valides au 7e coup de chaque trame (phase = 6)
fin = find(ph == 6);
md  = md(fin, :);  S = S(fin);
fprintf('Trames décodées : %d / %d\n\n', size(md, 1), size(trames, 1));

%% Résultats
fprintf('=== Q6 : décodeur par syndrome (Simulink) ===\n');
fprintf('Cas               | syndrome S | 16 messages corrects\n');
for j = 0:7
    k = cas == j;
    if j == 0, lib = 'sans erreur'; else, lib = ['erreur sur ' noms_pos{j}]; end
    fprintf('%-17s |     %d      | %d\n', lib, mode(S(k)), isequal(md(k, :), ref(k, :)));
end
k = cas == 99;
fprintf('%-17s |     %d      | %d (%d/16 messages faux)\n', 'deux erreurs m0,m1', ...
        mode(S(k)), isequal(md(k, :), ref(k, :)), sum(any(md(k, :) ~= ref(k, :), 2)));

% Comparaison avec le décodeur matriciel de référence
r_ref = zeros(size(trames));
r_ref(:, [4 3 2 1 7 6 5]) = trames;                  % retour à l'ordre [m0..m3 r0 r1 r2]
fprintf('\nIdentique au décodeur matriciel (144 trames) : %d\n', ...
        isequal(md, hamming_dec(r_ref, H)));
