#!/usr/bin/env pwsh
$ErrorActionPreference = "Stop"
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$BuildDir = Join-Path $ScriptDir "build"

cmake -S $ScriptDir -B $BuildDir
cmake --build $BuildDir
& (Join-Path $BuildDir "firmware_tests")
