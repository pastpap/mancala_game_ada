package body Mancala_Game is

   Player_One_ID : constant Natural := 0;
   Player_Two_ID : constant Natural := 1;

   procedure Initialize (Game : out Mancala_Game_Type) is
   begin
      Game.Board := (others => Pebbles_Per_Pit);
      Game.Board (6) := 0; -- Player One's Mancala
      Game.Board (13) := 0; -- Player Two's Mancala
      Game.Last_Player := Player_Two_ID;
   end Initialize;

   procedure Reset_Board (Game : out Mancala_Game_Type) is
   begin
      Initialize (Game);
   end Reset_Board;

   procedure Play_Hand (Game : in out Mancala_Game_Type; Position : Natural) is
      Current_Position : Natural;
   begin
      if not Is_Finished (Game) then
         Validate_Hand_Start_Position (Game, Position);
         Current_Position := Distribute_Pebbles (Game, Position);
         if Game.Board (Current_Position) = 1
           and then Is_Player_Own_Pit (Game, Current_Position)
         then
            Try_Capturing_Enemy_Position (Game, Current_Position);
         end if;
         Change_Turns (Game, Current_Position);
      end if;
   end Play_Hand;

   function Is_Finished (Game : Mancala_Game_Type) return Boolean is
   begin
      return
        Get_Player_One_Live_Pebbles (Game) = 0
        or Get_Player_Two_Live_Pebbles (Game) = 0;
   end Is_Finished;

   function Get_Winning_Player (Game : Mancala_Game_Type) return Integer is
   begin
      if Is_Finished (Game) then
         if Get_Player_One_Total_Pebbles (Game)
           > Get_Player_Two_Total_Pebbles (Game)
         then
            return Player_One_ID;
         elsif Get_Player_Two_Total_Pebbles (Game)
           > Get_Player_One_Total_Pebbles (Game)
         then
            return Player_Two_ID;
         else
            return -1; -- It's a tie
         end if;
      else
         return -1; -- Game not finished
      end if;
   end Get_Winning_Player;

   function Get_Winning_Player_Score (Game : Mancala_Game_Type) return Integer
   is
   begin
      if Is_Finished (Game) then
         if Get_Winning_Player (Game) = Player_One_ID then
            return Get_Player_One_Total_Pebbles (Game);
         elsif Get_Winning_Player (Game) = Player_Two_ID then
            return Get_Player_Two_Total_Pebbles (Game);
         else
            return -1; -- It's a tie
         end if;
      else
         return -1; -- Game not finished
      end if;
   end Get_Winning_Player_Score;

   function Get_Player_One_Total_Pebbles
     (Game : Mancala_Game_Type) return Natural is
   begin
      return Get_Player_One_Live_Pebbles (Game) + Game.Board (6);
   end Get_Player_One_Total_Pebbles;

   function Get_Player_Two_Total_Pebbles
     (Game : Mancala_Game_Type) return Natural is
   begin
      return Get_Player_Two_Live_Pebbles (Game) + Game.Board (13);
   end Get_Player_Two_Total_Pebbles;

   function Next_Player (Game : Mancala_Game_Type) return Natural is
   begin
      if Game.Last_Player = Player_One_ID then
         return Player_Two_ID;
      else
         return Player_One_ID;
      end if;
   end Next_Player;

   function Get_Player_One_Live_Pebbles
     (Game : Mancala_Game_Type) return Natural
   is
      Sum : Natural := 0;
   begin
      for I in 0 .. 5 loop
         Sum := Sum + Game.Board (I);
      end loop;
      return Sum;
   end Get_Player_One_Live_Pebbles;

   function Get_Player_Two_Live_Pebbles
     (Game : Mancala_Game_Type) return Natural
   is
      Sum : Natural := 0;
   begin
      for I in 7 .. 12 loop
         Sum := Sum + Game.Board (I);
      end loop;
      return Sum;
   end Get_Player_Two_Live_Pebbles;

   procedure Validate_Hand_Start_Position
     (Game : Mancala_Game_Type; Position : Natural) is
   begin
      if Position not in 0 .. Board_Size - 1 then
         raise Program_Error with "Cannot start hand from outside the board";
      elsif Position = 6 or Position = 13 then
         raise Program_Error with "Cannot start hand from a Mancala pit";
      elsif Game.Board (Position) = 0 then
         raise Program_Error with "Cannot start hand from empty pit";
      elsif not Is_Player_Own_Pit (Game, Position) then
         raise Program_Error with "Cannot start hand from opponent's pits";
      end if;
   end Validate_Hand_Start_Position;

   function Distribute_Pebbles
     (Game : in out Mancala_Game_Type; Position : Natural) return Natural
   is
      Start_Pebbles    : Natural;
      Current_Position : Natural;
   begin
      Start_Pebbles := Game.Board (Position);
      Game.Board (Position) := 0;
      Current_Position := Position;
      while Start_Pebbles > 0 loop
         Current_Position :=
           Add_One_Pebble_To_The_Next_Available_Pit (Game, Current_Position);
         Start_Pebbles := Start_Pebbles - 1;
      end loop;
      return Current_Position;
   end Distribute_Pebbles;

   function Add_One_Pebble_To_The_Next_Available_Pit
     (Game : in out Mancala_Game_Type; Current_Position : in out Natural)
      return Natural is
   begin
      Current_Position := Advance_Current_Position (Game, Current_Position);
      Game.Board (Current_Position) := Game.Board (Current_Position) + 1;
      return Current_Position;
   end Add_One_Pebble_To_The_Next_Available_Pit;

   function Advance_Current_Position
     (Game : Mancala_Game_Type; Current_Position : in out Natural)
      return Natural is
   begin
      Current_Position :=
        Handle_Moving_To_The_Start_Of_The_Board_When_Last_Index_Reached
          (Current_Position);
      Current_Position :=
        Handle_Jumping_Over_Opponents_Mancala (Game, Current_Position);
      return Current_Position;
   end Advance_Current_Position;

   function Handle_Moving_To_The_Start_Of_The_Board_When_Last_Index_Reached
     (Current_Position : Natural) return Natural is
   begin
      if Current_Position < Board_Size - 1 then
         return Current_Position + 1;
      else
         return 0;
      end if;
   end Handle_Moving_To_The_Start_Of_The_Board_When_Last_Index_Reached;

   function Handle_Jumping_Over_Opponents_Mancala
     (Game : Mancala_Game_Type; Current_Position : Natural) return Natural is
   begin
      if Is_Player_One (Game) and Current_Position = 13 then
         return 0;
      elsif Is_Player_Two (Game) and Current_Position = 6 then
         return Current_Position + 1;
      else
         return Current_Position;
      end if;
   end Handle_Jumping_Over_Opponents_Mancala;

   procedure Try_Capturing_Enemy_Position
     (Game : in out Mancala_Game_Type; Current_Position : Natural) is
   begin
      if Is_Player_One (Game)
        and Current_Position in 0 .. 5
        and Game.Board (Current_Position) = 1
      then
         Capture_From_Position_To_Mancala (Game, Current_Position, 6);
      elsif Is_Player_Two (Game)
        and Current_Position in 7 .. 12
        and Game.Board (Current_Position) = 1
      then
         Capture_From_Position_To_Mancala (Game, Current_Position, 13);
      end if;
   end Try_Capturing_Enemy_Position;

   procedure Capture_From_Position_To_Mancala
     (Game             : in out Mancala_Game_Type;
      Current_Position : Natural;
      Mancala          : Natural) is
   begin
      Game.Board (Mancala) :=
        Game.Board (Mancala)
        + Game.Board (Current_Position)
        + Game.Board (Board_Size - 2 - Current_Position);
      Game.Board (Current_Position) := 0;
      Game.Board (Board_Size - 2 - Current_Position) := 0;
   end Capture_From_Position_To_Mancala;

   procedure Change_Turns
     (Game : in out Mancala_Game_Type; Current_Position : Natural) is
   begin
      if (Is_Player_One (Game) and Current_Position /= 6)
        or (Is_Player_Two (Game) and Current_Position /= 13)
      then
         Game.Last_Player := Next_Player (Game);
      end if;
   end Change_Turns;

   function Is_Player_Own_Pit
     (Game : Mancala_Game_Type; Current_Position : Natural) return Boolean is
   begin
      return
        (Is_Player_One (Game) and Current_Position in 0 .. 5)
        or (Is_Player_Two (Game) and Current_Position in 7 .. 12);
   end Is_Player_Own_Pit;

   function Is_Player_One (Game : Mancala_Game_Type) return Boolean is
   begin
      return Next_Player (Game) = Player_One_ID;
   end Is_Player_One;

   function Is_Player_Two (Game : Mancala_Game_Type) return Boolean is
   begin
      return not Is_Player_One (Game);
   end Is_Player_Two;

end Mancala_Game;
