-------------------------------------------------------------------------------
--
-- code_barre.vhd
--
-- v. 2.0 2024-06-18
--
--------------------------
-----------------------------------------------------

LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE work.utilitaires_inf3500_pkg.ALL;

ENTITY code_barre IS
  GENERIC (
    N : POSITIVE := 32 -- largeur du code
  );
  PORT (
    i_detecteur : IN STD_LOGIC_VECTOR(N - 1 DOWNTO 0);
    o_rgb : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    o_erreur_encre_vide : OUT STD_LOGIC;
    o_erreur_impression : OUT STD_LOGIC;
    o_impression_valide : OUT STD_LOGIC;

    o_erreur_secteur : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    o_erreur_position : OUT STD_LOGIC_VECTOR(clog2(N) - 1 DOWNTO 0)
  );
END;

ARCHITECTURE arch OF code_barre IS

BEGIN

  PROCESS (i_detecteur)
    VARIABLE precendent_noir : BOOLEAN := false;
    VARIABLE contient_noir : BOOLEAN := false;
    VARIABLE impression_valide : BOOLEAN := true;
    VARIABLE v : STD_LOGIC;

    VARIABLE erreur_trouvee : BOOLEAN;
    VARIABLE position_erreur : INTEGER range 0 to N-1;
    CONSTANT taille_secteur : INTEGER := N/4;
    VARIABLE quel_secteur : INTEGER range 0 to 3;

  BEGIN

    ASSERT N MOD 4 = 0 REPORT "Cette architecture ne fonctionne que pour N muliple de 4." SEVERITY error;
    --Afin de remédier aux signaux undefined lorsque les signaux sont supposés valoir0, leur accorde une valeur par défaut
    o_rgb <= "000000";              
    o_erreur_secteur  <= "0000";   
    o_erreur_position <= (others => '0');   

    -- Reset les valeurs
    precendent_noir := false;
    contient_noir := false;
    impression_valide := true;

    erreur_trouvee := false;
    position_erreur     := 0;
    
    -- Parcours du détecteur bit par bit lsb à msb
    FOR k IN 0 TO N-1 LOOP
      v := i_detecteur(k); -- Bit courant
      IF v THEN -- si bit noir
        contient_noir := true;

        IF precendent_noir THEN
          impression_valide := false; -- Deux noirs consécutifs
          IF NOT erreur_trouvee THEN 
            erreur_trouvee := true;
            position_erreur := k-1;
          END IF;
        END IF;

        precendent_noir := true;
        contient_noir := true;
      ELSE -- Bit blanc
        precendent_noir := false;
      END IF;
    END LOOP;

    -- Valeurs par défaut
    o_erreur_encre_vide <= '0';
    o_erreur_impression <= '0';
    o_impression_valide <= '0';

    IF NOT contient_noir THEN
      o_erreur_encre_vide <= '1'; -- Encre vide
      o_rgb(2 DOWNTO 0) <= "001"; -- Bleu
    ELSIF NOT impression_valide THEN
      o_erreur_impression <= '1'; -- Erreur impression
      o_rgb(2 DOWNTO 0) <= "100"; -- Rouge

      -- Partie 4 
      o_erreur_position <= std_logic_vector(to_unsigned(position_erreur, clog2(N)));

      quel_secteur := position_erreur / taille_secteur;  -- calcul du secteur, va servir "d'index" 
      o_erreur_secteur <= "0000"; --on met tous les secteurs a 0, afin d'en allumer un seul 
      o_erreur_secteur(quel_secteur) <= '1';

    ELSE
      o_impression_valide <= '1'; -- Impression valide
      o_rgb(2 DOWNTO 0) <= "010"; -- Vert
    END IF;
    --  code � modifier pour le bonus de la partie 4a.
    --  o_erreur_secteur  <= "0001";
    --  o_erreur_position <= std_logic_vector(to_unsigned(3, clog2(N)));

  END PROCESS;
END;