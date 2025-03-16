
-- mancala_game_controller.adb
with AWS.Server;
with AWS.Status;
with AWS.Response;
with AWS.Parameters;
with AWS.Messages;
with Mancala_Game_Service; use Mancala_Game_Service;

package body Mancala_Game_Controller is

   Srv : AWS.Server.HTTP;

   function Escape_JSON (S : String) return String is
      Result : String (1 .. S'Length * 2) := (others => ' ');
      Pos    : Natural := 1;
   begin
      for C of S loop
         if C = '"' then
            Result(Pos)     := '\';
            Result(Pos + 1) := '"';
            Pos := Pos + 2;
         elsif C = '\' then
            Result(Pos)     := '\';
            Result(Pos + 1) := '\';
            Pos := Pos + 2;
         else
            Result(Pos) := C;
            Pos := Pos + 1;
         end if;
      end loop;
      return Result(1 .. Pos - 1);
   end Escape_JSON;

   function Serialize_State (State : Mancala_Game_State) return String is
      Board_JSON : String := "[";
   begin
      -- Serialize board array
      for I in State.Board'Range loop
         Board_JSON := Board_JSON & Natural'Image(State.Board(I));
         if I /= State.Board'Last then
            Board_JSON := Board_JSON & ",";
         end if;
      end loop;
      Board_JSON := Board_JSON & "]";

      -- Compose final JSON string manually
      return
      "{" &
      """board"":" & Board_JSON & "," &
      """turn_player"":" & Natural'Image(State.Turn_Player) & "," &
      """is_finished"":" & Boolean'Image(State.Is_Finished) & "," &
      """winning_player"":" & Integer'Image(State.Winning_Player) & "," &
      """winning_player_score"":" & Natural'Image(State.Winning_Player_Score) & "," &
      """message"":""" & Escape_JSON(State.Message) & """" &
      "}";
   end Serialize_State;


   function Global_Handler (Request : AWS.Status.Data) return AWS.Response.Data is
      URI    : constant String := AWS.Status.URI (Request);
      Method : constant String := AWS.Status.Method (Request);
      Params : AWS.Parameters.List;
      State  : Mancala_Game_State;
   begin
      if Method = "POST" and then URI = "/v1/play" then
         Params := AWS.Status.Parameters (Request);
         declare
            Position : constant Natural := Natural'Value (AWS.Parameters.Get (Params, "position"));
         begin
            Play_Hand (Position, State);
         end;
      elsif Method = "GET" and then URI = "/v1/reset" then
         State := Reset_Game;
      else
         return AWS.Response.Build (
            "application/json",
            "{""error"": ""Route not found""}",
            AWS.Messages.S404);
      end if;

      declare
         JSON : constant String := Serialize_State (State);
      begin
         return AWS.Response.Build (
            "application/json",
            JSON,
            AWS.Messages.S200);
      end;
   end Global_Handler;

   procedure Start_Server is
   begin
      AWS.Server.Start (
         Srv,
         Callback => Global_Handler'Access,
         Port     => 8888,
         Name     => "Mancala_Server");
   end Start_Server;

end Mancala_Game_Controller;
