%% Parametres.m - Paramètres communs du TP "chaîne de transmission numérique"
% À exécuter avant chaque simulation. Toutes les variables sont créées dans
% le workspace de base, où les modèles Simulink vont les chercher.
% Convention (§1.1) : Tb = 1, bits antipodaux ±A, Eb = A^2*Tb,
% bruit blanc gaussien de DSP bilatérale N0/2  ->  sigma2 = N0/(2*Te).

%% Chemins : tous les dossiers du projet (fonctions, scripts, modèles)
% Ainsi, n'importe quel script ou modèle fonctionne après « Parametres »,
% quel que soit l'ordre dans lequel on les lance.
racine_tp = chemins_tp();

%% Identification
nom = 'KONTIEBO Bénéwindé';               % <-- EXACTEMENT comme sur la liste d'appel
% parametres_perso tire des valeurs au hasard (c = rand(1), consigne de
% l'enseignant) : on les tire UNE SEULE FOIS puis on les fige dans un .mat
% versionné avec le code, pour que tous les résultats soient reproductibles.
% Pour retirer de nouvelles valeurs : supprimer mes_parametres.mat.
fichier_P = fullfile(racine_tp, 'mes_parametres.mat');   % chemin absolu
if exist(fichier_P, 'file') == 2
    load(fichier_P, 'P');
else
    P = parametres_perso(nom);
    P.graine = round(P.graine);   % rng() exige une graine entière
    save(fichier_P, 'P');
    fprintf('Nouveaux paramètres tirés et sauvegardés dans %s\n', fichier_P);
end

%% Temps, amplitude, énergie
Tb = 1;                 % durée d'un bit d'information (unité de référence)
A  = P.A;               % niveaux antipodaux ±A
Eb = A^2 * Tb;          % énergie par bit d'information
L  = P.L;               % échantillons par bit (ou par symbole)
Te = Tb / L;            % pas fondamental du solveur (Fixed-step, discrete)

%% Source (parties 2 et 3)
p1     = P.p1;          % P(bit = 1)
p0     = 1 - p1;
p1_ext = P.p1_ext;      % source très déséquilibrée (extension, partie 2.3)
graine       = P.graine;      % graine de la source
graine_bruit = P.graine + 1;  % graine du bruit : DOIT différer de la source

%% Canaux de la partie 3
pe_cbs = P.pe_cbs;      % probabilité d'erreur du canal binaire symétrique
a_unif = P.a_unif;      % bruit uniforme sur [-a, a]
sigma  = P.sigma;       % écart-type du bruit gaussien (1 échantillon/bit)
s_opt_gauss = sigma^2 / (2*A) * log(p0/p1);   % seuil optimal (Q7)
seuil  = 0;             % seuil courant du comparateur (modifié par script)

%% Rapport Eb/N0 courant (écrasé par trace_TEB à chaque point)
EbN0_dB = 5;
N0      = Eb / 10^(EbN0_dB/10);
sigma2  = N0 / (2*Te);  % variance par échantillon (réel, ou par voie I/Q)
 
%% Récepteur de la chaîne de base (partie 3, modèle chaine_P3.slx)
h_rx = ones(1, L) / L;  % FIR = intégrateur remis à zéro (moyenne sur 1 bit)
D    = 2;               % retard (en bits) de la voie de référence
                        % -> valeur trouvée par partie3_simulink (étape 1)


%% Codage de canal Hamming C(7,4) (partie 4)
n  = 7;  k = 4;  R = k/n;
Tc   = R * Tb;          % durée d'un bit codé : rythme 7/(4Tb)
Ac   = A * sqrt(R);     % amplitude d'un bit codé (Eb conservée)
Te_c = Tc / L;          % pas d'échantillonnage côté bits codés
g_poly = [1 1 0 1];     % g(x) = 1 + x + x^3 (coefficients croissants)
G = [eye(4) [1 1 0; 0 1 1; 1 1 1; 1 0 1]];   % G = [I4 | P] (partie 4, Q1)
H = [G(:, 5:7).' eye(3)];                     % H = [P' | I3]
K7 = 5;
D4 = 12;                 % retard de la chaîne codée -> trouvé par partie4_chaine

%% Modulation QPSK (partie 5), symboles e^{j k pi/4}, |s| = 1
Ts   = 2 * Tb;          % chaîne non codée : 2 bits d'info par symbole
Ts_c = 2 * Tc;          % chaîne codée : 2 bits codés par symbole
Es   = 2 * Eb;          % énergie par symbole (non codée)
tab_I  = [1 1 -1 -1] / sqrt(2);   tab_Q  = [1 -1 1 -1] / sqrt(2);
tab_b1 = [0 0 1 1];               tab_b2 = [0 1 0 1];
D5 = 2;                 % retard de chaine_P5 -> trouvé par partie5_qpsk
K7c = 5;  D6 = 12;       % alignement et retard de chaine_P5c -> trouvés par partie5_q6

%% Mise en forme RRC (partie 6)
alpha    = P.alpha;     % roll-off
span     = 10;          % troncature en symboles
N_rrc    = span*L + 1;  % nombre de coefficients
retard_rrc = span;      % retard émission + réception, en symboles
Te_s   = Ts / L;        % pas d'échantillonnage de la chaîne filtrée (chaine_P6)
h6     = rrc_coef(alpha, L, span);   % filtre de mise en forme (porte : ones(1,L)/sqrt(L))
decal6 = 0;             % alignement en échantillons (porte : 1 ; question 6 : + L/4)
D7     = 0;             % retard des bits de chaine_P6 -> trouvé par partie6_chaine

%% Canal à 2 trajets (partie 7) : hc(t) = delta(t) + beta*delta(t - tau)
beta = P.beta;
tau  = P.retard_trajet; % en durées symbole

%% Pilotage des simulations
EbN0_vec = 0:9;         % plage des courbes de TEB (dB)
nErrMax  = 100;         % arrêt après 100 erreurs (TEB fiable)
nBitsMax = 1e6;         % ou après 1e6 bits (TEB mesurable ~1e-4)
retard_rx = 0;          % "Receive delay" de l'Error Rate Calculation
Q = @(x) 0.5*erfc(x/sqrt(2));

%% Récapitulatif
fprintf('--- Paramètres de %s ---\n', P.nom);
fprintf('p1 = %.2f | p1_ext = %.2f | pe = %.3f | a = %.2f | sigma = %.2f\n', ...
        p1, p1_ext, pe_cbs, a_unif, sigma);
fprintf('L = %d | alpha = %.2f | beta = %.2f | tau = %d T | graine = %d\n', ...
        L, alpha, beta, tau, graine);
fprintf('Seuil optimal gaussien s* = %.4f\n', s_opt_gauss);