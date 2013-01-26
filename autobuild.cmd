@ECHO OFF
IF [%1]==[] GOTO startAutobuilds

title autobuild %1
coffee -o %1/js/ -j app_%1.coffee -cw src/%1
GOTO end

:startAutobuilds
START CMD /C CALL autobuild.cmd server
START CMD /C CALL autobuild.cmd client

:end