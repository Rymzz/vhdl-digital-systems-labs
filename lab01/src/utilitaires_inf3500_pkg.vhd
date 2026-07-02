---------------------------------------------------------------------------------------------------
-- 
-- utilitaires_inf3500_pkg.vhd
-- D�clarations et fonctions utilitaires pour le cours INF3500
--
-- Pierre Langlois
-- v. 1.0, 2020-07-12
-- v. 1.1, 2020-10-21 correction assert dans la fonction unsigned_to_BCD(nombre : unsigned(9 downto 0)), erreur trouv�e par F�lix Boucher
-- v. 1.2, 2020-10-24 changement de nom pour utilitaires_inf3500_pkg.vhd
-- v. 1.3, 2020-10-31 ajout de fonctions pour les caract�res encod�s en Base64
--                    _2_ devient _to_
-- v. 1.4, 2021-01-23 ajout de la fonction bool2stdl()
--                    modifications mineures au texte, fonction unsigned_to_BCD
-- v. 1.5, 2022-01-07 ajout de la fonction compte_valeurs
--                    modification du nom de la fonction indice_Base64_to_character
--
-- 
---------------------------------------------------------------------------------------------------

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.numeric_std.ALL;

PACKAGE utilitaires_inf3500_pkg IS

  SUBTYPE quartet IS STD_LOGIC_VECTOR(3 DOWNTO 0);
  SUBTYPE quartet_signed IS signed(3 DOWNTO 0);
  SUBTYPE quartet_unsigned IS unsigned(3 DOWNTO 0);
  SUBTYPE segments IS STD_LOGIC_VECTOR(7 DOWNTO 0);

  SUBTYPE BCD IS quartet;

  SUBTYPE BCD1 IS unsigned(3 DOWNTO 0); -- un chiffre d�cimal BCD
  SUBTYPE BCD2 IS unsigned(7 DOWNTO 0); -- deux chiffres d�cimaux BCD, ex. 58 : 0101_1000
  SUBTYPE BCD3 IS unsigned(11 DOWNTO 0); -- trois chiffres d�cimaux BCD, ex. 907 : 1001_0000_0111

  TYPE quatre_symboles IS ARRAY(3 DOWNTO 0) OF segments;

  FUNCTION hex_to_7seg(chiffre_hex : quartet) RETURN segments;
  FUNCTION hex_to_7seg(chiffre_hex : quartet_signed) RETURN segments;
  FUNCTION hex_to_7seg(chiffre_hex : quartet_unsigned) RETURN segments;
  FUNCTION BCD_to_7seg(chiffre_bcd : BCD) RETURN segments;

  FUNCTION unsigned_to_BCD(nombre : unsigned(9 DOWNTO 0)) RETURN BCD3;

  FUNCTION character_to_7seg(caractere : CHARACTER) RETURN segments;

  FUNCTION indice_Base64_to_character(indice : NATURAL RANGE 0 TO 63) RETURN CHARACTER;

  FUNCTION hex_to_character(chiffre_hex : NATURAL RANGE 0 TO 15) RETURN CHARACTER;
  FUNCTION hex_to_character(chiffre_hex : quartet_unsigned) RETURN CHARACTER;

  FUNCTION bool2stdl(b : BOOLEAN) RETURN STD_LOGIC;

  FUNCTION compte_valeurs(s : STD_LOGIC_VECTOR; v : STD_LOGIC) RETURN NATURAL;

  FUNCTION clog2(n : NATURAL) RETURN INTEGER;

END PACKAGE;

PACKAGE BODY utilitaires_inf3500_pkg IS

  ------------------------------------------------------------------------------------------------
  --
  -- d�codeur pour caract�res hexad�cimaux vers affichage � 7 segments (8 bits incluant le point)
  -- correspondances entre bits et segments:
  --      0
  --     ---  
  --  5 |   | 1
  --     ---   <- 6
  --  4 |   | 2
  --     ---
  --      3     
  --  point: bit 7
  --
  FUNCTION hex_to_7seg(chiffre_hex : quartet) RETURN segments IS
    VARIABLE lessegments : segments;
  BEGIN
    CASE chiffre_hex IS
      WHEN x"0" => lessegments := "11000000";
      WHEN x"1" => lessegments := "11111001";
      WHEN x"2" => lessegments := "10100100";
      WHEN x"3" => lessegments := "10110000";
      WHEN x"4" => lessegments := "10011001";
      WHEN x"5" => lessegments := "10010010";
      WHEN x"6" => lessegments := "10000010";
      WHEN x"7" => lessegments := "11111000";
      WHEN x"8" => lessegments := "10000000";
      WHEN x"9" => lessegments := "10010000";
      WHEN x"A" => lessegments := "10001000"; -- A
      WHEN x"B" => lessegments := "10000011"; -- b
      WHEN x"C" => lessegments := "11000110"; -- C
      WHEN x"D" => lessegments := "10100001"; -- d
      WHEN x"E" => lessegments := "10000110"; -- E
      WHEN x"F" => lessegments := "10001110"; -- F
      WHEN OTHERS => lessegments := "01111111"; -- erreur, affichage �teint sauf le point (ne devrait pas se produire)
    END CASE;

    RETURN lessegments;

  END;

  -- fonction surcharg�e pour accepter une entr�e de type signed
  FUNCTION hex_to_7seg(chiffre_hex : quartet_signed) RETURN segments IS
  BEGIN
    RETURN hex_to_7seg(quartet(chiffre_hex));
  END;

  -- fonction surcharg�e pour accepter une entr�e de type unsigned
  FUNCTION hex_to_7seg(chiffre_hex : quartet_unsigned) RETURN segments IS
  BEGIN
    RETURN hex_to_7seg(quartet(chiffre_hex));
  END;

  -- fonction surcharg�e pour accepter une entr�e de type BCD
  FUNCTION BCD_to_7seg(chiffre_bcd : BCD) RETURN segments IS
  BEGIN
    RETURN hex_to_7seg(chiffre_bcd);
  END;

  ------------------------------------------------------------------------------------------------
  --
  -- d�codeur pour caract�res ASCII vers affichage � 7 segments (8 bits incluant le point)
  -- correspondances entre bits et segments:
  --      0
  --     ---  
  --  5 |   | 1
  --     ---   <- 6
  --  4 |   | 2
  --     ---
  --      3     
  --  point: bit 7
  --
  FUNCTION character_to_7seg(caractere : CHARACTER) RETURN segments IS
    VARIABLE lessegments : segments;
  BEGIN
    CASE caractere IS
      WHEN ' ' => lessegments := "11111111";
      WHEN '!' => lessegments := "01111001";
      WHEN '"' => lessegments := "11011101";
      WHEN '#' => lessegments := "00100011";
      WHEN ''' => lessegments := "00010010";
      WHEN '%' => lessegments := "00011100";
      WHEN '&' => lessegments := "00001100";
      WHEN ''' => lessegments := "11111101";
      WHEN '(' => lessegments := "11000110";
      WHEN ')' => lessegments := "11110000";
      WHEN '*' => lessegments := "00111001";
      WHEN '+' => lessegments := "10111001";
      WHEN ',' => lessegments := "11110011";
      WHEN '-' => lessegments := "10111111";
      WHEN '.' => lessegments := "01111111";
      WHEN '/' => lessegments := "10101101";
      WHEN '0' => lessegments := "11000000";
      WHEN '1' => lessegments := "11111001";
      WHEN '2' => lessegments := "10100100";
      WHEN '3' => lessegments := "10110000";
      WHEN '4' => lessegments := "10011001";
      WHEN '5' => lessegments := "10010010";
      WHEN '6' => lessegments := "10000010";
      WHEN '7' => lessegments := "11111000";
      WHEN '8' => lessegments := "10000000";
      WHEN '9' => lessegments := "10010000";
      WHEN ':' => lessegments := "01111001";
      WHEN ';' => lessegments := "01111001";
      WHEN '<' => lessegments := "10100111";
      WHEN '=' => lessegments := "10110111";
      WHEN '>' => lessegments := "10110011";
      WHEN '?' => lessegments := "00100100";
      WHEN '@' => lessegments := "00100011";
      WHEN 'A' => lessegments := "10001000";
      WHEN 'B' => lessegments := "10000011";
      WHEN 'C' => lessegments := "11000110";
      WHEN 'D' => lessegments := "10100001";
      WHEN 'E' => lessegments := "10000110";
      WHEN 'F' => lessegments := "10001110";
      WHEN 'G' => lessegments := "10010000";
      WHEN 'H' => lessegments := "10001001";
      WHEN 'I' => lessegments := "11111001";
      WHEN 'J' => lessegments := "11100001";
      WHEN 'K' => lessegments := "10001001";
      WHEN 'L' => lessegments := "11000111";
      WHEN 'M' => lessegments := "11001000";
      WHEN 'N' => lessegments := "10101011";
      WHEN 'O' => lessegments := "10100011";
      WHEN 'P' => lessegments := "10001100";
      WHEN 'Q' => lessegments := "01000000";
      WHEN 'R' => lessegments := "10101111";
      WHEN 'S' => lessegments := "10010010";
      WHEN 'T' => lessegments := "11001110";
      WHEN 'U' => lessegments := "11000001";
      WHEN 'V' => lessegments := "11100011";
      WHEN 'W' => lessegments := "11100011";
      WHEN 'X' => lessegments := "11001001";
      WHEN 'Y' => lessegments := "10011001";
      WHEN 'Z' => lessegments := "10100100";
      WHEN '[' => lessegments := "11000110";
      WHEN '\' => lessegments := "10011011";
      WHEN ']' => lessegments := "11110000";
      WHEN '^' => lessegments := "11011100";
      WHEN '_' => lessegments := "11110111";
      WHEN '`' => lessegments := "11011111";
      WHEN 'a' => lessegments := "00100011";
      WHEN 'b' => lessegments := "10000011";
      WHEN 'c' => lessegments := "10100111";
      WHEN 'd' => lessegments := "10100001";
      WHEN 'e' => lessegments := "10000110";
      WHEN 'f' => lessegments := "10001110";
      WHEN 'g' => lessegments := "10010000";
      WHEN 'h' => lessegments := "10001011";
      WHEN 'i' => lessegments := "11111011";
      WHEN 'j' => lessegments := "11100001";
      WHEN 'k' => lessegments := "10001001";
      WHEN 'l' => lessegments := "11001111";
      WHEN 'm' => lessegments := "10101011";
      WHEN 'n' => lessegments := "10101011";
      WHEN 'o' => lessegments := "10100011";
      WHEN 'p' => lessegments := "10001100";
      WHEN 'q' => lessegments := "10011000";
      WHEN 'r' => lessegments := "10101111";
      WHEN 's' => lessegments := "10010010";
      WHEN 't' => lessegments := "11001110";
      WHEN 'u' => lessegments := "11100011";
      WHEN 'v' => lessegments := "11100011";
      WHEN 'w' => lessegments := "11100011";
      WHEN 'x' => lessegments := "10001001";
      WHEN 'y' => lessegments := "10010001";
      WHEN 'z' => lessegments := "10100100";
      WHEN '{' => lessegments := "11000110";
      WHEN '|' => lessegments := "11001111";
      WHEN '}' => lessegments := "11110000";
      WHEN '~' => lessegments := "10111111";
      WHEN OTHERS => lessegments := "01111111"; -- erreur, affichage �teint sauf le point (ne devrait pas se produire)
    END CASE;

    RETURN lessegments;

  END;
  ------------------------------------------------------------------------------------------------
  --
  -- Conversion d'un nombre binaire type unsigned vers d�cimal sur 3 chiffres (centaines, dizaines, unit�s) encod� en BCD.
  -- AVERTISSEMENT : ne fonctionne que pour des valeurs inf�rieures � 1000
  --
  -- Description combinatoire par encodeurs � priorit�.
  --
  FUNCTION unsigned_to_BCD(nombre : unsigned(9 DOWNTO 0)) RETURN BCD3 IS
    VARIABLE n, c, d, u : NATURAL := 0;
  BEGIN

    ASSERT nombre < 1000 REPORT "fonction unsigned_to_BCD, les nombres >= 1000 ne sont pas pris en charge" SEVERITY failure;

    n := to_integer(nombre);

    c := 0;
    FOR centaines IN 9 DOWNTO 1 LOOP
      IF n >= centaines * 100 THEN
        c := centaines;
        EXIT;
      END IF;
    END LOOP;

    n := n - c * 100;

    d := 0;
    FOR dizaines IN 9 DOWNTO 1 LOOP
      IF n >= dizaines * 10 THEN
        d := dizaines;
        EXIT;
      END IF;
    END LOOP;

    u := n - d * 10;

    RETURN to_unsigned(c, 4) & to_unsigned(d, 4) & to_unsigned(u, 4);

  END;
  ------------------------------------------------------------------------------------------------
  --
  -- obtenir le caract�re ASCII correspondant � l'indice en encodage Base64
  -- r�f�rence : https://en.wikipedia.org/wiki/Base64
  -- L'encodage Base64 inclut les lettres majuscules, les lettres minuscules, les chiffres '0' � '9' et les caract�res '+' et '/'
  --
  FUNCTION indice_Base64_to_character(indice : NATURAL RANGE 0 TO 63) RETURN CHARACTER IS
  BEGIN
    IF indice <= 25 THEN
      -- lettres majuscules, 'A' = x"41" = 65
      RETURN CHARACTER'val(65 + indice);
    ELSIF indice <= 51 THEN
      -- lettres minuscules, 'a' = x"61" = 97
      RETURN CHARACTER'val(97 + indice - 26);
    ELSIF indice <= 61 THEN
      -- chiffres 0 � 9, '0' = x"30" = 48
      RETURN CHARACTER'val(48 + indice - 52);
    ELSIF indice = 62 THEN
      RETURN '+';
    ELSE
      RETURN '/';
    END IF;
  END;
  ------------------------------------------------------------------------------------------------
  --
  -- obtenir le caract�re ASCII correspondant au quartet en entr�e : {'0' � '9', 'a' � 'f'}
  -- on choisit arbitrairement de prendre les lettres minuscules 'a' � 'f'
  --
  FUNCTION hex_to_character(chiffre_hex : NATURAL RANGE 0 TO 15) RETURN CHARACTER IS
  BEGIN
    IF chiffre_hex <= 9 THEN
      -- les chiffres 0 � 9
      RETURN CHARACTER'val(48 + chiffre_hex);
    ELSE
      -- lettres minuscules, 'a' = x"61" = 97
      RETURN CHARACTER'val(97 + chiffre_hex - 10);
    END IF;
  END;

  ------------------------------------------------------------------------------------------------
  --
  -- obtenir le caract�re ASCII correspondant au quartet en entr�e : {'0' � '9', 'a' � 'f'}
  --
  FUNCTION hex_to_character(chiffre_hex : quartet_unsigned) RETURN CHARACTER IS
  BEGIN
    RETURN hex_to_character(to_integer(chiffre_hex));
  END;
  ------------------------------------------------------------------------------------------------
  --
  -- convertir un boolean en std_logic
  -- cette fonction est utile pour rendre le code plus compact
  -- remplace {si vrai alors F <= '1' sinon F <= '0'}
  --
  FUNCTION bool2stdl(b : BOOLEAN) RETURN STD_LOGIC IS
  BEGIN
    IF b THEN
      RETURN '1';
    ELSE
      RETURN '0';
    END IF;
  END;
  ------------------------------------------------------------------------------------------------
  --
  -- retourne le nombre de fois o� la valeur v de type std_logic
  -- est pr�sente dans le vecteur s de type std_logic_vector
  --
  FUNCTION compte_valeurs(s : STD_LOGIC_VECTOR; v : STD_LOGIC) RETURN NATURAL IS
    VARIABLE compte : NATURAL;
  BEGIN
    compte := 0;
    FOR k IN s'RANGE LOOP
      IF s(k) = v THEN
        compte := compte + 1;
      END IF;
    END LOOP;
    RETURN compte;
  END;

  ------------------------------------------------------------------------------------------------
  --
  -- retourne le nombre de bit n�cessaire pour indexer un vecteur de taille n
  --
  FUNCTION clog2(n : NATURAL) RETURN INTEGER IS
    VARIABLE temp : INTEGER := n;
    VARIABLE compte : INTEGER := 0;
  BEGIN
    WHILE temp > 1 LOOP
      compte := compte + 1;
      temp := temp / 2;
    END LOOP;
    IF (2 ** compte >= n) THEN
      RETURN compte;
    ELSE
      RETURN compte + 1;
    END IF;
  END FUNCTION;

END;