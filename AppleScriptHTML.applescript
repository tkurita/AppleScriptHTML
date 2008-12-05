property ASFormattingStyle : missing value
property HTMLElement : missing value
property XCharacterSet : missing value
property XDict : missing value
property XList : missing value
property XText : missing value
property ASHTML : missing value
property ScriptLinkMaker : missing value
property TemplateProcessor : missing value
property ASHTMLProcessor : missing value
property DefaultsManager : missing value
property CSSBuilder : missing value
property RGBColor : missing value
property XFile : missing value
property SheetManager : missing value

property _indicator : missing value
property _main_window : missing value
property _monitor_textview : missing value

on __load__(loader)
	tell loader
		set HTMLElement to load("HTMLElement")
		set XCharacterSet to load("XCharacterSet")
		set RGBColor to load("RGBColor")
		set CSSBuilder to load("CSSBuilder")
		set ScriptLinkMaker to load("ScriptLinkMaker")
		set TemplateProcessor to load("TemplateProcessor")
	end tell
	set XDict to CSSBuilder's XDict
	set XList to XDict's XList
	set XText to XList's XText
	set XFile to TemplateProcessor's XFile
	return missing value
end __load__

property _ : __load__(proxy() of application (get "AppleScriptHTMLLib"))

on import_script(script_name)
	tell main bundle
		set script_path to path for script script_name extension "scpt"
	end tell
	return load script POSIX file script_path
end import_script

on will finish launching theObject
	set ASHTML to import_script("ASHTML")
	set ASFormattingStyle to import_script("ASFormattingStyle")
	set ASHTMLProcessor to import_script("ASHTMLProcessor")
	set DefaultsManager to import_script("DefaultsManager")
	set SheetManager to import_script("SheetManager")
end will finish launching

on launched theObject
	(*
	set formats to call method "styles" of class "ASFormatting"
	log formats
	set a_list to call method "styleNames" of class "ASFormatting"
	log a_list
	--display dialog item 1 of a_list
	log length of formats
	log length of a_list
	log (call method "styleRunsForSource:" of class "ASFormatting" with parameter "display dialog {1,2,3} as string")
	
	set a_script to call method "importScript" of class "ScriptLoader"
	set a_script2 to call method "onemore" of class "ScriptLoader"
	set a_script's _message to "hello"
	log a_script's _message
	log a_script2's _message
	*)
	--ASHTML's initialize()
	--log ASHTML's process_text("tell hello" & return & "display dialog {1,2,3} as text" & return & "beep" & return & "end tell", true)
	
end launched

on clicked theObject
	set a_name to name of theObject
	if a_name is "CopyToClipBoard" then
		start_indicator()
		ASHTMLProcessor's copy_to_clipboard()
		stop_indicator()
	else if a_name is "SaveToFile" then
		start_indicator()
		ASHTMLProcessor's save_to_file()
		stop_indicator()
	end if
end clicked

on awake from nib theObject
	set a_name to name of theObject
	if a_name is "ProgressIndicator" then
		set my _indicator to theObject
	else if a_name is "MainWindow" then
		set my _main_window to theObject
	else if a_name is "MonitorTextView" then
		set my _monitor_textview to theObject
	end if
end awake from nib

on alert ended theObject with reply withReply
	SheetManager's sheet_ended(theObject, withReply)
end alert ended

on dialog ended theObject with reply withReply
	SheetManager's sheet_ended(theObject, withReply)
end dialog ended

on panel ended theObject with result withResult
	SheetManager's sheet_ended(theObject, withResult)
end panel ended

on start_indicator()
	set visible of _indicator to true
	start _indicator
end start_indicator

on stop_indicator()
	stop _indicator
	set visible of _indicator to false
end stop_indicator

