---------------------------------------------------------------------------------------------------
-- 
-- racine_carree.vhd
--
-- v. 1.0 Pierre Langlois 2022-02-25 laboratoire #4 INF3500 - code de base
-- v. 1.1 2024-07-29
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity racine_carree is
  generic (
    -- Nombre de bits de A
    N    : positive := 16;
    -- Nombre de bits de X
    M    : positive := 8;
    -- Nombre d'itérations à faire
    kmax : positive := 11
    );
  port (
    reset, clk : in  std_logic;
    -- Le nombre dont on cherche la racine carrée
    i_A        : in  unsigned(N - 1 downto 0);
    -- Commande pour débuter les calculs
    i_go       : in  std_logic;
    -- La racine carré de A, telle que X * X = A
    o_X        : out unsigned(M - 1 downto 0);
    -- '1' quand les calculs sont terminés ==> la valeur de X est
    -- stable et correcte
    o_fini     : out std_logic
    );
end racine_carree;

architecture newton of racine_carree is
  constant W_frac : integer := 14;  -- pour le module de division, nombre de bits pour exprimer les réciproques

  type etat_type is (attente, calculs);
  signal etat : etat_type := attente;

  --- votre code ici
  signal A_entier :unsigned(N-1 downto 0);
  signal xk : unsigned ( M -1 downto 0);
  signal quotient :unsigned((N +W_frac - 1) downto 0);
  signal erreur_div_par_0 : std_logic := '0';
  
  signal xk_virgule_fixe : unsigned( N +W_frac- 1 downto 0); --xk en virgule fixe, car une somme se fait sur deux unsigned de meme largeur (partie 1)
  signal somme : unsigned( N +W_frac- 1 downto 0);
  signal moyenne : unsigned( N +W_frac- 1 downto 0);
  signal k : integer range 0 to kmax;
  
begin
  --diviseur : entity division_par_reciproque(arch)
  diviseur : entity division_goldschmidt(arch)
    generic map(
        W_num =>N,
        W_denom=> M, 
        W_frac=> W_frac
    )
    port map(
        num => A_entier,
        denom => xk, 
        quotient=>quotient, 
        erreur_div_par_0 => erreur_div_par_0
    );
    
    xk_virgule_fixe <= shift_left(resize(xk, xk_virgule_fixe'length), W_frac);
    somme <= xk_virgule_fixe + quotient;
    moyenne <= shift_right(somme, 1);
    
    process (clk, reset)
    begin
    if reset='1' then
        etat <= attente;
        A_entier <=(others => '0');
        xk <= (others => '0');
        k <= 0;
        
    elsif rising_edge(clk) then 
        case etat is
        
        when attente =>
           if i_go = '1' then
              A_entier <= i_A;
              xk<= to_unsigned(255, M);
              etat <= calculs;
              k<= 0;
           end if;
           
        when calculs =>
            xk <= moyenne(M+W_frac - 1 downto W_frac);
            
            if k = kmax - 1 then
                etat <= attente;
            else
                k <= k+1;
            end if;
            
        end case;
    end if;
 end process;
    
  o_X    <= xk;
  o_fini <= '1' when etat = attente else '0';
end newton;
