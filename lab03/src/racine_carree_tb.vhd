---------------------------------------------------------------------------------------------------
-- 
-- racine_carree_tb.vhd
--
-- v. 1.0 Pierre Langlois 2022-02-25 laboratoire #4 INF3500, fichier de démarrage
-- v. 1.1 2024-07-29
--
---------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use work.all;

entity racine_carree_tb is
  generic (
    N : positive := 16;
    M : positive := 8
    );
end racine_carree_tb;

architecture arch of racine_carree_tb is
  signal reset     : std_logic;
  signal clk       : std_logic := '0';
  constant periode : time      := 10 ns;

  signal A    : unsigned(N - 1 downto 0);  -- le nombre dont on cherche la racine carrée
  signal go   : std_logic := '0';  --               commande pour débuter les calculs
  signal X    : unsigned(M - 1 downto 0);  -- la racine carrée de A, telle que X * X = A
  signal fini : std_logic;  --             '1' quand les calculs sont terminés ==> la valeur de X est stable et correcte
begin
  UUT : entity racine_carree(newton)
    generic map(16, 8, 11)
    port map(reset=> reset,
    clk=>clk,
    i_A => A, 
    i_go => go, 
    o_x => X, 
    o_fini => fini
    );

  clk   <= not clk after periode / 2;
  reset <= '1'     after 0 ns, '0' after 5 * periode / 4;
  
  process 
    variable resultat_racine_attendu : integer;
    variable resultat_racine_obtenu : integer;
    variable erreur_resultat : integer;
    variable erreur_maximale : integer := 0;
    variable somme_erreurs : integer := 0;
  begin
    wait until reset = '0';
    wait until rising_edge(clk);
    
    for i in 0 to 65025 loop
        A<=to_unsigned(i, A'length);
    
        go <= '1';
        wait until rising_edge(clk);
        go <= '0';
        wait until fini = '0';
        wait until fini = '1';

        resultat_racine_attendu := integer(floor(sqrt(real(i)))); --racine carrée de i (transformée en réel car sqrt marche seulement sur des réel)
        resultat_racine_obtenu := to_integer(X); -- on lit o_x 
        erreur_resultat := abs(resultat_racine_obtenu - resultat_racine_attendu); --difference 
        somme_erreurs := somme_erreurs + erreur_resultat; --on additionne toutes les erreurs
        
         if erreur_resultat > erreur_maximale then --pour retourner l'erreur maximal a la fin (partie 2)
            erreur_maximale := erreur_resultat;
         end if;
         
        report "A = "& integer'image(i);
        report "X ="& integer'image(resultat_racine_obtenu);
        report"erreur = " & integer'image(erreur_resultat);
        report "Erreur max = "& integer'image(erreur_maximale);
        if i /= 0 then
        report "Erreur moyenne = " & real'image(real(somme_erreurs) / real(i));
    end if;
     end loop;
     -- affiche l'erreur maximale et l'erreur moyenne
        report "Erreur max = "& integer'image(erreur_maximale);
        report "Erreur moyenne = "& real'image(real(somme_erreurs) /65026.0);
      
    wait;
 end process;
        
  --A  <= to_unsigned(30000, A'length);   -- une stimulation de base
  --go <= '0' after 0 ns, '1' after 27 ns, '0' after 37 ns;  -- une stimulation de base
end arch;
