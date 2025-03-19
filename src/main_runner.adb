-- File: main.adb
with Mancala_Game_Controller;

procedure Main_Runner is
begin
   Mancala_Game_Controller.Start_Server;
   Mancala_Game_Controller.Start_Static_Server;
end Main_Runner;
