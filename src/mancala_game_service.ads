-- File: mancala_game_service.ads
package Mancala_Game_Service is

   type Mancala_Game_State is record
      Board       : Mancala_Game.Board_Array;
      Turn_Player : Natural;
      Is_Finished : Boolean;
      Winning_Player : Integer;
      Winning_Player_Score : Natural;
      Message     : String(1..256);
   end record;

   procedure Play_Hand(Position : Natural; State : in out Mancala_Game_State);
   function Reset_Game return Mancala_Game_State;

end Mancala_Game_Service;
