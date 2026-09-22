@echo off
rem Double-click to open the GravelMaster website preview with the new header, footer, homepage and category page.
rem Keep this window open while you use the preview; close it to stop the preview.
title GravelMaster website preview
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0preview\tools\site-preview.ps1" %*
if errorlevel 1 pause
