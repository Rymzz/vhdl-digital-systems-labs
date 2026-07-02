LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.NUMERIC_STD.ALL;
USE work.ALL;

ENTITY top IS
  PORT (
    rgb : OUT STD_LOGIC_VECTOR(5 DOWNTO 0);
    led_top : OUT STD_LOGIC_VECTOR(3 DOWNTO 0)
  );
END top;

ARCHITECTURE arch OF top IS
  SIGNAL clk : STD_LOGIC;
  SIGNAL count : unsigned(31 DOWNTO 0) := to_unsigned(0, 32);
  SIGNAL data_out, data_in : STD_LOGIC_VECTOR(31 DOWNTO 0);
BEGIN

  inst_code_barre : ENTITY code_barre(arch)
    GENERIC MAP(
      N => 32
    ) PORT MAP
    (
    i_detecteur => data_in,
    o_rgb => rgb,
    o_erreur_encre_vide => data_out(29),
    o_erreur_impression => data_out(30),
    o_impression_valide => data_out(31),
    o_erreur_secteur => led_top,
    o_erreur_position => data_out(4 DOWNTO 0)
    );

  data_out(28 DOWNTO 5) <= (OTHERS => '0');

  zynq : ENTITY zynq_wrapper(STRUCTURE)
    PORT MAP
    (
      clk => clk,
      to_zynq => data_out,
      from_zynq => data_in
    );

END arch;