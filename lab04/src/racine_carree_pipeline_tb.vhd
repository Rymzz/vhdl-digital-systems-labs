---------------------------------------------------------------------------------------------------
-- 
-- racine_carree_pipeline_tb.vhd
--
-- v. 1.0 Pierre Langlois 2022-02-25 laboratoire #4 INF3500, fichier de démarrage
-- v. 1.1 2024-07-29
-- v. 1.2 2025-03-17 laboratoire #4
--
---------------------------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
USE work.ALL;

ENTITY racine_carree_pipeline_tb IS
  GENERIC (
    N : POSITIVE := 16;
    M : POSITIVE := 8
  );
END racine_carree_pipeline_tb;

ARCHITECTURE arch OF racine_carree_pipeline_tb IS
  SIGNAL reset : STD_LOGIC;
  SIGNAL clk : STD_LOGIC := '0';
  CONSTANT periode : TIME := 10 ns;
  --  constant MAX     : integer   := 10;
  CONSTANT MAX : INTEGER := 65025;
  CONSTANT kmax : INTEGER := 10;

  -- Sigaux pour le module
  SIGNAL A_in : unsigned(N - 1 DOWNTO 0);
  SIGNAL A_out : unsigned(N - 1 DOWNTO 0);
  SIGNAL last_in : STD_LOGIC;
  SIGNAL ready_in : STD_LOGIC;
  SIGNAL valid_in : STD_LOGIC;
  SIGNAL X : unsigned(M - 1 DOWNTO 0);
  SIGNAL last_out : STD_LOGIC;
  SIGNAL valid_out : STD_LOGIC;
BEGIN
  UUT : ENTITY racine_carree_pipeline(newton)
    GENERIC MAP(N, M, kmax)
    PORT MAP(
      reset => reset,
      clk => clk,
      i_A => A_in,
      i_valid => valid_in,
      i_last => last_in,
      i_ready => ready_in,
      o_X => X,
      o_A => A_out,
      o_valid => valid_out,
      o_last => last_out
    );

  -- Simualtion de l'horloge et du power-on reset
  clk <= NOT clk AFTER periode / 2;
  reset <= '1' AFTER 0 ns, '0' AFTER 5 * periode / 4;

  PROCESS (clk, reset)
    VARIABLE i : INTEGER := 0;
    VARIABLE resultat_racine_attendu : INTEGER;
    VARIABLE resultat_racine_obtenu : INTEGER;
    VARIABLE erreur_resultat : INTEGER;
    VARIABLE erreur_maximale : INTEGER := 0;
    VARIABLE somme_erreurs : INTEGER := 0;
  BEGIN
    IF reset = '1' THEN
      A_in <= (OTHERS => '0');
      valid_in <= '0';
      last_in <= '0';
      ready_in <= '0';
    ELSIF falling_edge(clk) THEN

      -- Pour le test-bench, on considère que le handshake AXI est
      -- toujours fait
      valid_in <= '1';
      ready_in <= '1';

      -- Application de i en entree
      IF i <= MAX THEN -- MAX est 65025

        -- Last pour la derniere donnee
        last_in <= '1' WHEN i = MAX ELSE
          '0';
        A_in <= to_unsigned(i, N);
        i := i + 1;

        IF valid_out = '1' THEN
          resultat_racine_attendu := INTEGER(floor(sqrt(real(to_integer(A_out))))); --racine carrée de A_out
          resultat_racine_obtenu := to_integer(X); -- on lit X 
          erreur_resultat := ABS(resultat_racine_obtenu - resultat_racine_attendu); --difference 
          somme_erreurs := somme_erreurs + erreur_resultat; --on additionne toutes les erreurs

          IF erreur_resultat > erreur_maximale THEN --pour retourner l'erreur maximal
            erreur_maximale := erreur_resultat;
          END IF;

          REPORT "---------- A = " & integer'image(to_integer(A_out)) & " ----------";

            REPORT "A = " & INTEGER'image(to_integer(A_out));
          REPORT "X =" & INTEGER'image(resultat_racine_obtenu);
          REPORT"erreur = " & INTEGER'image(erreur_resultat);
          REPORT "Erreur max = " & INTEGER'image(erreur_maximale);
          IF to_integer(A_out) /= 0 THEN
            REPORT "Erreur moyenne = " & real'image(real(somme_erreurs) / real(to_integer(A_out)));
          END IF;
          REPORT "----------------------------------------"; 
          END IF;

          -- Fin de simulation une fois la derniere donnee reçue
        ELSIF last_out = '1' THEN
          REPORT "Fin de simulation" SEVERITY failure;
        END IF;
      END IF;
    END PROCESS;

  END arch;