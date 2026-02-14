@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\rescli.ps1" config
exit