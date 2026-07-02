-------------------------------------------------------------------------------
--
-- feu_tb.vhd
--
-- Ce banc de test montre comment simuler une séquence d'entrées sur votre
-- module. Ici, il se contente de simuler quatre appuis sur le bouton 0 ; c'est
-- à vous de le modifier pour tester le comportement de votre module.
--
-- v. 1.0 2024-06-25
--
-------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE WORK.ALL;

ENTITY test_bench IS
END test_bench;

ARCHITECTURE arch_tb OF test_bench IS
  SIGNAL feu0, feu1 : STD_LOGIC_VECTOR(2 DOWNTO 0);
  SIGNAL btns : STD_LOGIC_VECTOR(3 DOWNTO 0) := "0000";
  SIGNAL clk, reset : STD_LOGIC := '0';
  CONSTANT clk_periode : TIME := 8 ns;
  CONSTANT OFF : STD_LOGIC_VECTOR(2 DOWNTO 0) := "000";
  CONSTANT GREEN : STD_LOGIC_VECTOR(2 DOWNTO 0) := "010";
  CONSTANT RED : STD_LOGIC_VECTOR(2 DOWNTO 0) := "100";
  CONSTANT YELLOW : STD_LOGIC_VECTOR(2 DOWNTO 0) := "110";
BEGIN

  -- Création d'une clock artificielle
  clk <= NOT clk AFTER clk_periode / 2;
  -- Reset pendant les deux premières période (power-on reset)
  reset <= '1' AFTER 0 ns, '0' AFTER 2 * clk_periode;

  -- Unit Under Test
  UUT : ENTITY feu(arch)
    GENERIC MAP(
      -------------------------------------------------------------------------------
      -- NE PAS MODIFIER - DUREE DU FEU JAUNE EN SIMULATION
      -- Permet de voir facilement le feu jaune sur le chronogramme
      -- avec une duree de 8 cycles plutot que 250_000_000...
      YELLOW_DURATION_CYCLES => 8
      -------------------------------------------------------------------------------
    )
    PORT MAP(
      clk => clk,
      reset => reset,
      I_btns => btns,
      O_feu0 => feu0,
      O_feu1 => feu1
    );

  -- Ce process est une ébauche de test-bench, vous pouvez le modifier pour
  -- l'adapter à votre design
  -- Note : Lors des tests, pas la peine de debouncer les boutons, puisque vous
  -- stimulez les inputs avec un test-bench VHDL qui est capable de générer une
  -- impulsion qui dure moins d'une période d'horloge
  PROCESS (clk)
    VARIABLE indice : NATURAL := 0;
  BEGIN
    IF falling_edge(clk) THEN
      CASE indice IS

          -- reset actif
        WHEN 0 | 1 => btns <= "0000";

          -- INIT, feux éteints
        WHEN 2 => btns <= "0000";
          ASSERT (feu0 = OFF AND feu1 = OFF) REPORT "Erreur INIT" SEVERITY failure;

          -- btn0, 2 cycles pour front montant
        WHEN 3 => btns <= "0001";
        WHEN 4 => btns <= "0000";

          -- e_1, feu0 vert, feu1 rouge
        WHEN 5 | 6 => btns <= "0000";
          ASSERT (feu0 = GREEN AND feu1 = RED) REPORT "Erreur e_1" SEVERITY failure;

          -- btn0, passage au jaune
        WHEN 7 => btns <= "0001";
        WHEN 8 => btns <= "0000";

          -- e_2, feu0 jaune
        WHEN 9 => btns <= "0000";
          ASSERT (feu0 = YELLOW AND feu1 = RED) REPORT "Erreur e_2" SEVERITY failure;

          -- e_2, countdown jaune
        WHEN 10 | 11 | 12 =>
          btns <= "0000";
          ASSERT (feu0 = YELLOW AND feu1 = RED)
          REPORT "Erreur e_2 jaune cycle " & INTEGER'image(indice - 8) SEVERITY failure;

          -- e_2 clignotant
        WHEN 13 | 15 =>
          btns <= "0000";
          ASSERT (feu0 = OFF AND feu1 = RED)
          REPORT "Erreur e_2 clignotant " & INTEGER'image(indice - 8) SEVERITY failure;

        WHEN 14 | 16 =>
          btns <= "0000";
          ASSERT (feu0 = YELLOW AND feu1 = RED)
          REPORT "Erreur e_2 clignotant " & INTEGER'image(indice - 8) SEVERITY failure;

          -- e_3, feu1 vert
        WHEN 17 => btns <= "0000";
          ASSERT (feu0 = RED AND feu1 = GREEN) REPORT "Erreur e_3" SEVERITY failure;

          -- e_3, btn0 change pas
        WHEN 18 => btns <= "0001";
          ASSERT (feu0 = RED AND feu1 = GREEN) REPORT "Erreur maintien e_3" SEVERITY failure;

          -- relâcher btn0
        WHEN 19 => btns <= "0000";

          -- btn1, passage feu1 jaune
        WHEN 20 => btns <= "0010";
        WHEN 21 => btns <= "0000";

          -- e_4, feu1 jaune
        WHEN 22 => btns <= "0000";
          ASSERT (feu0 = RED AND feu1 = YELLOW) REPORT "Erreur e_4" SEVERITY failure;

          -- e_4 solide
        WHEN 23 | 24 | 25 =>
          btns <= "0000";
          ASSERT (feu0 = RED AND feu1 = YELLOW)
          REPORT "Erreur e_4 jaune cycle " & INTEGER'image(indice - 21) SEVERITY failure;

          -- e_4 clignotant
        WHEN 26 | 28 =>
          btns <= "0000";
          ASSERT (feu0 = RED AND feu1 = OFF)
          REPORT "Erreur e_4 clignotant cycle " & INTEGER'image(indice - 21) SEVERITY failure;

        WHEN 27 | 29 =>
          btns <= "0000";
          ASSERT (feu0 = RED AND feu1 = YELLOW)
          REPORT "Erreur e_4 clignotant  cycle " & INTEGER'image(indice - 21) SEVERITY failure;

          -- btn0 et btn1, reset
        WHEN 30 => btns <= "0011";
        WHEN 31 => btns <= "0000";
          ASSERT (feu0 = OFF AND feu1 = OFF) REPORT "Erreur reset" SEVERITY failure;

          -- btn1, retour e_3 après reset
        WHEN 32 => btns <= "0010";
        WHEN 33 => btns <= "0000";
        WHEN 34 => btns <= "0000";
          ASSERT (feu0 = RED AND feu1 = GREEN) REPORT "Erreur INIT post-reset -> e_3" SEVERITY failure;

        WHEN OTHERS =>
          ASSERT false REPORT "Fin de simulation - tous les tests passés" SEVERITY failure;
      END CASE;
      indice := indice + 1;
    END IF;
  END PROCESS;

  -- On affiche le vecteur de boutons à chaque fois qu'il change de valeur
  PROCESS (btns)
  BEGIN
    -- Exemple de `report' pour écrire dans stdout pendant la simulation
    REPORT "btns: " & to_string(btns);
  END PROCESS;

END arch_tb;