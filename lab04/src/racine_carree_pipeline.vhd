---------------------------------------------------------------------------------------------------
-- 
-- racine_carree_pipeline.vhd
--
-- v. 1.0 2024-08-07 laboratoire #4 INF3500 - code de base
-- v. 1.1 2025-02-17 laboratoire #4 INF3500 - code de base
--
---------------------------------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity racine_carree_pipeline is
  generic (
    -- Nombre de bits de A
    N    : positive := 16;
    -- Nombre de bits de X
    M    : positive := 8;
    -- Nombre max d'itérations
    kmax : positive := 10
    );
  port (
    reset, clk : in  std_logic;
    -- Le nombre dont on cherche la racine carré
    i_A        : in  unsigned(N - 1 downto 0);
    -- '1' quand une données qui est passée à travers la pipeline
    -- est valide
    i_valid    : in  std_logic;
    -- '1' quand la dernière donnée est passée à travers la
    -- pipeline
    i_last     : in  std_logic;
    -- Indique quand le zynq est prêt à recevoir des données
    i_ready    : in  std_logic;
    -- La racine carré de A, telle que X * X = A
    o_X        : out unsigned(M - 1 downto 0);
    -- La valeur de A associee a cette racine carree (pour la verification dans le testbench)
    o_A        : out unsigned(N - 1 downto 0);
    -- '1' quand une données qui est passée à travers la pipeline
    -- est valide
    o_valid    : out std_logic;
    -- '1' quand la dernière donnée est passée à travers la
    -- pipeline
    o_last     : out std_logic
    );
end racine_carree_pipeline;

architecture newton of racine_carree_pipeline is
  -- Pour le module de division, nombre de bits pour exprimer les réciproques
  constant W_frac : integer := 14;

  -- Types utilisables pour les tableaux de signaux
  -- Ici, exemple illustratif et incomplet pour un pipeline a 3 etages qui ne fait que passer les donnees
  type pipeline_vec_n_t is array(0 to kmax) of unsigned(N-1 downto 0);
  type pipeline_vec_m_t is array(0 to kmax) of unsigned(M-1 downto 0);
  type pipeline_bit_t is array(0 to kmax) of std_logic;
  signal A_pipeline                  : pipeline_vec_n_t;
  signal X_pipeline  : pipeline_vec_m_t;
  signal valid_pipeline, last_pipeline : pipeline_bit_t;
  
  
  type quotient_vec_t is array(0 to kmax - 1) of unsigned(N+W_frac -1 downto 0);
  type xk_virgule_fixe_vec_t is array(0 to kmax - 1) of unsigned(N+W_frac -1 downto 0);
  type moyenne_vec_t is array(0 to kmax - 1) of unsigned(N+W_frac -1 downto 0);
  type somme_vec_t is array(0 to kmax - 1) of unsigned(N+W_frac -1 downto 0);
  type erreur_vec_T is array(0 to kmax - 1) of std_logic;

  signal quotient_etage : quotient_vec_t;
  signal xk_virgule_fixe_etage : xk_virgule_fixe_vec_t;
  signal somme_etage : somme_vec_t;
  signal moyenne_etage : moyenne_vec_t;
  signal prochain_X : pipeline_vec_m_t;
  signal erreur_div_etage :erreur_vec_t;
  
begin
  -- Mettre les valeurs de sortie au dernier étage de pipeline
  -- Ici, exemple illustratif et incomplet pour un pipeline a 3 etages qui ne fait que passer les donnees
  o_X     <= X_pipeline(kmax);
  o_A     <= A_pipeline(kmax);
  o_valid <= valid_pipeline(kmax);
  o_last  <= last_pipeline(kmax);
  generate_etages: for i in 0 to kmax - 1 generate 
  begin
  -- Instancier un diviseur par reciprque par etage
  diviseur : entity division_par_reciproque(arch)
    generic map(
        W_num => N, 
        W_denom =>M,
        W_frac => W_frac
         )
     port map(
       num      => A_pipeline(i),
       denom    => X_pipeline(i),
       quotient => quotient_etage(i),
       erreur_div_par_0 => erreur_div_etage(i)
       );
       
       xk_virgule_fixe_etage(i) <= shift_left(resize(X_pipeline(i), N + W_frac), W_frac);
       somme_etage(i) <= xk_virgule_fixe_etage(i) + quotient_etage(i);
       moyenne_etage(i) <= shift_right(somme_etage(i), 1);
       prochain_X(i) <= moyenne_etage(i)(M+W_frac-1 downto W_frac);
     end generate;

  -- Connecter les registres des differents etages du pipeline
  process (clk, reset) is
  begin
    if reset = '1' then
      -- Réinitialiser les registres du pipeline
      A_pipeline     <= (others => (others => '0'));
      X_pipeline <= (others => (others => '0'));
      valid_pipeline <= (others => '0');
      last_pipeline  <= (others => '0');
    elsif rising_edge(clk) and i_ready = '1' then
      -- Le premier élément de la pipeline est l'entrée, on lit une entrée à
      -- chaque coup d'horloge
      A_pipeline(0)     <= i_A;
      X_pipeline(0) <= to_unsigned(255, M);
      valid_pipeline(0) <= i_valid;
      last_pipeline(0)  <= i_last;

      -- Faire circuler les données dans la pipeline à chaque coup d'horloge
      -- Ici, exemple illustratif et incomplet pour un pipeline a 3 etages qui ne fait que passer les donnees
  for i in 1 to kmax loop 
      A_pipeline(i)     <= A_pipeline(i-1);
      X_pipeline(i)     <= prochain_X(i-1);
      valid_pipeline(i) <= valid_pipeline(i-1);
      last_pipeline(i)  <= last_pipeline(i-1);
  end loop;

    end if;
  end process;

end newton;