---------------------------------------------------------------------------------------------------
--
-- PolyRISC_utilitaires_pkg.vhd
--
-- v. 1.0, 2020/11/15 Pierre Langlois
-- v. 1.0c 2021-11-28 inclut RB := GPIO_in, solution du labo #5
--
-- Déclarations et fonctions utilitaires pour le processeur PolyRISC
--
---------------------------------------------------------------------------------------------------
LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE IEEE.NUMERIC_STD.ALL;
USE IEEE.MATH_REAL.ceil;
USE IEEE.MATH_REAL.log2;

PACKAGE PolyRISC_utils IS
  -----------------------------------------------------------------------------
  -- Constantes
  --
  -- dimensions du processeur
  -- nombre de registres
  CONSTANT POLYRISC_NREG : POSITIVE := 16;
  -- Nombre de bits pour adresser les registres de PolyRISC
  -- 4 bits suffiraient pour 16 registres, mais les instructions RISC
  -- utilisent 5 bits car elles sont prévues pour 32 registres
  CONSTANT POLYRISC_AREG_W : POSITIVE := 5; -- positive(ceil(log2(real(POLYRISC_NREG))));
  -- largeur du chemin des données en bits
  CONSTANT POLYRISC_GPIO_W : POSITIVE := 32;
  -- largeur du PC et nombre de bits d'adresse de la mémoire
  -- d'instructions
  CONSTANT POLYRISC_MEMI_W : POSITIVE := 8;
  -- nombre de bits d'adresse de la mémoire des données
  CONSTANT POLYRISC_MEMD_W : POSITIVE := 8;
  -- Nombre de types d'instructions
  CONSTANT n_instr : NATURAL := 4;
  -- Nombre de valeurs possibles pour la partie détails de
  -- l'instruction
  CONSTANT n_detail : NATURAL := 16;

  -- Constantes pour la lisibilité
  -- Point de départ pour les décalages (on commence au MSB et on
  -- retranche la largeur de chaque champ)
  CONSTANT INST_START : INTEGER := POLYRISC_GPIO_W - 1;
  -- Largeur et décalage (par rapport au MSB !) de la catégorie
  CONSTANT INST_CAT_OFF : INTEGER := INST_START;
  CONSTANT INST_CAT_W : INTEGER := 2;
  -- Largeur et décalage du détail
  CONSTANT INST_DET_OFF : INTEGER := INST_CAT_OFF - INST_CAT_W;
  CONSTANT INST_DET_W : INTEGER := 4;
  -- Largeur des adresses de registres et décalages des registres
  CONSTANT INST_REG1_OFF : INTEGER := INST_DET_OFF - INST_DET_W;
  CONSTANT INST_REG_W : INTEGER := POLYRISC_AREG_W;
  CONSTANT INST_REG2_OFF : INTEGER := INST_REG1_OFF - INST_REG_W;
  -- Décalage de la valeur immédiate (la largeur est aussi le décalage
  -- car on prend tous les bits restants)
  CONSTANT INST_VAL_OFF : INTEGER := INST_REG2_OFF - INST_REG_W;
  CONSTANT INST_VAL_W : INTEGER := INST_VAL_OFF + 1;

  -- Structure pour l'encodage d'une instruction
  TYPE instruction_t IS RECORD
    categorie : NATURAL RANGE 0 TO n_instr - 1;
    detail : NATURAL RANGE 0 TO n_detail - 1;
    reg1 : unsigned(POLYRISC_AREG_W - 1 DOWNTO 0);
    reg2 : unsigned(POLYRISC_AREG_W - 1 DOWNTO 0);
    valeur : signed(INST_VAL_W - 1 DOWNTO 0);
  END RECORD;

  -- Déclaration des types pour les différents types de mémoires
  -- Fichier de registres
  TYPE fichierRegistres_t IS
  ARRAY(0 TO 2 ** POLYRISC_AREG_W - 1) OF signed(POLYRISC_GPIO_W - 1 DOWNTO 0);
  -- Mémoire des données
  TYPE memoireDonnees_t IS
  ARRAY(0 TO 2 ** POLYRISC_MEMD_W - 1) OF signed(POLYRISC_GPIO_W - 1 DOWNTO 0);

  -----------------------------------------------------------------------------
  -- Fonction pour générer des instructions facilement en passant des
  -- entiers
  -- 
  FUNCTION gen_inst(
    cat : NATURAL RANGE 0 TO n_instr - 1;
    det : NATURAL RANGE 0 TO n_detail - 1;
    reg1 : INTEGER RANGE 0 TO POLYRISC_NREG - 1;
    reg2 : INTEGER RANGE 0 TO POLYRISC_NREG - 1;
    val : INTEGER RANGE -2 ** POLYRISC_NREG TO 2 ** POLYRISC_NREG - 1
  ) RETURN instruction_t;
  -- Conversion de unsigned en instruction
  FUNCTION to_inst(bits : unsigned(POLYRISC_GPIO_W - 1 DOWNTO 0)
  ) RETURN instruction_t;
  -- Conversion inverse
  FUNCTION inst_to_unsigned(inst : instruction_t
  ) RETURN unsigned;

  -- Catégories d'instructions
  CONSTANT reg : NATURAL := 0;
  CONSTANT reg_valeur : NATURAL := 1;
  CONSTANT branchement : NATURAL := 2;
  CONSTANT memoire : NATURAL := 3;

  -- Détails d'instructions pour la catégorie mémoire
  CONSTANT lireMemoire : NATURAL := 0;
  CONSTANT ecrireMemoire : NATURAL := 1;
  CONSTANT lireGPIO_in : NATURAL := 2;
  CONSTANT ecrireGPIO_out : NATURAL := 3;

  -- Encodage des opérations de l'UAL
  CONSTANT passeA : NATURAL := 0;
  CONSTANT passeB : NATURAL := 1;
  CONSTANT AplusB : NATURAL := 2;
  CONSTANT AmoinsB : NATURAL := 3;
  CONSTANT AetB : NATURAL := 4;
  CONSTANT AouB : NATURAL := 5;
  CONSTANT nonA : NATURAL := 6;
  CONSTANT AouxB : NATURAL := 7;
  CONSTANT absA : NATURAL := 8;
  CONSTANT minAB : NATURAL := 9;
  CONSTANT maxAB : NATURAL := 10;
  CONSTANT AmulB : NATURAL := 11;
  CONSTANT Adiv2 : NATURAL := 12;

  -- Encodage des conditions de branchement
  CONSTANT egal : NATURAL := 0;
  CONSTANT diff : NATURAL := 1;
  CONSTANT ppq : NATURAL := 2;
  CONSTANT pgq : NATURAL := 3;
  CONSTANT ppe : NATURAL := 4;
  CONSTANT pge : NATURAL := 5;
  CONSTANT toujours : NATURAL := 6;
  CONSTANT jamais : NATURAL := 7;

  -- Déclaration des instructions prédéfinies
  -- Elles sont définies dans le package body
  CONSTANT NOP : instruction_t;
  CONSTANT STOP : instruction_t;
END PACKAGE;

PACKAGE BODY PolyRISC_utils IS
  -- Définition de la fonction gen_inst
  FUNCTION gen_inst(
    cat : NATURAL RANGE 0 TO n_instr - 1;
    det : NATURAL RANGE 0 TO n_detail - 1;
    reg1 : INTEGER RANGE 0 TO POLYRISC_NREG - 1;
    reg2 : INTEGER RANGE 0 TO POLYRISC_NREG - 1;
    val : INTEGER RANGE -2 ** POLYRISC_NREG TO 2 ** POLYRISC_NREG - 1
  ) RETURN instruction_t
    IS
    VARIABLE ret : instruction_t;
  BEGIN
    ret := (
      cat,
      det,
      to_unsigned(reg1, INST_REG_W),
      to_unsigned(reg2, INST_REG_W),
      to_signed(val, INST_VAL_W)
      );
    RETURN ret;
  END gen_inst;
  -- Définition de to_inst
  FUNCTION to_inst(bits : unsigned(POLYRISC_GPIO_W - 1 DOWNTO 0))
    RETURN instruction_t
    IS
    VARIABLE ret : instruction_t;
  BEGIN
    ret := (
      -- Catégorie
      to_integer(bits(INST_CAT_OFF DOWNTO INST_CAT_OFF - INST_CAT_W + 1)),
      -- Détail
      to_integer(bits(INST_DET_OFF DOWNTO INST_DET_OFF - INST_DET_W + 1)),
      -- Registre 1
      bits(INST_REG1_OFF DOWNTO INST_REG1_OFF - INST_REG_W + 1),
      bits(INST_REG2_OFF DOWNTO INST_REG2_OFF - INST_REG_W + 1),
      signed(bits(INST_VAL_OFF DOWNTO 0))
      );
    RETURN ret;
  END to_inst;
  -- Override de to_unsigned pour les instructions
  FUNCTION inst_to_unsigned(inst : instruction_t)
    RETURN unsigned
    IS
    VARIABLE ret : unsigned(POLYRISC_GPIO_W - 1 DOWNTO 0);
  BEGIN
    ret := to_unsigned(inst.categorie, INST_CAT_W) &
      to_unsigned(inst.detail, INST_DET_W) &
      inst.reg1 &
      inst.reg2 &
      unsigned(inst.valeur);
    RETURN ret;
  END inst_to_unsigned;

  -- instructions prédéfinies
  CONSTANT NOP : instruction_t := gen_inst(
  branchement, jamais, 0, 0, 0
  );
  CONSTANT STOP : instruction_t := gen_inst(
  branchement, toujours, 0, 0, 0
  );
END PACKAGE BODY;