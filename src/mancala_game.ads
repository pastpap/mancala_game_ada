-- mancala_game.ads

package Mancala_Game is

   Board_Size      : constant Natural := 14;
   Pebbles_Per_Pit : constant Natural := 6;

   type Board_Array is array (Natural range <>) of Natural;

   type Mancala_Game_Type is record
      Board       : Board_Array (0 .. Board_Size - 1);
      Last_Player : Natural;
   end record;

   procedure Initialize (Game : out Mancala_Game_Type);
   procedure Reset_Board (Game : out Mancala_Game_Type);
   procedure Play_Hand
     (Game : in out Mancala_Game_Type; Position : Natural);
   function Is_Finished (Game : Mancala_Game_Type) return Boolean;
   function Get_Winning_Player (Game : Mancala_Game_Type) return Integer;
   function Get_Winning_Player_Score (Game : Mancala_Game_Type) return Integer;
   function Get_Player_One_Total_Pebbles
     (Game : Mancala_Game_Type) return Natural;
   function Get_Player_Two_Total_Pebbles
     (Game : Mancala_Game_Type) return Natural;
   function Next_Player (Game : Mancala_Game_Type) return Natural;

   -- Additional helper functions
   function Get_Player_One_Live_Pebbles
     (Game : Mancala_Game_Type) return Natural;
   function Get_Player_Two_Live_Pebbles
     (Game : Mancala_Game_Type) return Natural;
   procedure Validate_Hand_Start_Position
     (Game : Mancala_Game_Type; Position : Natural);
   function Distribute_Pebbles
     (Game : in out Mancala_Game_Type; Position : Natural) return Natural;
   function Add_One_Pebble_To_The_Next_Available_Pit
     (Game : in out Mancala_Game_Type; Current_Position : in out Natural)
      return Natural;
   function Advance_Current_Position
     (Game : Mancala_Game_Type; Current_Position : in out Natural)
      return Natural;
   function Handle_Moving_To_The_Start_Of_The_Board_When_Last_Index_Reached
     (Current_Position : Natural) return Natural;
   function Handle_Jumping_Over_Opponents_Mancala
     (Game : Mancala_Game_Type; Current_Position : Natural) return Natural;
   procedure Try_Capturing_Enemy_Position
     (Game : in out Mancala_Game_Type; Current_Position : Natural);
   procedure Capture_From_Position_To_Mancala
     (Game    : in out Mancala_Game_Type; Current_Position : Natural;
      Mancala :        Natural);
   procedure Change_Turns
     (Game : in out Mancala_Game_Type; Current_Position : Natural);
   function Is_Player_Own_Pit
     (Game : Mancala_Game_Type; Current_Position : Natural) return Boolean;
   function Is_Player_One (Game : Mancala_Game_Type) return Boolean;
   function Is_Player_Two (Game : Mancala_Game_Type) return Boolean;

end Mancala_Game;
