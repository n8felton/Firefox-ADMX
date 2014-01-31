' Firefox ADMX
' Version 0.1.3
'
' Author: Nathan Felton
'
' Firefox ADMX is a way of allowing centrally managed locked and/or default settings 
' in Firefox via Group Policy and Administrative Templates in Active Directory.
' 
' Firefox ADMX is a continuation of FirefoxADM by Mark Sammons.
' 
' This work is licensed under the Creative Commons Attribution 3.0 Unported License. 
' To view a copy of this license, visit http://creativecommons.org/licenses/by/3.0/

'On Error Resume Next

Dim objShell			:   Set objShell = WScript.CreateObject("WScript.Shell")
Dim objFSO				:	Set objFSO = WScript.CreateObject("Scripting.FileSystemObject")
Dim objEnv				: 	Set objEnv = objShell.Environment("Process")
Dim objWMIService		:	Set objWMIService = GetObject("winmgmts:{impersonationLevel=impersonate}!\\.\root\cimv2")
Dim objArgs				: 	Set objArgs = WScript.Arguments

Const ForReading = 1, ForWriting = 2, ForAppending = 8

' Script variables
Dim strVersion			:	strVersion = "0.2.0"

' Variables required for logging.
Dim fileLog
Dim strLogLocation		:	strLogLocation = objEnv("TEMP") & "\FirefoxADMX.log"

' Global variables used by the various parts of the script.
Dim policiesRegistry	:	policiesRegistry = "HKLM\Software\Policies\Mozilla\Firefox"
Dim baseRegistry		:	baseRegistry = ""
Dim firefoxVersion		:	firefoxVersion = ""
Dim firefoxMajorVersion	:	firefoxMajorVersion = ""
Dim firefoxInstallDir	:	firefoxInstallDir = ""
Dim strMozillaCfgFile	:	strMozillaCfgFile = ""
Dim strAllSettingsFile	:	strAllSettingsFile = ""
Dim strOverrideFile		:	strOverrideFile = ""
Dim bQB					:	bQB = False
Dim bQN					:	bQN = True

checkArgs
forceCScript
generateLogFile

determineArchitecture
locateInstallation

setFileLocations
forceConfigFiles
cleanOldSettings

setCustomHomepage
setDisableDefaultCheck
setDisableImport
setDisableUpdates
setDisableDownloadManager
setDisablePasswordManager
setDisableAddonWizard
setSupressUpdatePage
setDisableTelemetry
setDisableRights
setDisableBrowserMilestone

Sub setCustomHomepage()
	Dim keyHomepageDisplay, keyCustomHomepage
	keyHomepageDisplay = getRegistryKey(policiesRegistry & "\HomepageDisplay")
	keyCustomHomepage = getRegistryKey(policiesRegistry & "\CustomHomepage")
	removePreference("browser.startup.homepage")
	removePreference("browser.startup.page")	
	If keyHomepageDisplay <> "" Then
		writeLog "Changing homepage to " & keyHomepageDisplay
		Select Case Ucase(keyHomepageDisplay)
			Case "DEFAULT"
				appendLockPreference "browser.startup.homepage","about:home",True
				appendLockPreference "browser.startup.page","1",False
			Case "CUSTOM"
				appendLockPreference "browser.startup.homepage",keyCustomHomepage,True
				appendLockPreference "browser.startup.page","1",False
				writeLog "Custom homepage: " & keyCustomHomepage
			Case "BLANK"
				appendLockPreference "browser.startup.homepage","about:blank",True
				appendLockPreference "browser.startup.page","0",False
		End Select
	End If
End Sub

Sub setDisableDefaultCheck
	Dim keyDisableDefaultCheck
	keyDisableDefaultCheck = getRegistryKey(policiesRegistry & "\DisableDefaultCheck")
	removePreference("browser.shell.checkDefaultBrowser")
	If keyDisableDefaultCheck <> "" Then
		writeLog "Disabling Default Browser Check"
		Select Case keyDisableDefaultCheck
			Case 0
				appendLockPreference "browser.shell.checkDefaultBrowser","true",False
			Case 1
				appendLockPreference "browser.shell.checkDefaultBrowser","false",False
		End Select
	End If
End Sub

Sub setDisableImport()
	Dim keyDisableImport, fileOverride, arrOverrideContents, strEnableProfileMigrator
	keyDisableImport = getRegistryKey(policiesRegistry & "\DisableImport")
	If keyDisableImport <> "" Then
		Select Case keyDisableImport
			Case 0
				writeLog "Enabling Import Wizard"
				strEnableProfileMigrator = "EnableProfileMigrator=true"
			Case 1
				writeLog "Disabling Import Wizard"
				strEnableProfileMigrator = "EnableProfileMigrator=false"
		End Select
		If objFSO.FileExists(strOverrideFile) Then
			Set fileOverride = objFSO.GetFile(strOverrideFile)
			If fileOverride.Size > 0 Then 'If the file already exists but is not empty
				writeLog strOverrideFile & " already exists. Replaceing contents"
				Set fileOverride = objFSO.OpenTextFile(strOverrideFile, ForReading)
				arrOverrideContents = Split(fileOverride.ReadAll, vbCrLf)
				arrOverrideContents = Filter(arrOverrideContents,"[XRE]", False, vbTextCompare)
				arrOverrideContents = Filter(arrOverrideContents,"EnableProfileMigrator", False, vbTextCompare)
				Set fileOverride = objFSO.OpenTextFile(strOverrideFile, ForWriting)
				fileOverride.WriteLine "[XRE]"
				fileOverride.WriteLine strEnableProfileMigrator
				fileOverride.Write Join(arrOverrideContents,vbCrLf)
				fileOverride.Close
			Else 'If the file exists but is Empty
				writeLog strOverrideFile & " exists, but is empty. Adding contents"
				Set fileOverride = objFSO.OpenTextFile(strOverrideFile, ForWriting)
				fileOverride.WriteLine "[XRE]"
				fileOverride.WriteLine strEnableProfileMigrator
				fileOverride.Close
			End If	
		Else 'If the file does not exist at all
			writeLog "Creating " & strOverrideFile
			Set fileOverride = objFSO.OpenTextFile(strOverrideFile, ForWriting, True)
			fileOverride.WriteLine "[XRE]"
			fileOverride.WriteLine strEnableProfileMigrator
			fileOverride.Close	
		End If
	End If
End Sub

Sub setDisableUpdates()
	Dim keyDisableUpdate, keyDisableExtensionsUpdate, keyDisableSearchUpdate
	keyDisableUpdate = getRegistryKey(policiesRegistry & "\DisableUpdate")
	keyDisableExtensionsUpdate = getRegistryKey(policiesRegistry & "\DisableExtensionsUpdate")
	keyDisableSearchUpdate = getRegistryKey(policiesRegistry & "\DisableSearchUpdate")
	removePreference("app.update.enabled")
	removePreference("extensions.update.enabled")
	removePreference("browser.search.update")
	If keyDisableUpdate <> "" Then
		writeLog "Disabling Firefox Updates"
		Select Case keyDisableUpdate
			Case 0
				appendLockPreference "app.update.enabled","true",False
			Case 1
				appendLockPreference "app.update.enabled","false",False
		End Select
	End If
	If keyDisableExtensionsUpdate <> "" Then
		writeLog "Disabling Firefox Extension Updates"
		Select Case keyDisableUpdate
			Case 0
				appendLockPreference "extensions.update.enabled","true",False
			Case 1
				appendLockPreference "extensions.update.enabled","false",False
		End Select
	End If
	If keyDisableSearchUpdate <> "" Then
		writeLog "Disabling Firefox Search Updates"
		Select Case keyDisableUpdate
			Case 0
				appendLockPreference "browser.search.update","true",False
			Case 1
				appendLockPreference "browser.search.update","false",False
		End Select
	End If
End Sub

Sub setDisableDownloadManager()
	Dim keyDisableDownloadManager
	keyDisableDownloadManager = getRegistryKey(policiesRegistry & "\DisableDownloadManager")
	removePreference("browser.download.manager.showWhenStarting")
	If keyDisableDownloadManager <> "" Then
		writeLog "Disabling Download Manager"
		Select Case keyDisableDownloadManager
			Case 0
				appendLockPreference "browser.download.manager.showWhenStarting","true",False
			Case 1
				appendLockPreference "browser.download.manager.showWhenStarting","false",False
		End Select
	End If
End Sub

Sub setDisablePasswordManager
	Dim keyDisablePasswordManager
	keyDisablePasswordManager = getRegistryKey(policiesRegistry & "\DisablePasswordManager")
	removePreference("signon.rememberSignons")	
	If keyDisablePasswordManager <> "" Then
		writeLog "Disabling the Password Manager"
		Select Case keyDisablePasswordManager
			Case 0
				appendLockPreference "signon.rememberSignons","true",False
			Case 1
				appendLockPreference "signon.rememberSignons","false",False
		End Select
	End If	
End Sub

Sub setDisableAddonWizard()
	Dim keyDisableAddonWizard
	keyDisableAddonWizard = getRegistryKey(policiesRegistry & "\DisableAddonWizard")
	removePreference("extensions.shownSelectionUI")
	removePreference("extensions.autoDisableScope")
	If keyDisableAddonWizard <> "" Then
		writeLog "Disabling the Add-On Wizard"
		Select Case keyDisableAddonWizard
			Case 0
				appendLockPreference "extensions.shownSelectionUI","false",False
				appendLockPreference "extensions.autoDisableScope","15",False
			Case 1
				appendLockPreference "extensions.shownSelectionUI","true",False
				appendLockPreference "extensions.autoDisableScope","11",False
		End Select
	End If		
End Sub

Sub setSupressUpdatePage()
	Dim keySuppressUpdatePage
	keySuppressUpdatePage = getRegistryKey(policiesRegistry & "\SupressUpdatePage")
	removePreference("startup.homepage_override_url")
	removePreference("startup.homepage_welcome_url")	
	If keySuppressUpdatePage <> "" Then
		writeLog "Suppressing the Firefox Updated page"
		Select Case keySuppressUpdatePage
			Case 1
				appendLockPreference "startup.homepage_override_url","",True
				appendLockPreference "startup.homepage_welcome_url","",True
		End Select
	End If	
End Sub

Sub setDisableTelemetry()
	Dim keyDisableTelemetry
	keyDisableTelemetry = getRegistryKey(policiesRegistry & "\DisableTelemetry")
	removePreference("toolkit.telemetry.enabled")
	removePreference("toolkit.telemetry.prompted")
	removePreference("toolkit.telemetry.rejected")	
	If keyDisableTelemetry <> "" Then
		writeLog "Disabling Telemetry"
		Select Case keyDisableTelemetry
			Case 1
				appendLockPreference "toolkit.telemetry.enabled","false",False
				appendLockPreference "toolkit.telemetry.rejected","true",False
				If firefoxMajorVersion = 8 Then
					appendLockPreference "toolkit.telemetry.prompted","true",False
				ElseIf firefoxMajorVersion > 8 Then
					appendLockPreference "toolkit.telemetry.prompted","2",False
				End If
		End Select
	End If		
End Sub

Sub setDisableRights()
	Dim keyDisableRights
	keyDisableRights = getRegistryKey(policiesRegistry & "\DisableRights")
	removePreference("browser.rights.3.shown")	
	If keyDisableRights <> "" Then
		writeLog "Suppressing the Know your Rights Browser Bar"
		Select Case keyDisableRights
			Case 1
				appendLockPreference "browser.rights.3.shown","true",False
		End Select
	End If	
End Sub

Sub setDisableBrowserMilestone
	Dim keyDisableBrowserMilestone
	keyDisableBrowserMilestone = getRegistryKey(policiesRegistry & "\DisableBrowserMilestone")
	removePreference("browser.startup.homepage_override.mstone")
	If keyDisableBrowserMilestone <> "" Then
		writeLog "Disabling the browser milestone page"
		Select Case keyDisableBrowserMilestone
			Case 1
				appendLockPreference "browser.startup.homepage_override.mstone","ignore",True
		End Select
	End If	
End Sub

Sub determineArchitecture()
	Dim colArchitecture	: Set colArchitecture = objWMIService.ExecQuery("Select AddressWidth from Win32_Processor")
	Dim objArch, strArch
	
	For Each objArch In colArchitecture
		strArch = objArch.AddressWidth
	Next
	
	Select Case strArch
		Case "64"
			baseRegistry = "HKLM\Software\Wow6432Node\Mozilla\Mozilla Firefox\"
		Case "32"
			baseRegistry = "HKLM\Software\Mozilla\Mozilla Firefox\"	
	End Select
End Sub

Sub locateInstallation()
	On Error Resume Next
	firefoxVersion = objShell.RegRead(baseRegistry & "CurrentVersion")
	If Err.Number <> 0 Then
		writeLog "Mozilla Firefox not installed. Exiting."
		Err.Clear
		WScript.Quit(1)
	End If
	On Error GoTo 0
	firefoxInstallDir = objShell.RegRead(baseRegistry & firefoxVersion & "\Main\Install Directory")
	firefoxVersion = split(firefoxVersion,Chr(32))(0)
	firefoxMajorVersion = split(firefoxVersion,Chr(46))(0)
	
	'If the Firefox installation directory can not be found in the registry, use the default 32-bit OS location
	'(C:\Program Files\Mozilla Firefox) by default.
	If firefoxInstallDir = "" Then
		firefoxInstallDir = objEnv("ProgramFiles") & "\Mozilla Firefox"
	End If
	writeLog "Installation Directory: " & firefoxInstallDir
End Sub

Sub setFileLocations()
	strMozillaCfgFile = firefoxInstallDir & "\mozilla.cfg"
	strAllSettingsFile = firefoxInstallDir & "\defaults\pref\all-settings.js"
	strOverrideFile = firefoxInstallDir & "\browser\override.ini"
End Sub

Sub forceConfigFiles()

	On Error Resume Next
	Dim strConfigFile, strConfigObscure, fileAllSettings, arrAllSettingsContents
	strConfigFile = "pref(" & Chr(34) & "general.config.filename" & Chr(34) & "," & Chr(34) & "mozilla.cfg" & Chr(34) & ");"
	strConfigObscure = "pref(" & Chr(34) & "general.config.obscure_value" & Chr(34) & "," & "0" & ");"
	If objFSO.FileExists(strAllSettingsFile) Then 'Check if the file exists first.
		Set fileAllSettings = objFSO.GetFile(strAllSettingsFile)
		'If the file does exist, then make sure it's not empty.
		If fileAllSettings.Size > 0 Then 'If the file is NOT empty
			Set fileAllSettings = objFSO.OpenTextFile(strAllSettingsFile, ForReading)
			arrAllSettingsContents = Split(fileAllSettings.ReadAll, vbCrLf)
			arrAllSettingsContents = Filter(arrAllSettingsContents,"general.config.filename", False, vbTextCompare)
			arrAllSettingsContents = Filter(arrAllSettingsContents,"general.config.obscure_value", False, vbTextCompare)
			Set fileAllSettings = objFSO.OpenTextFile(strAllSettingsFile, ForWriting)
			fileAllSettings.WriteLine strConfigFile
			fileAllSettings.WriteLine strConfigObscure
			fileAllSettings.Write Join(arrAllSettingsContents,vbCrLf)
			fileAllSettings.Close
		Else 'If the file IS empty
			Set fileAllSettings = objFSO.OpenTextFile(strAllSettingsFile, ForWriting)
			fileAllSettings.WriteLine strConfigFile
			fileAllSettings.WriteLine strConfigObscure
			fileAllSettings.Close
		End If
	Else
		Set fileAllSettings = objFSO.OpenTextFile(strAllSettingsFile, ForWriting, True)
		fileAllSettings.WriteLine strConfigFile
		fileAllSettings.WriteLine strConfigObscure
		fileAllSettings.Close
	End If
	Dim fileMozillaCfg, arrMozillaCfgContents
	If objFSO.FileExists(strMozillaCfgFile) Then 'Check if the file exists first.
		Set fileMozillaCfg = objFSO.GetFile(strMozillaCfgFile)
		'If the file does exist, then make sure it's not empty.
		If fileMozillaCfg.Size > 0 Then 'If the file is NOT empty
			Set fileMozillaCfg = objFSO.OpenTextFile(strMozillaCfgFile, ForReading)
			arrMozillaCfgContents = Split(fileMozillaCfg.ReadAll, vbCrLf)
			arrMozillaCfgContents = Filter(arrMozillaCfgContents,"//", False, vbTextCompare)
			Set fileMozillaCfg = objFSO.OpenTextFile(strMozillaCfgFile, ForWriting)
			fileMozillaCfg.WriteLine "//"
			fileMozillaCfg.Write Join(arrMozillaCfgContents,vbCrLf)
			fileMozillaCfg.Close
		Else 'If the file IS empty
			Set fileMozillaCfg = objFSO.OpenTextFile(strMozillaCfgFile, ForWriting)
			fileMozillaCfg.WriteLine "//"
			fileMozillaCfg.Close
		End If
	Else
		Set fileMozillaCfg = objFSO.OpenTextFile(strMozillaCfgFile, ForWriting, True)
		fileMozillaCfg.WriteLine "//"
		fileMozillaCfg.Close
	End If
	On Error GoTo 0
End Sub

Sub cleanOldSettings
	Dim oldRegistryLocation		: oldRegistryLocation = "HKLM\Software\Policies\Mozilla\Firefox\4\"
	On Error Resume Next
		objShell.RegDelete oldRegistryLocation
	On Error GoTo 0	
End Sub

Sub removePreference(strPreference)
	Dim fileMozillaCfg, arrMozillaCfgContents
	If objFSO.FileExists(strMozillaCfgFile) Then 'Check if the file exists.
		Set fileMozillaCfg = objFSO.GetFile(strMozillaCfgFile)
		If fileMozillaCfg.Size > 0 Then 'If the file is NOT empty.
			Set fileMozillaCfg = objFSO.OpenTextFile(strMozillaCfgFile, ForReading)
			arrMozillaCfgContents = Split(fileMozillaCfg.ReadAll, vbCrLf)
			arrMozillaCfgContents = Filter(arrMozillaCfgContents, strPreference, False, vbTextCompare)
			Set fileMozillaCfg = objFSO.OpenTextFile(strMozillaCfgFile, ForWriting)
			fileMozillaCfg.Write Join(arrMozillaCfgContents,vbCrLf)
			fileMozillaCfg.Close
		End If
	End If
End Sub

Sub appendLockPreference(strPreference,strValue,boolQuoted)
	Dim fileMozillaCfg, arrMozillaCfgContents
	If boolQuoted Then
		strPreference = "lockPref(" & Chr(34) & strPreference & Chr(34) & "," & Chr(34) & strValue & Chr(34) & ");"
	Else
		strPreference = "lockPref(" & Chr(34) & strPreference & Chr(34) & "," & strValue & ");"
	End If
	
	If objFSO.FileExists(strMozillaCfgFile) Then
		Set fileMozillaCfg = objFSO.OpenTextFile(strMozillaCfgFile,ForAppending,False)
		fileMozillaCfg.WriteLine strPreference
		fileMozillaCfg.Close
	Else
		Set fileMozillaCfg = objFSO.OpenTextFile(strMozillaCfgFile,ForAppending,True)
		fileMozillaCfg.WriteLine "//"
		fileMozillaCfg.WriteLine strPreference
		fileMozillaCfg.Close
	End If
End Sub

' generateLogFile
Sub generateLogFile()
	On Error Resume Next
	Set fileLog = objFSO.OpenTextFile(strLogLocation,ForAppending,True)
	Select Case Err.Number
	Case 70 'Access Denied
		MsgBox "Log File Inaccessable. Please make sure another instance isn't running and that you are an administrator."
		WScript.Quit(1)
	End Select
	On Error GoTo 0
	writeLog ""
	writeLog "-----------------------------------------------------------------"
	writeLog vbTab & vbTab & vbTab & "Starting New Instance"
	writeLog vbTab & vbTab & vbTab & date & " - " & time
	writeLog "-----------------------------------------------------------------"
	writeLog ""
	writeLog vbTab & vbTab & vbTab & "Firefox ADMX - Version " & strVersion
End Sub

' writeLog
' Outputs "strMessage" to the screen as well as write to a specifed log file.
' Uses the fLog object which points to the logFile variable for a file name and location of the log.
' @param 	sMessage	The message that will be output to both the specified error log and to the screen
Sub writeLog(strMessage)
	logFormat = "["&time&"]"&" "& strMessage
	Wscript.Echo logFormat
	fileLog.WriteLine(logFormat)
End Sub

' forceCScript
' Forces the script to be run using "CScript.exe" rather than the often default "WScript.exe"
Sub forceCScript()
	Dim strArgs	:	strArgs = " "
	Dim i, iWindow
	For i = 0 To objArgs.Count-1
		strArgs = strArgs & objArgs.Item(i) & " "
	Next
	If bQN Then
		iWindow = 0
	ElseIf bQB Then
		iWindow = 1
	Else
		iWindow = 1
	End If
	
	If InStr(WScript.FullName,"cscript") = 0 Then
		objShell.Run "%comspec% /k " & WScript.Path & "\cscript.exe " & Chr(34) & WScript.ScriptFullName & Chr(34) & strArgs,iWindow,False
		WScript.Quit(0)
	End If
End Sub

Sub checkArgs()
	Dim i
	If objArgs.Count > 0 Then
		For i = 0 To objArgs.Count-1
			Select Case objArgs.Item(i)
				Case "/qb"
					bQB = True
					bQN = False
				Case "/qn"
					bQB = False
					bQN = True
			End Select
		Next
	End If					
End Sub

Function getRegistryKey(strKey)
	On Error Resume Next
	strKey = objShell.RegRead(strKey)
	If Err.Number <> 0 Then
		Select Case Err.Number
			Case -2147024894 'Registry key doesn't exist. Usually means the setting is not set via GPO.
				getRegistryKey = ""
			Case Else
				writeLog "Error: " & Err.Number
		End Select
	Else
		getRegistryKey = strKey
	End If
	Err.Clear
	On Error GoTo 0
End Function
