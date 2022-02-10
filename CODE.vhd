library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_signed.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity driver8bit is
port(a : in std_logic_vector(7 downto 0);
b : in std_logic_vector(7 downto 0);
clk : in std_logic;
wr : in std_logic;
rd : in std_logic;
s : in std_logic_vector(2 downto 0);
modeselect : in std_logic; -- Signed operation / Unsigned operation.
addra : in natural range 0 to 15; -- Address at which input a is stored.
addrb : in natural range 0 to 15; -- Address at which input b is stored.
addroh : in natural range 0 to 15; -- Address at which higher bits of output O is stored.
addrol : in natural range 0 to 15 ;-- Address at which lower bits of output O is stored.
o : out std_logic_vector(15 downto 0);
overflow : out std_logic;
zeroflg : out std_logic;
cyflg : out std_logic);
end entity;

architecture driver of driver8bit is
subtype regis is std_logic_vector(7 downto 0);
type memory is array(15 downto 0) of regis;

signal i : std_logic_vector(8 downto 0);
signal y : std_logic_vector(8 downto 0);
signal z : std_logic_vector(8 downto 0);
signal aluor : std_logic_vector(15 downto 0);
signal k : std_logic_vector(15 downto 0);

signal addregisa : natural range 15 downto 0;
signal addregisb : natural range 15 downto 0;
signal ram : memory;

procedure div4( -- Division procedure Starts
numer : in std_logic_vector(7 downto 0);
denom : in std_logic_vector(3 downto 0);
quotient : out std_logic_vector(3 downto 0);
remainder : out std_logic_vector(3 downto 0)) is
variable d,n1: std_logic_vector(4 downto 0);
variable n2: std_logic_vector(3 downto 0);
begin
d := '0' & denom;
n2 := numer(3 downto 0);
n1 := '0' & numer(7 downto 4);
for i in 0 to 3 loop
     n1 := n1(3 downto 0) & n2(3);
	  n2 := n2(2 downto 0) & '0';
	  if n1 >= d then
	         n1 := n1 - d;
				n2(0) := '1';
		end if;		
end loop;
quotient := n2;
remainder := n1(3 downto 0);
end procedure;	-- Division Procedure Ends

begin
process(clk,b,s)
variable remH,remL,quotL,quotH: std_logic_vector(3 downto 0);
variable pv,bp : std_logic_vector(15 downto 0);
variable pvs,bps : std_logic_vector(13 downto 0);
begin


if (rising_edge(clk)) then
if (wr = '1') then
ram(addra) <= a;
ram(addrb) <= b;
end if;

addregisa <= addroh;
addregisb <= addroh;

-- Mode Select 
if(modeselect = '1') then

if (a(7) = '0' and b(7) = '0') then 
if s = "000" then -- Addition
i <= ('0' & ram(addra)) + ('0' & ram(addrb));
aluor <= "0000000" & i;

if i(8) = '1' then
cyflg <= '1';
else
cyflg <= '0';
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

if ram(addra) > 0 and ram(addrb) > 0 then -- Overflow Check

if i < 0 then -- For negative overflow
overflow <= '1';
else
overflow <= '0';
end if;

elsif ram(addra) < 0 and ram(addrb) < 0 then

if i > 0 then -- For positive overflow
overflow <= '1';
else
overflow <= '0';
end if;
end if;


elsif s = "001" then -- And
i <= ('0' & ram(addra)) and ('0' & ram(addrb));
aluor <= "0000000" & i;
cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "010" then -- OR
i <= ('0' & ram(addra)) or ('0' & ram(addrb));
aluor <= "0000000" & i;
cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "011" then -- Xor
i <= ('0' & ram(addra)) xor ('0' & ram(addrb));
aluor <= "0000000" & i;
cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "100" then -- Sub
i <= ('0' & ram(addra)) - ('0' & ram(addrb));
aluor <= "0000000" & i;

y <= ('0' & not(ram(addrb))) + '1';
z <= ('0' & ram(addra)) + y;

if z(8) = '1' then
cyflg <= '1';
else
cyflg <= '0';
end if;

if ram(addra) > ram(addrb) then -- Overflow Check 1
if i < 0 then
overflow <= '1';
else 
overflow <= '0';
end if;
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "101" then -- Multiply
pv := "0000000000000000";
bp := "00000000" & ram(addrb);
for i in 0 to 7 loop
     if ram(addra)(i) = '1' then
	  pv := pv + bp;
	  end if;
	  bp := bp(14 downto 0) & '0';
	  end loop;
	  aluor <= pv;
	  cyflg <= '0';
	  if pv = "0000000000000000" then
	  zeroflg <= '1';
	  else 
	  zeroflg <= '0';
	  end if;
	  overflow <= '0';

elsif s = "110" then -- division

div4("0000" & ram(addra)(7 downto 4),ram(addrb)(3 downto 0),quotH,remH);
div4(remH & ram(addra)(3 downto 0),ram(addrb)(3 downto 0),quotL,remL);

aluor(15 downto 8) <= "00000000";
aluor(7 downto 4) <= quotH;
aluor(3 downto 0) <= quotL;
--	 remainder <= remL
zeroflg <= '0';
overflow <= '0';
cyflg <= '0';
	 
end if;

elsif(a(7) = '0' and b(7) = '1') then
if s = "000" then -- Addition
i <= ("00" & ram(addra)(6 downto 0)) - ("00" & ram(addrb)(6 downto 0));
aluor <= "00000000" & i(7 downto 0);


y <= ("00" & not(ram(addrb)(6 downto 0))) + '1';
z <= ("00" & ram(addra)(6 downto 0)) + y;

if z(7) = '1' then
cyflg <= '1';
else
cyflg <= '0';
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

if ram(addrb)(6 downto 0) > ram(addra)(6 downto 0) then -- Overflow Check
if i < 0 then
overflow <= '1';
else
overflow <= '0';
end if;
end if;

elsif s = "001" then -- And
i <= ('0' & ram(addra)) and ('0' & ram(addrb));
aluor <= "0000000" & i;

cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "010" then -- OR
i <= ('0' & ram(addra)) or ('0' & ram(addrb));
aluor <= "0000000" & i;

cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "011" then -- Xor
i <= ('0' & ram(addra)) xor ('0' & ram(addrb));
aluor <= "0000000" & i;

cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "100" then -- Sub ---Done
i <= ("00" & ram(addra)(6 downto 0)) + ("00" & ram(addrb)(6 downto 0));
aluor <= "0000000" & i;


if i(7) = '1' then -- carryflag
cyflg <= '1';
else
cyflg <= '0';
end if;

if ram(addra)(6 downto 0) > 0 and ram(addrb)(6 downto 0) > 0 then -- overflow
if((ram(addra)(6 downto 0) + ram(addrb)(6 downto 0)) < 0) then
overflow <= '1';
else
overflow <= '0';
end if;
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "101" then -- Multiply 
pvs := "00000000000000";-- Error was here
bps := "0000000" & ram(addrb)(6 downto 0);

for i in 0 to 6 loop
     if ram(addra)(i) = '1' then
	  pvs := pvs + bps;
	  end if;
	  bps := bps(12 downto 0) & '0';
	  end loop;
	  if(ram(addra)(7) = ram(addrb)(7)) then
	  k <= ("00" & pvs);
	  else
	  k <= ("10" & pvs);
	  end if;
	  
	  aluor <= k;
	 
	  
	  cyflg <= '0'; -- Carry Flag
	  
	  if pvs = "00000000000000" then -- Zeroflag
	  zeroflg <= '0';
	  else
	  zeroflg <= '1';
	  end if;
	  
	  	  
	  if(ram(addra)(7) = ram(addrb)(7)) then --  Overflowflag
	  if(k(14) = '1') then
	  overflow <= '1';
	  else
	  overflow <= '0';
	  end if;
	  end if;
elsif s = "110" then -- division

div4("0000" & ram(addra)(7 downto 4),ram(addrb)(3 downto 0),quotH,remH);
div4(remH & ram(addra)(3 downto 0),ram(addrb)(3 downto 0),quotL,remL);

aluor(15 downto 8) <= "10000000";
aluor(7 downto 4) <= quotH;
aluor(3 downto 0) <= quotL;

--	 remainder <= remL
zeroflg <= '0';
overflow <= '0';
cyflg <= '0';	  
	  

end if;




elsif(a(7) = '1' and b(7) = '0') then
if s = "000" then -- Addition
i <= ("00" & ram(addrb)(6 downto 0)) - ("00" & ram(addra)(6 downto 0));
aluor <= "00000000" & i(7 downto 0);


y <= ("00" & not(ram(addra)(6 downto 0))) + '1';
z <= ("00" & ram(addrb)(6 downto 0)) + y;

if z(7) = '1' then
cyflg <= '1';
else
cyflg <= '0';
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

if ram(addrb)(6 downto 0) > ram(addra)(6 downto 0) then -- Overflow Check
if i < 0 then
overflow <= '1';
else
overflow <= '0';
end if;
end if;

elsif s = "001" then -- And
i <= ('0' & ram(addra)) and ('0' & ram(addrb));
aluor <= "0000000" & i;

cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "010" then -- OR
i <= ('0' & ram(addra)) or ('0' & ram(addrb));
aluor <= "0000000" & i;

cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "011" then -- Xor
i <= ('0' & ram(addra)) xor ('0' & ram(addrb));
aluor <= "0000000" & i;

cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "100" then -- Sub ---Done
i <= ("00" & ram(addra)(6 downto 0)) + ("00" & ram(addrb)(6 downto 0));
aluor <= "1000000" & i;


if i(7) = '1' then -- carryflag
cyflg <= '1';
else
cyflg <= '0';
end if;

if ram(addra)(6 downto 0) < 0 and ram(addrb)(6 downto 0) < 0 then -- overflow
if((ram(addra)(6 downto 0) + ram(addrb)(6 downto 0)) > 0) then
overflow <= '1';
else
overflow <= '0';
end if;
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "101" then -- Multiply
pvs := "00000000000000";
bps := "0000000" & ram(addrb)(6 downto 0);

for i in 0 to 6 loop
     if ram(addra)(i) = '1' then
	  pvs := pvs + bps;
	  end if;
	  bps := bps(12 downto 0) & '0';
	  end loop;
	  if(ram(addra)(7) = ram(addrb)(7)) then
	  k <= ("00" & pvs);
	  else
	  k <= ("01" & pvs);
	  end if;
	  
	  aluor <= k;
	  
	  
	  
	  cyflg <= '0'; -- Carry Flag
	  
	  if pvs = "00000000000000" then -- Zeroflag
	  zeroflg <= '0';
	  else
	  zeroflg <= '1';
	  end if;
	  
	  	  
	  if(ram(addra)(7) = ram(addrb)(7)) then --  Overflowflag
	  if(k(14) = '1') then
	  overflow <= '1';
	  else
	  overflow <= '0';
	  end if;
	  end if;
elsif s = "110" then -- division

div4("0000" & ram(addra)(7 downto 4),ram(addrb)(3 downto 0),quotH,remH);
div4(remH & ram(addra)(3 downto 0),ram(addrb)(3 downto 0),quotL,remL);

aluor(15 downto 8) <= "10000000";
aluor(7 downto 4) <= quotH;
aluor(3 downto 0) <= quotL;

--	 remainder <= remL
zeroflg <= '0';
overflow <= '0';
cyflg <= '0';	  
 
end if;



elsif(a(7) = '1' and b(7) = '1') then
if s = "000" then -- Addition
i <= ("00" & ram(addra)(6 downto 0)) + ("00" & ram(addrb)(6 downto 0));
aluor <= "10000000" & i(7 downto 0);


if i(7) = '1' then
cyflg <= '1';
else
cyflg <= '0';
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

if i(7) = '0' then -- Overflow Check not possible because of signed criteria
overflow <= '1';
else
overflow <= '0';
end if;

elsif s = "001" then -- And
i <= ('0' & ram(addra)) and ('0' & ram(addrb));
aluor <= "0000000" & i;

cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "010" then -- OR
i <= ('0' & ram(addra)) or ('0' & ram(addrb));
aluor <= "0000000" & i;

cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "011" then -- Xor
i <= ('0' & ram(addra)) xor ('0' & ram(addrb));
aluor <= "0000000" & i;

cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "100" then -- Sub
i <= ("00" & ram(addrb)(6 downto 0)) - ("00" & ram(addra)(6 downto 0));
aluor <= "0000000" & i;


y <= ("00" & not(ram(addra)(6 downto 0))) + '1';
z <= ("00" & ram(addrb)(6 downto 0)) + y;

if z(7) = '1' then
cyflg <= '1';
else
cyflg <= '0';
end if;

if ram(addrb)(6 downto 0) > ram(addra)(6 downto 0) then-- Overflow Check 1
if (ram(addrb)(6 downto 0) - ram(addra)(6 downto 0)) < 0 then
overflow <= '1';
else 
overflow <= '0';
end if;
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "101" then -- Multiply
pvs := "00000000000000";
bps := "0000000" & ram(addrb)(6 downto 0);

for i in 0 to 6 loop
     if ram(addra)(i) = '1' then
	  pvs := pvs + bps;
	  end if;
	  bps := bps(12 downto 0) & '0';
	  end loop;
	  if(ram(addra)(7) = ram(addrb)(7)) then
	  k <= ("00" & pvs);
	  else
	  k <= ("10" & pvs);
	  end if;
	  
	  aluor <= k;
	  
	  
	  cyflg <= '0'; -- Carry Flag
	  
	  if pvs = "00000000000000" then -- Zeroflag
	  zeroflg <= '0';
	  else
	  zeroflg <= '1';
	  end if;
	  
	  	  
	  if(ram(addra)(7) = ram(addrb)(7)) then --  Overflowflag
	  if(k(14) = '1') then
	  overflow <= '1';
	  else
	  overflow <= '0';
	  end if;
	  end if;
	  
	  
elsif s = "110" then -- division

div4("0000" & ram(addra)(7 downto 4),ram(addrb)(3 downto 0),quotH,remH);
div4(remH & ram(addra)(3 downto 0),ram(addrb)(3 downto 0),quotL,remL);

aluor(15 downto 8) <= "00000000";
aluor(7 downto 4) <= quotH;
aluor(3 downto 0) <= quotL;

--	 remainder <= remL
zeroflg <= '0';
overflow <= '0';
cyflg <= '0';	  
	  	  
	  

end if;
-- ALU ENDS for signed 
end if;


elsif(modeselect = '0') then
-- Alu for unsigned starts here.
-- A = '0' and B = '0'
if s = "000" then -- Addition
i <= ('0' & ram(addra)) + ('0' & ram(addrb));
aluor <= "0000000" & i;

if i(8) = '1' then
cyflg <= '1';
else
cyflg <= '0';
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

if ram(addra) > 0 and ram(addrb) > 0 then -- Overflow Check

if i < 0 then -- For negative overflow
overflow <= '1';
else
overflow <= '0';
end if;

elsif ram(addra) < 0 and ram(addrb) < 0 then

if i > 0 then -- For positive overflow
overflow <= '1';
else
overflow <= '0';
end if;
end if;


elsif s = "001" then -- And
i <= ('0' & ram(addra)) and ('0' & ram(addrb));
aluor <= "0000000" & i;
cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "010" then -- OR
i <= ('0' & ram(addra)) or ('0' & ram(addrb));
aluor <= "0000000" & i;
cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "011" then -- Xor
i <= ('0' & ram(addra)) xor ('0' & ram(addrb));
aluor <= "0000000" & i;
cyflg <= i(8);
overflow <= '0';
if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "100" then -- Sub
i <= ('0' & ram(addra)) - ('0' & ram(addrb));
aluor <= "0000000" & i;

y <= ('0' & not(ram(addrb))) + '1';
z <= ('0' & ram(addra)) + y;

if z(8) = '1' then
cyflg <= '1';
else
cyflg <= '0';
end if;

if ram(addra) > ram(addrb) then -- Overflow Check 1
if i < 0 then
overflow <= '1';
else 
overflow <= '0';
end if;
end if;

if i = "000000000" then -- Zero Check
zeroflg <= '1';
else
zeroflg <= '0';
end if;

elsif s = "101" then -- Multiply
pv := "0000000000000000";
bp := "00000000" & ram(addrb);
for i in 0 to 7 loop
     if ram(addra)(i) = '1' then
	  pv := pv + bp;
	  end if;
	  bp := bp(14 downto 0) & '0';
	  end loop;
	  aluor <= pv;
	  cyflg <= '0';
	  if pv = "0000000000000000" then
	  zeroflg <= '1';
	  else 
	  zeroflg <= '0';
	  end if;
	  overflow <= '0';

elsif s = "110" then -- division

div4("0000" & ram(addra)(7 downto 4),ram(addrb)(3 downto 0),quotH,remH);
div4(remH & ram(addra)(3 downto 0),ram(addrb)(3 downto 0),quotL,remL);

aluor(15 downto 8) <= "00000000";
aluor(7 downto 4) <= quotH;
aluor(3 downto 0) <= quotL;
--	 remainder <= remL
zeroflg <= '0';
overflow <= '0';
cyflg <= '0';
	 
end if;
-- Alu for unsigned starts here.
else
o <= null;
end if;


ram(addregisa) <= aluor(15 downto 8);
ram(addregisb) <= aluor(7 downto 0);

--if (rising_edge(clk)) then
if(rd = '1') then
o(15 downto 8) <= ram(addregisa);
o(7 downto 0) <= ram(addregisb);
end if;
end if;

end process;
end driver;












