@echo off
chcp 65001
set current_dir=%~dp0
set mode=release
set exe=bin\msvc\%mode%\vaststars.exe
set cachedir=.build
set param=startup/main.lua

pushd %current_dir%
if exist "%cachedir%" (
	rem rd /s /q %cachedir%
)

if not exist "%exe%" (
	set mode=debug
	set exe=bin\msvc\debug\vaststars.exe
)

title %mode% - %current_dir%%exe%
%current_dir%%exe% %param%
popd

pause