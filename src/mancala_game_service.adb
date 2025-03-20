-- File: mancala_game_service.adb

package body Mancala_Game_Service is

   Game : Mancala_Game_Type;

   function Calculate_Last_Player (Turn_Player : Natural) return Natural is
   begin
      return (if Turn_Player = 0 then 1 else 0);
   end Calculate_Last_Player;

   function Map_Mancala_Game_To_State
     (Game : Mancala_Game_Type) return Mancala_Game_State
   is
      Winner_Id : Integer := Get_Winning_Player (Game);
   begin
      return
        Mancala_Game_State'
          (Board                => Game.Board,
           Turn_Player          => Next_Player (Game),
           Is_Finished          => Is_Finished (Game),
           Winning_Player       => Winner_Id,
           Winning_Player_Score =>
             (if Winner_Id = 0 then Get_Player_One_Total_Pebbles (Game)
              elsif Winner_Id = 1 then Get_Player_Two_Total_Pebbles (Game)
              else -1),
           Message              => [others => ' ']);
   end Map_Mancala_Game_To_State;

   function Get_Message_About_Winner_And_Score
     (State : Mancala_Game_State) return String is
   begin
      return
        (if State.Winning_Player = 0 then "Player One" else "Player Two")
        & " won with "
        & Natural'Image (State.Winning_Player_Score)
        & " pebbles";
   end Get_Message_About_Winner_And_Score;

   procedure Play_Hand (Position : Natural; State : in out Mancala_Game_State)
   is
   begin
      Game.Board := State.Board;
      Game.Last_Player := Calculate_Last_Player (State.Turn_Player);
      begin
         Mancala_Game.Play_Hand (Game, Position);
      exception
         when others =>
            State.Message := [others => ' '];
            return;
      end;
      State := Map_Mancala_Game_To_State (Game);
      if Is_Finished (Game) then
         State.Message := Get_Message_About_Winner_And_Score (State);
      end if;
   end Play_Hand;

   function Reset_Game return Mancala_Game_State is
   begin
      Mancala_Game.Reset_Board (Game);
      return Map_Mancala_Game_To_State (Game);
   end Reset_Game;

end Mancala_Game_Service;
