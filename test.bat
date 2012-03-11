
REM enumerate sound cards
java -cp bin                            ^
  -Denumerate                           ^
  sivantoledo.ax25.Test

REM loopback test
java -cp bin                            ^
  -Drate=48000                          ^
  -Dloopback                            ^
  -Dcallsign=4X6IZ-9                    ^
  sivantoledo.ax25.Test
  
REM write the samples of a generated packet to a file
java -cp bin                            ^
  -Drate=48000                          ^
  -Dfile-output="xxx.txt"               ^
  -Dcallsign=4X6IZ-9                    ^
  sivantoledo.ax25.Test
  
REM send a test packet
java -cp bin                            ^
  -Drate=48000                          ^
  -Doutput="Conexant HD Audio output"   ^
  -Dcallsign=4X6IZ-9                    ^
  sivantoledo.ax25.Test

REM receive packets with audio-level indication
java -cp bin                            ^
  -Drate=48000                          ^
  -Daudio-level                         ^
  -Dinput="Conexant HD Audio input"     ^
  sivantoledo.ax25.Test
  
REM receive packets
java -cp bin                            ^
  -Drate=48000                          ^
  -Dinput="Conexant HD Audio input"     ^
  sivantoledo.ax25.Test