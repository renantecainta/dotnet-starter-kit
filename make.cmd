@echo off
REM .NET 10 Project Utility Wrapper
REM Usage: make <target> [options]
REM
REM Run PowerShell script for actual functionality

set TARGET=%~1

powershell -ExecutionPolicy Bypass -File "%~dp0make.ps1" %*