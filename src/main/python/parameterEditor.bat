set PROJECT_DRIVE=%1
set PROJECT_DIRECTORY=%2

%PROJECT_DRIVE%
set "SCEN_DIR=%PROJECT_DRIVE%%PROJECT_DIRECTORY%"
set OLDPYTHONPATH=%PYTHONPATH%
set PYTHONPATH=%OLDPYTHONPATH%;%SCEN_DIR%\python
python.exe %SCEN_DIR%\python\sandag\pythonGUI\parameterEditor.py %SCEN_DIR%
set PYTHONPATH=%OLDPYTHONPATH%