-------------------------------------------------------------------------------
--
-- feu.vhd
--
-- v. 2.0 2024-06-25
--
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;

ENTITY feu IS
  GENERIC (
    -------------------------------------------------------------------------------
    -- NE PAS MODIFIER - A UTILISER POUR LA DUREE DU FEU JAUNE
    -- Nombre de cycles d'horloge total pour le feu jaune
    -- 250_000_000 correspond a une duree de 2 secondes pour une horloge de 125 MHz
    YELLOW_DURATION_CYCLES : INTEGER := 250_000_000
    -------------------------------------------------------------------------------
  );
  PORT (
    -- Horloge
    clk : IN STD_LOGIC;
    reset : IN STD_LOGIC;
    -- Boutons pour activer les feux
    -- Le bouton 0 (resp. 1) active (passe au vert) le feu 0 (resp. 1)
    -- Les boutons 0 et 1 sont utilisés comme reset quand pressés
    -- simultanément
    I_btns : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
    -- I_mode       : in  std_logic_vector(1 downto 0);
    O_feu0 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    O_feu1 : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
END feu;

ARCHITECTURE arch OF feu IS

  --------------------------------------------------------------------------
  -- NE PAS MODIFIER - UTILISER SEULEMENT POUR LE DEFI

  -- Nombre de cycles d'horloge avant que le blinking demarre
  -- Ici, le blinking démarrera après une seconde...
  CONSTANT BLINK_START_CYCLES : INTEGER := YELLOW_DURATION_CYCLES / 2;

  -- Nombre de cycles avant de "toggle" le clignotement (passer de ON a OFF, et inversement)
  -- Ici, on aura 1/4 de seconde ON, 1/4 de seconde OFF, et ainsi de suite jusqu'a la fin du feu jaune
  CONSTANT BLINK_TOGGLE_CYCLES : INTEGER := YELLOW_DURATION_CYCLES / 8;
  --------------------------------------------------------------------------

  -- Constantes pour les couleurs
  -- Ces déclarations sont là à titre d'exemple, vous pouvez ajouter /
  -- supprimer / modifier des constantes comme bon vous semble
  CONSTANT COL0 : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000"; --éteint
  CONSTANT COL1 : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010"; --vert
  CONSTANT COL2 : STD_LOGIC_VECTOR(2 DOWNTO 0) := "111"; --blanc
  CONSTANT COL3 : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100"; --rouge
  CONSTANT JAUNE : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110"; -- rouge+vert=jaune

  SIGNAL front_montant_btn0 : STD_LOGIC := '0';
  SIGNAL btn0_stabilise : STD_LOGIC;
  SIGNAL btn0_stabilise_precedent : STD_LOGIC := '0';

  SIGNAL front_montant_btn1 : STD_LOGIC := '0';
  SIGNAL btn1_stabilise : STD_LOGIC;
  SIGNAL btn1_stabilise_precedent : STD_LOGIC := '0';

  SIGNAL compteur_jaune : INTEGER RANGE 0 TO YELLOW_DURATION_CYCLES := 0; --temps feu jaune 

  -- Définition des états possibles
  -- À modifier pour implémenter votre feu de circulation. Vous pouvez
  -- ajouter / retirer autant d'états que vous le souhaitez
  TYPE etat_type IS (INIT, e_1, e_2, e_3, e_4, eteint_2, eteint_4);
  -- État du système
  SIGNAL etat : etat_type := INIT;

  -- Reset
  SIGNAL rst : STD_LOGIC := '0';

BEGIN
  -- rst est affecté au bouton 3 OU au signal reset du composant
  -- C'est à vous de modifier ce signal pour respecter l'énoncé
  rst <= (I_btns(1)AND I_btns(0)) OR reset;
  btn0_stabilise <= I_btns(0);
  btn1_stabilise <= I_btns(1);
  -------------------------------------------------------------------------------
  --Partie 1
  -------------------------------------------------------------------------------
  PROCESS (clk)
  BEGIN
    IF rising_edge(clk) THEN
      IF rst = '1' THEN
        btn0_stabilise_precedent <= '0';
        front_montant_btn0 <= '0';
        btn1_stabilise_precedent <= '0';
        front_montant_btn1 <= '0';
        btn0_stabilise_precedent <= btn0_stabilise; -- afin que la machine reste dans l'état INIT
        btn1_stabilise_precedent <= btn1_stabilise; -- afin que la machine reste dans l'état INIT
      ELSE
        front_montant_btn0 <= btn0_stabilise AND NOT btn0_stabilise_precedent;
        btn0_stabilise_precedent <= btn0_stabilise;

        front_montant_btn1 <= btn1_stabilise AND NOT btn1_stabilise_precedent;
        btn1_stabilise_precedent <= btn1_stabilise;
      END IF;
    END IF;
  END PROCESS;

  -- Ce process dépend de l'état courant et des entrées
  --
  -- Cette machine à états basique est là à titre d'exemple, vous
  -- devez la modifier pour compléter le laboratoire.
  -- état change sur front montant horloge

  -------------------------------------------------------------------------------
  --Machine à états, Partie 2
  -------------------------------------------------------------------------------
  PROCESS (clk, rst) IS
    VARIABLE cptCligno : INTEGER := 0;
  BEGIN
    -- Reset Asynchrone
    IF rst = '1' THEN
      etat <= INIT;
      compteur_jaune <= 0;

    ELSIF rising_edge(clk) THEN
      CASE etat IS

        WHEN INIT =>
          compteur_jaune <= 0;
          IF front_montant_btn0 = '1' THEN
            etat <= e_1;
          ELSIF front_montant_btn1 = '1' THEN
            etat <= e_3;
          END IF;

        WHEN e_1 =>
          IF front_montant_btn0 = '1' THEN
            etat <= e_2;
            compteur_jaune <= YELLOW_DURATION_CYCLES - 1; --jaune pendant YELLOW_DURATION_CYCLES ticks pile
          END IF;

        WHEN e_2 | eteint_2 =>
          IF compteur_jaune > 0 THEN
            compteur_jaune <= compteur_jaune - 1;
            IF compteur_jaune <= BLINK_START_CYCLES THEN
              cptCligno := cptCligno - 1;
              IF cptCligno <= 0 THEN
                IF etat = e_2 THEN
                  etat <= eteint_2;
                ELSE
                  etat <= e_2;
                END IF;
                cptCligno := BLINK_TOGGLE_CYCLES;
              END IF;
            END IF;
          ELSE
            etat <= e_3;
          END IF;

        WHEN e_3 =>
          IF front_montant_btn1 = '1' THEN
            etat <= e_4;
            compteur_jaune <= YELLOW_DURATION_CYCLES - 1;
          END IF;

        WHEN e_4 | eteint_4 =>
          IF compteur_jaune > 0 THEN
            compteur_jaune <= compteur_jaune - 1;
            IF compteur_jaune <= BLINK_START_CYCLES THEN
              cptCligno := cptCligno - 1;
              IF cptCligno <= 0 THEN
                IF etat = e_4 THEN
                  etat <= eteint_4;
                ELSE
                  etat <= e_4;
                END IF;
                cptCligno := BLINK_TOGGLE_CYCLES;
              END IF;
            END IF;
          ELSE
            etat <= e_1;
          END IF;
      END CASE;
    END IF;
  END PROCESS;

  -- Ce process dépend uniquement de l'état courant
  --
  -- Cette machine à états basique est là à titre d'exemple, vous
  -- devez la modifier pour compléter le laboratoire.

  -------------------------------------------------------------------------------
  --Machine à états pour les sorties
  -------------------------------------------------------------------------------
  PROCESS (etat) IS
  BEGIN
    CASE etat IS
      WHEN INIT =>
        O_feu0 <= COL0;
        O_feu1 <= COL0;
      WHEN e_1 =>
        O_feu0 <= COL1;
        O_feu1 <= COL3;
      WHEN e_2 =>
        O_feu0 <= JAUNE;
        O_feu1 <= COL3;
      WHEN e_3 =>
        O_feu0 <= COL3;
        O_feu1 <= COL1;
      WHEN e_4 =>
        O_feu0 <= COL3;
        O_feu1 <= JAUNE;
      WHEN eteint_2 =>
        O_feu0 <= COL0;
        O_feu1 <= COL3;
      WHEN eteint_4 =>
        O_feu0 <= COL3;
        O_feu1 <= COL0;
        -- Condition d'erreur : ne devrait jamais arriver puisqu'il n'y
        -- a pas d'autre état possible
      WHEN OTHERS =>
        O_feu0 <= "111";
        O_feu1 <= "111";
    END CASE;
  END PROCESS;
END arch;