-- File: mancala_game_controller.adb
with AWS.Server;
with AWS.Status;
with AWS.Response;
with AWS.Messages;
with Mancala_Game_Service; use Mancala_Game_Service;

package body Mancala_Game_Controller is

   procedure Play_Hand_Handler(Request : AWS.Status.Data) is
      Position : constant Natural := Natural'Value(AWS.Messages.Get(Request, "position"));
      State    : Mancala_Game_State;
   begin
      -- Parse the request body to get the game state
      -- Call the service layer to play the hand
      Play_Hand(Position, State);
      -- Send the response with the updated game state
      AWS.Response.Build(Request, AWS.Status.OK, State);
   end Play_Hand_Handler;

   procedure Reset_Game_Handler(Request : AWS.Status.Data) is
      State : constant Mancala_Game_State := Reset_Game;
   begin
      -- Send the response with the reset game state
      AWS.Response.Build(Request, AWS.Status.OK, State);
   end Reset_Game_Handler;

   procedure Start_Server is
   begin
      AWS.Server.Start(
         Name        => "MancalaGameServer",
         Port        => 8080,
         Dispatchers => (
            1 => (Method => AWS.Status.POST, Path => "/v1/play", Handler => Play_Hand_Handler'Access),
            2 => (Method => AWS.Status.GET, Path => "/v1/reset", Handler => Reset_Game_Handler'Access)
         )
      );
   end Start_Server;

end Mancala_Game_Controller;
