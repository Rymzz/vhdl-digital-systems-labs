-------------------------------------------------------------------------------
--
-- code_barre_tb.vhd
--
-- v. 1.0 2024-02-03
--
-------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.numeric_std.ALL;
USE IEEE.math_real.ALL;
USE std.env.finish;
USE work.utilitaires_inf3500_pkg.ALL;
USE work.code_barre;

ENTITY code_barre_tb IS
  GENERIC (
    N_tb : POSITIVE := 8
  );
END ENTITY;

ARCHITECTURE arch OF code_barre_tb IS
  SIGNAL detecteur_tb : STD_LOGIC_VECTOR(N_tb - 1 DOWNTO 0);
  SIGNAL erreur_encre_vide_tb : STD_LOGIC;
  SIGNAL erreur_impression_tb : STD_LOGIC;
  SIGNAL impression_valide_tb : STD_LOGIC;
  SIGNAL rgb_tb : STD_LOGIC_VECTOR(5 DOWNTO 0);

  SIGNAL erreur_secteur_tb : STD_LOGIC_VECTOR(3 DOWNTO 0);
  SIGNAL erreur_position_tb : STD_LOGIC_VECTOR(clog2(N_tb) - 1 DOWNTO 0);

BEGIN

  -- instanciation du module à vérifier UUT (Unit Under Test)
  UUT : ENTITY code_barre(arch)
    GENERIC MAP(N => N_tb)
    PORT MAP
    (
      i_detecteur => detecteur_tb,
      o_rgb => rgb_tb,
      o_erreur_encre_vide => erreur_encre_vide_tb,
      o_erreur_impression => erreur_impression_tb,
      o_impression_valide => impression_valide_tb,

      o_erreur_secteur => erreur_secteur_tb,
      o_erreur_position => erreur_position_tb
    );
  -- application exhaustive des vecteurs de test, affichage et vérification
  PROCESS
    VARIABLE detecteur_int : unsigned(N_tb - 1 DOWNTO 0);
    VARIABLE deux_noirs_consecutifs : BOOLEAN;
    VARIABLE au_moins_un_noir : BOOLEAN;
    VARIABLE impression_valide_attendue : BOOLEAN;
    VARIABLE erreur_encre_vide_attendue : STD_LOGIC;
    VARIABLE erreur_impression_attendue : STD_LOGIC;
    VARIABLE rgb_attendu : STD_LOGIC_VECTOR(2 DOWNTO 0);
    VARIABLE expected_valide : STD_LOGIC;

    VARIABLE premiere_erreur_trouvee : BOOLEAN;
    VARIABLE position_premiere_erreur : INTEGER range 0 to N_tb-1;
    VARIABLE position_premiere_erreur_attendue_vec : STD_LOGIC_VECTOR(clog2(N_tb)-1 downto 0);
    VARIABLE secteur_attendu : STD_LOGIC_VECTOR(3 downto 0);
    CONSTANT taille_secteur_tb : INTEGER := N_tb/4;
    VARIABLE secteur_idx : INTEGER range 0 to 3;


  BEGIN

    FOR k IN 0 TO 2 ** N_tb - 1 LOOP

      detecteur_tb <= STD_LOGIC_VECTOR(to_unsigned(k, N_tb)); 

      WAIT FOR 10 ns; -- nécessaire pour que les signaux se propagent dans l'UUT
      detecteur_int := unsigned(detecteur_tb);

      -- au moins un noir?
      au_moins_un_noir := detecteur_int /= 0; -- différent de 0

      -- deux noirs consécutifs?
      deux_noirs_consecutifs := (detecteur_int AND (detecteur_int SRL 1)) /= 0; -- différent de 0 avec un shift right

      premiere_erreur_trouvee := false;
      position_premiere_erreur := 0;

      FOR i IN 0 TO N_tb-2 LOOP
        IF (detecteur_tb(i) = '1') AND (detecteur_tb(i+1) = '1') THEN
          premiere_erreur_trouvee := true;
          position_premiere_erreur := i; -- début de la paire "11"
          EXIT;
        END IF;
      END LOOP;

      -- Valeurs attendues secteur/position (partie 4)
      secteur_attendu := (others => '0');
      position_premiere_erreur_attendue_vec := (others => '0');

      IF deux_noirs_consecutifs THEN
        position_premiere_erreur_attendue_vec :=
          std_logic_vector(to_unsigned(position_premiere_erreur, clog2(N_tb)));

        secteur_idx := position_premiere_erreur / taille_secteur_tb; -- 0..3
        secteur_attendu(secteur_idx) := '1';
      END IF;

      -- Calcul des valeurs attendues
      IF NOT au_moins_un_noir THEN
        erreur_encre_vide_attendue := '1';
        erreur_impression_attendue := '0';
        impression_valide_attendue := false;
        rgb_attendu := "001"; -- Bleu
      ELSIF deux_noirs_consecutifs THEN
        erreur_encre_vide_attendue := '0';
        erreur_impression_attendue := '1';
        impression_valide_attendue := false;
        rgb_attendu := "100"; -- Rouge
      ELSE
        erreur_encre_vide_attendue := '0';
        erreur_impression_attendue := '0';
        impression_valide_attendue := true;
        rgb_attendu := "010"; -- Vert
      END IF;

      -- Vérification impression_valide
      expected_valide := '1' WHEN impression_valide_attendue ELSE
        '0';
      ASSERT impression_valide_tb = expected_valide
      REPORT "Erreur impression_valide pour detecteur = " & INTEGER'image(k)
        SEVERITY error;

      -- Vérification erreur_encre_vide   
      ASSERT erreur_encre_vide_tb = erreur_encre_vide_attendue
      REPORT "Erreur erreur_encre_vide pour detecteur = "
        & INTEGER'image(k)
        SEVERITY error;

      -- Vérification erreur_impression
      ASSERT erreur_impression_tb = erreur_impression_attendue
      REPORT "Erreur erreur_impression pour detecteur = "
        & INTEGER'image(k)
        SEVERITY error;

      -- Vérification RGB
      ASSERT rgb_tb(2 DOWNTO 0) = rgb_attendu
      REPORT "Erreur RGB pour detecteur = "
        & INTEGER'image(k)
        SEVERITY error;

      -- Vérification o_erreur_position
      ASSERT erreur_secteur_tb = secteur_attendu
      REPORT "Erreur erreur_secteur pour detecteur = " & INTEGER'image(k)
      SEVERITY error;

      -- Vérification o_erreur_position, verifie uniquement si erreur impression
      IF deux_noirs_consecutifs THEN
        ASSERT erreur_position_tb = position_premiere_erreur_attendue_vec
        REPORT "Erreur erreur_position pour detecteur = " & INTEGER'image(k)
        SEVERITY error;
      END IF;

    END LOOP;

    finish;

  END PROCESS;
END arch;