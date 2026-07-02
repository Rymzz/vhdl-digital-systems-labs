-------------------------------------------------------------------------------
--
-- Division par la methode de Goldschmidt
--
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;
use ieee.fixed_pkg.all;

entity division_goldschmidt is
  generic (
    -- Nombre de bits pour le num rateur
    W_num   : integer := 16;
    -- Nombre de bits pour le d nominateur
    W_denom : integer := 8;
    -- Nombre de bits pour exprimer les r ciproques
    W_frac  : integer := 14
    );
  port (
    -- Num rateur
    num              : in  unsigned(W_num - 1 downto 0);
    -- D nominateur
    denom            : in  unsigned(W_denom - 1 downto 0);
    -- Approximation du quotient de num / denom
    quotient         : out unsigned(W_num + W_frac - 1 downto 0);
    -- '1' si b = 0
    erreur_div_par_0 : out std_logic
    );
end division_goldschmidt;

architecture arch of division_goldschmidt is
  
  -- Nombre d'iterations pour la methode de Goldschmidt
  constant K_goldschmidt : integer := 3;

  -- Vos constantes, fonctions, signaux (si necessaire)

begin
  -- Cas de la division par 0 (a garder comme tel)
  erreur_div_par_0 <= '1' when denom = 0 else '0';

process(num, denom)
   variable N : ufixed(W_num+1 downto -W_frac);  -- permet de *2 sans erreur
variable D : ufixed(W_denom+1 downto -W_frac);
    variable X : ufixed(1         downto -W_frac);
    constant two  : ufixed(1 downto -W_frac) := to_ufixed(2, 1, -W_frac);
    constant half : ufixed(1 downto -W_frac) := to_ufixed(0.5, 1, -W_frac);
  begin
  
   N := resize(to_ufixed(to_integer(num), N'high, 0), N'high, N'low);
   D := resize(to_ufixed(to_integer(denom), D'high, 0), D'high, D'low);
    
     -- normaliser le diviseur D 
   for i in 0 to W_frac+1 loop
    if D < half then
        D := resize(D * two, D'high, D'low);
        N := resize(N * two, N'high, N'low);
    elsif D > to_ufixed(1.0, D'high, D'low) then
        D := resize(D / two, D'high, D'low);
        N := resize(N / two, N'high, N'low);
    else
        exit;
    end if;
end loop;
    
    --main loop
    for i in 0 to K_goldschmidt-1 loop
      X := resize(two - D, X'high, X'low);
      N := resize(N * X, N'high, N'low);
      D := resize(D * X, D'high, D'low);
    end loop;    
    
quotient <= to_unsigned(to_integer(N * 2.0**W_frac), quotient'length);

  end process;
end arch;
