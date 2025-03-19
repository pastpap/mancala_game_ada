
-- mancala_game_controller.adb
with Ada.Text_IO; use Ada.Text_IO;
with AWS.Server;
with AWS.Status;
with AWS.Response;
with AWS.Parameters;
with AWS.Messages;
with Ada.Strings.Fixed; -- for Trim
with Ada.Strings; -- for Write
with Ada.Strings.Unbounded; -- for deserialization

with GNATCOLL.JSON;        use GNATCOLL.JSON;
with Mancala_Game_Service; use Mancala_Game_Service;
with Mancala_Game;         use Mancala_Game;
with AWS.Headers;
with AWS.Services.Page_Server;

package body Mancala_Game_Controller is

   Srv        : AWS.Server.HTTP;
   Static_Srv : AWS.Server.HTTP;
   Headers    : AWS.Headers.List;

   function Serialize_State (State : Mancala_Game_State) return String is
      use GNATCOLL.JSON;
      use Ada.Strings;
      use Ada.Strings.Fixed;

      Obj : JSON_Value := Create_Object;
      Arr : JSON_Array := Empty_Array;
   begin
      -- GNATCOLL.JSON base API does allow this
      for I in State.Board'Range loop
         Append (Arr, Create (State.Board (I)));
      end loop;

      -- Populate root JSON object
      Obj.Set_Field ("board", Arr);
      Obj.Set_Field ("turnPlayer", Create (State.Turn_Player));
      Obj.Set_Field ("finished", Create (State.Is_Finished));
      Obj.Set_Field ("winningPlayer", Create (State.Winning_Player));
      Obj.Set_Field
        ("winningPlayerScore", Create (State.Winning_Player_Score));
      Obj.Set_Field ("message", Create (Trim (State.Message, Both)));

      return Write (Obj);
   end Serialize_State;

   function Deserialize_State
     (JSON_Text : Ada.Strings.Unbounded.Unbounded_String)
      return Mancala_Game_State
   is
      use Ada.Strings.Unbounded;
      use GNATCOLL.JSON;
      Obj                  : constant JSON_Value := Read (JSON_Text);
      Board                :
        Mancala_Game.Board_Array (0 .. Mancala_Game.Board_Size - 1) :=
          (others => 1);-- Explicit array bounds
      Turn_Player          : Natural;
      Is_Finished          : Boolean;
      Winning_Player       : Integer;
      Winning_Player_Score : Integer;
      Message              : String (1 .. 256) := (others => ' ');
      String_Element       : String (1 .. 1);
   begin

      -- Check if "turnPlayer" exists and is of the correct type
      if Has_Field (Obj, "turnPlayer")
        and then Get (Obj, "turnPlayer").Kind = JSON_Int_Type
      then
         Turn_Player := Get (Obj, "turnPlayer");
      else
         Put_Line ("Error: 'turnPlayer' key is missing or not an integer.");
         raise Constraint_Error with "'turnPlayer' key is missing or invalid.";
      end if;

      -- Check if "finished" exists and is of the correct type
      if Has_Field (Obj, "finished")
        and then Get (Obj, "finished").Kind = JSON_Boolean_Type
      then
         Is_Finished := Get (Obj, "finished");
      else
         Put_Line ("Error: 'finished' key is missing or not a boolean.");
         raise Constraint_Error with "'finished' key is missing or invalid.";
      end if;

      -- Check if "winningPlayer" exists and is of the correct type
      if Has_Field (Obj, "winningPlayer")
        and then Get (Obj, "winningPlayer").Kind = JSON_Int_Type
      then
         Winning_Player := Get (Obj, "winningPlayer");
      else
         Put_Line ("Error: 'winningPlayer' key is missing or not an integer.");
         raise Constraint_Error
           with "'winningPlayer' key is missing or invalid.";
      end if;

      -- Check if "winningPlayerScore" exists and is of the correct type
      if Has_Field (Obj, "winningPlayerScore")
        and then Get (Obj, "winningPlayerScore").Kind = JSON_Int_Type
      then
         Winning_Player_Score := Get (Obj, "winningPlayerScore");
      else
         Put_Line
           ("Error: 'winningPlayerScore' key is missing or not an integer.");
         raise Constraint_Error
           with "'winningPlayerScore' key is missing or invalid.";
      end if;

      -- Check if "message" exists and is of the correct type
      if Has_Field (Obj, "message")
        and then Get (Obj, "message").Kind = JSON_String_Type
      then
         Message_Record : String := Get (Obj, "message");
         for I in Message_Record'Range loop
            Message (I) := Message_Record (I);
         end loop;
      else
         Put_Line ("Error: 'message' key is missing or not a string.");
         raise Constraint_Error with "'message' key is missing or invalid.";
      end if;

      -- Extract the board values
      if Has_Field (Obj, "board")
        and then Get (Obj, "board").Kind = JSON_Array_Type
      then
         Arr : constant JSON_Array := Get (Obj, "board");
         for I in 0 .. Length (Arr) - 1 loop
            if Get (Arr, I + 1).Kind = JSON_Int_Type then
               Board (I) := Get (Get (Arr, I + 1));
            else
               Put_Line
                 ("Error: 'board' key is missing or not an array of integers.");
               raise Constraint_Error
                 with "'board' key is missing or invalid.";
            end if;
         end loop;
      end if;

      return
        Mancala_Game_State'
          (Board                => Board,
           Turn_Player          => Turn_Player,
           Is_Finished          => Is_Finished,
           Winning_Player       => Winning_Player,
           Winning_Player_Score => Winning_Player_Score,
           Message              => Message);
   end Deserialize_State;

   function Global_Handler (Request : AWS.Status.Data) return AWS.Response.Data
   is

      use Ada.Strings.Unbounded;

      URI      : constant String := AWS.Status.URI (Request);
      Method   : constant String := AWS.Status.Method (Request);
      Body_Str : constant Unbounded_String := AWS.Status.Binary_Data (Request);

      Params : AWS.Parameters.List;
      State  : Mancala_Game_State;
   begin
      AWS.Headers.Add
        (Table => Headers,
         Name  => "Access-Control-Allow-Origin",
         Value => "*");

      if Method = "POST" and then URI = "/v1/play" then
         Params := AWS.Status.Parameters (Request);
         declare
            Position : constant Natural :=
              Natural'Value (AWS.Parameters.Get (Params, "position"));
         begin
            if Position < 0 or else Position > 13 then
               return
                  Result : AWS.Response.Data :=
                    AWS.Response.Build
                      ("application/json",
                       "{""error"": ""Invalid position""}",
                       AWS.Messages.S400)
                    with Headers => Headers;
            end if;
            if AWS.Status.Is_Body_Uploaded (Request) then

               State := Deserialize_State (Body_Str);
            else
               State := Reset_Game;
            end if;
            Play_Hand (Position, State);
         end;
      elsif Method = "GET" and then URI = "/v1/reset" then
         State := Reset_Game;
      else
         return
            Result : AWS.Response.Data :=
              AWS.Response.Build
                ("application/json",
                 "{""error"": ""Route not found""}",
                 AWS.Messages.S404)
              with Headers => Headers;
      end if;

      declare
         JSON : constant String := Serialize_State (State);
      begin
         return
           AWS.Response.Build ("application/json", JSON, AWS.Messages.S200);
      end;
   end Global_Handler;

   procedure Start_Server is
   begin
      AWS.Server.Start
        (Srv,
         Callback => Global_Handler'Access,
         Port     => 8888,
         Name     => "Mancala_API_Server");
   end Start_Server;

   procedure Start_Static_Server is
   begin
      AWS.Server.Start
        (Static_Srv,
         Callback       => AWS.Services.Page_Server.Callback'Access,
         Port           => 8000,
         Name           => "Mancala_Static_Client",
         Max_Connection => 5);
   end Start_Static_Server;

end Mancala_Game_Controller;
