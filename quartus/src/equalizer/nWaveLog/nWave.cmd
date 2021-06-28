wvResizeWindow -win $_nWave1 0 0 1326 533
wvResizeWindow -win $_nWave1 0 0 1326 533
wvResizeWindow -win $_nWave1 0 0 1801 846
wvResizeWindow -win $_nWave1 146 49 1825 858
wvRestoreSignal -win $_nWave1 \
           "/home/raid7_2/userb06/b06165/test/equalizer/tb/signal.rc" \
           -overWriteAutoAlias on -appendSignals on
wvResizeWindow -win $_nWave1 50 0 1381 776
wvResizeWindow -win $_nWave1 50 0 1941 1046
wvResizeWindow -win $_nWave1 50 0 1943 1046
wvDisplayGridCount -win $_nWave1 -off
wvGetSignalClose -win $_nWave1
wvReloadFile -win $_nWave1
wvSetCursor -win $_nWave1 22084.143415 -snap {("G1" 4)}
wvSetCursor -win $_nWave1 17912.474426 -snap {("G1" 23)}
wvSetCursor -win $_nWave1 22084.143415 -snap {("G1" 23)}
wvSetCursor -win $_nWave1 13029.051487 -snap {("G1" 4)}
wvSelectSignal -win $_nWave1 {( "G1" 2 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvSelectSignal -win $_nWave1 {( "G1" 8 )} 
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvSelectSignal -win $_nWave1 {( "G1" 6 )} 
wvSelectSignal -win $_nWave1 {( "G1" 7 )} 
wvSelectSignal -win $_nWave1 {( "G1" 8 )} 
wvSelectSignal -win $_nWave1 {( "G1" 10 )} 
wvSetCursor -win $_nWave1 12000.962447 -snap {("G1" 4)}
wvSetCursor -win $_nWave1 13048.822430 -snap {("G1" 4)}
wvSetCursor -win $_nWave1 12989.509601 -snap {("G1" 7)}
wvSetCursor -win $_nWave1 23092.461512 -snap {("G1" 8)}
wvSetCursor -win $_nWave1 26689.657205 -snap {("G1" 9)}
wvSetCursor -win $_nWave1 26709.428148 -snap {("G1" 7)}
wvSetCursor -win $_nWave1 23051.803679 -snap {("G1" 8)}
wvSelectSignal -win $_nWave1 {( "G1" 11 )} 
