# Chaîne de transmission numérique en bande de base — Matlab/Simulink

TP de **Théorie de l'information et du codage** — ENSIM 5A ASTRE, 2026-2027
Auteur : **Bénéwindé KONTIEBO**

Modélisation et simulation, étape par étape, d'une chaîne de transmission numérique complète :
codage de source → codage de canal → modulation QPSK → mise en forme RRC → canal à deux trajets + AWGN → filtre adapté → (égaliseur) → décision → décodage.
À chaque étape, la chaîne est validée puis comparée à la précédente (TEB, débit, occupation spectrale) et aux bornes théoriques (Shannon).

📄 **Compte rendu : [`rapport/rapport_Benewinde_Kontiebo.pdf`](rapport/rapport_Benewinde_Kontiebo.pdf)** — source LaTeX dans [`rapport/latex/`](rapport/latex/) (compilation pdfLaTeX, par exemple sur Overleaf)

🎥 **Vidéo de présentation (≈ 30 min) : [regarder la vidéo](https://drive.google.com/file/d/1YZJHBDIkoWLP0zdbsSZrMybrxrPkuh2F/view?usp=drive_link)** — tout le TP expliqué : code, modèles Simulink, démonstrations en direct et résultats.

| Temps | Chapitre |
|:--:|---|
| 0:00 | Introduction : la chaîne complète |
| 1:41 | Organisation du code et méthode (paramètres, `trace_TEB`, recherche automatique des retards, reproductibilité) |
| 5:17 | Partie 2 – Codage de source : entropie, Huffman sur *Candide*, extension de source, compresseurs, LZ78 |
| 9:57 | Partie 3 – Chaîne de base : CBS, seuils optimaux, détecteur optimal (intégrateur) sous Simulink |
| 13:31 | Partie 4 – Code de Hamming (7,4) : matrices G/H, syndrome, codeur à registre, gain de codage |
| 18:08 | Partie 5 – Modulation QPSK : mapping de Gray, constellations, Hamming + QPSK |
| 20:24 | Partie 6 – Filtre en racine de cosinus surélevé : Nyquist, spectre, diagramme de l'œil, décalage T/4 |
| 24:15 | Partie 7 – Canal à deux trajets : perte de Nyquist, égaliseur ZF, transmission d'un texte |
| 27:51 | Conclusion et limites de Shannon |

Les démonstrations de la vidéo se rejouent avec `demo_video` (dans `matlab/`, après `init_tp`).

---

## Contenu du TP

| Partie | Thème | Ce qui est réalisé | Outils |
|:--:|---|---|---|
| 2 | Codage de source | Source binaire, entropie, Huffman (texte *Candide*), extension de source, compresseurs réels, LZ78 | Matlab |
| 3 | Chaîne de base | CBS, bruit uniforme, bruit gaussien, seuil optimal, détecteur optimal (intégrateur) | Matlab + Simulink |
| 4 | Codage de canal | Hamming C(7,4) cyclique : matrices G/H, syndrome, codeur à registre LFSR, décodeur, gain de codage | Matlab + Simulink |
| 5 | Modulation | QPSK Gray / naturel, constellations, chaîne Hamming + QPSK | Simulink |
| 6 | Mise en forme | Filtre porte et racine de cosinus surélevé, critère de Nyquist, DSP, diagramme de l'œil, décalage T/4 | Matlab + Simulink |
| 7 | Canal à deux trajets | Écho β·δ(t − τ), perte de Nyquist, œil, TEB, égaliseur ZF, transmission d'un texte (From/To Workspace) avec et sans Hamming | Matlab + Simulink |

## Organisation du dépôt

```
.
├── README.md
├── rapport/
│   ├── rapport_Benewinde_Kontiebo.pdf  # compte rendu compilé (10 pages + garde)
│   └── latex/
│       ├── rapport.tex         # source LaTeX du compte rendu (pdfLaTeX)
│       └── figures/            # les 17 figures utilisées dans le rapport
├── figures/                    # toutes les figures, régénérées par run_all.m
│   └── modeles/                # schémas des modèles Simulink
├── resultats/                  # sorties console de chaque script (valeurs numériques)
└── matlab/
    ├── init_tp.m               # se place dans matlab/ + chemins + paramètres
    ├── chemins_tp.m            # ajoute les sous-dossiers au chemin Matlab
    ├── run_all.m               # rejoue tout le TP, exporte figures et résultats
    ├── demo_video.m            # démonstrations courtes de la vidéo (une étape par partie)
    ├── Parametres.m            # paramètres communs (Tb, A, L, Eb/N0, retards...)
    ├── parametres_perso.m      # tirage des paramètres personnels
    ├── mes_parametres.mat      # paramètres personnels figés (reproductibilité)
    ├── commun/                 # source.m, entropie_binaire.m, trace_TEB.m
    ├── partie2_codage_source/  # Huffman, LZ78, entropie, textes
    ├── partie3_chaine_base/    # canaux CBS / uniforme / gaussien, chaine_P3.slx
    ├── partie4_codage_canal/   # Hamming (7,4), codeur/décodeur Simulink, chaine_P4.slx
    ├── partie5_modulation_qpsk/# chaine_P5.slx (QPSK), chaine_P5c.slx (Hamming + QPSK)
    ├── partie6_mise_en_forme/  # rrc_coef.m, chaine_P6.slx (porte / RRC)
    └── partie7_canal/          # chaine_P7.slx (écho + égaliseur ZF + source texte)
```

## Reproduire les résultats

**Prérequis** : MATLAB/Simulink **R2024b ou plus récent** (les modèles `.slx` sont enregistrés en R2024b), avec les toolboxes
*Communications Toolbox* (bloc *Error Rate Calculation*), *DSP System Toolbox* (blocs *Buffer / Unbuffer*) et *Signal Processing Toolbox* (`pwelch`, `rcosdesign`).
Optionnel : [7-Zip](https://www.7-zip.org/) installé dans `C:\Program Files\7-Zip` pour les colonnes bzip2 / 7z de la partie 2.4 (sinon elles valent `NaN`, le reste est inchangé).

```bash
git clone https://github.com/fkontiebo/TP-communication-numerique.git
```

```matlab
cd TP-communication-numerique/matlab
run_all            % rejoue tout le TP (≈ 8 min) : régénère figures/ et resultats/
```

Les résultats sont **identiques bit à bit** à ceux du dépôt et du rapport :

- les paramètres personnels sont figés dans `matlab/mes_parametres.mat` (versionné) ;
- tous les tirages aléatoires sont initialisés par une graine fixe (`rng(graine)` en Matlab, paramètre *Seed* des blocs Simulink) ;
- les retards et alignements des chaînes sont recalculés automatiquement à chaque exécution.

Après `run_all`, `git status` ne montre aucune différence sur `resultats/`, sauf les lignes d'horodatage et de durée.

**Lancer une partie seule** (dans n'importe quel ordre, chaque script est autonome) :

```matlab
cd matlab
init_tp                    % chemins + paramètres personnels
partie4_chaine             % un script...
open_system('chaine_P4')   % ...ou un modèle : il s'exécute directement (bouton Run)
```

| Script | Contenu | Modèle Simulink |
|---|---|---|
| `partie2_1` … `partie2_5` | source binaire, Huffman, extension, compresseurs, LZ78 | — |
| `partie3_canaux`, `test_P3` | CBS, bruit uniforme / gaussien, seuils, chaîne de référence Matlab | — |
| `partie3_simulink` | détecteur optimal, TEB avec / sans intégrateur | `chaine_P3` |
| `partie4_hamming` | matrices G/H, syndrome, registre (théorie) | — |
| `partie4_codeur_simulink`, `partie4_decodeur_simulink` | validation du codeur / décodeur à registre | `codeur_hamming`, `decodeur_hamming` |
| `partie4_chaine` | TEB avec / sans codage, limites de Shannon | `chaine_P3`, `chaine_P4` |
| `partie5_qpsk`, `partie5_q6` | QPSK Gray / naturel, Hamming + QPSK | `chaine_P5`, `chaine_P5c` |
| `partie6_filtres`, `partie6_chaine` | RRC, Nyquist, DSP, œil, décalage T/4 | `chaine_P6` |
| `partie7_canal` | canal à deux trajets, égaliseur ZF, transmission d'un texte | `chaine_P7` |

## Conventions

- Durée d'un bit **T<sub>b</sub> = 1**, niveaux antipodaux ±A, **E<sub>b</sub> = A²T<sub>b</sub>**.
- Bruit blanc gaussien de DSP N<sub>0</sub>/2 ; avec L échantillons par bit : σ² = N<sub>0</sub>/(2T<sub>e</sub>) = N<sub>0</sub>L/(2T<sub>b</sub>).
- Solveur Simulink à pas fixe discret, pas T<sub>e</sub> = T<sub>b</sub>/L ; changements de rythme par *Buffer / Unbuffer / Rate Transition*.
- TEB mesuré jusqu'à 100 erreurs ou 10⁶ bits, avec intervalle de confiance à 95 % ; graines fixées (`rng(graine)`, paramètre *Seed*).
- Paramètres personnels tirés une fois puis figés dans `mes_parametres.mat` (supprimer ce fichier pour en tirer de nouveaux).

## Déclaration d'usage de l'IA

Un assistant d'IA générative (Claude, Anthropic) a été utilisé comme outil d'appui pour ce TP, dans trois cas précis :

- **Rédaction du rapport** : reformulation et amélioration de la clarté de passages du compte rendu dont le contenu (démarche, résultats, analyses) est le mien ;
- **Débogage** : aide à l'identification et à la correction d'erreurs dans le code Matlab et les modèles Simulink ;
- **Vidéo** : aide à l'écriture du script de la vidéo de présentation.

**Tout ce qui est issu de l'IA a été relu, vérifié et compris avant d'être adopté** : chaque correction de code a été testée par simulation, chaque résultat numérique provient de l'exécution des scripts du dépôt (et se reproduit avec `run_all`), et chaque reformulation a été contrôlée pour qu'elle reste fidèle au travail réalisé. La conception de la chaîne, les choix techniques, les simulations et l'interprétation des résultats relèvent de mon propre travail.
