property HTMLElement : module
property XCharacterSet : module
property XDict : module
property XList : module
property XText : module
property RGBColor : module
property XFile : module
property CSSBuilder : module
property TemplateProcessor : module
property only local : true

property loader : boot (module loader of application (get "AppleScriptHTMLLib")) for me

property ASFormattingStyle : missing value
property ASHTML : missing value
property ScriptLinkMaker : missing value
property ASHTMLProcessor : missing value
property DefaultsManager : missing value
property EditorController : missing value
property FileController : missing value
property ClipboardController : missing value

on import_script(script_name)
	--set script_path to path to resource (script_name & ".scpt") in directory "Scripts"
	tell main bundle
		set script_path to path for script script_name extension "scpt"
	end tell
	return load script script_path
end import_script

on setup_modules()
	--log "start setup_modules"
	set ASHTML to import_script("ASHTML")
	set ASFormattingStyle to import_script("ASFormattingStyle")
	set ASHTMLProcessor to import_script("ASHTMLProcessor")
	set DefaultsManager to import_script("DefaultsManager")
	set EditorController to import_script("EditorController")
	set FileController to import_script("FileController")
	set ClipboardController to import_script("ClipboardController")
	set ScriptLinkMaker to import_script("ScriptLinkMaker")
	--log "end setup_modules"
end setup_modules

on save_to_file()
	return ASHTMLProcessor's save_to_file()
end save_to_file

on copy_to_clipboard()
	return ASHTMLProcessor's copy_to_clipboard()
end copy_to_clipboard

on generate_css()
	return ASHTML's css_as_unicode()
end generate_css

on path_on_scripteditor()
	tell application id "com.apple.ScriptEditor2"
		set a_path to path of front document
	end tell
	
	try
		get a_path
		set is_saved to true
	on error
		set is_saved to false
	end try
	
	if is_saved then
		return a_path
	else
		return missing value
	end if
end path_on_scripteditor
