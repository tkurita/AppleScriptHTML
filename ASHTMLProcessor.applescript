global ScriptLinkMaker
global ASHTML
global TemplateProcessor
global HTMLElement
global DefaultsManager
global XFile
global SheetManager
global _main_window
global EditorController
global FileController

property _is_css : missing value
property _is_convert : missing value
property _is_scriptlink : missing value
property _use_scripteditor : missing value

on do given fullhtml:full_flag
	--log "start do"
	ASHTML's initialize()
	set content_type to "html"
	set _is_css to DefaultsManager's value_for("GenerateCSS")
	set _is_convert to DefaultsManager's value_for("CodeToHTML")
	set _is_scriptlink to DefaultsManager's value_for("MakeScriptLink")
	if not (_is_css or _is_convert or _is_scriptlink) then
		set msg to localized string "No action is selected."
		display alert msg attached to _main_window default button "OK"
		error "No Action." number 1501
	end if
	set _use_scripteditor to DefaultsManager's value_for("UseScriptEditorSelection")
	if _use_scripteditor then
		--log "use Script Editor"
		set CodeController to EditorController
	else
		set CodeController to FileController
	end if
	set template_name to missing value
	if _is_css then
		if (_is_convert) then
			if (_is_scriptlink) then
				set template_name to "template_full_scriptlink.html"
			else
				set template_name to "template_full.html"
			end if
		else
			if (_is_scriptlink) then
				set template_name to "template_full_onlyscriptlink.html"
			end if
		end if
	else
		if (_is_convert and _is_scriptlink) then
			set template_name to "template_sourcecode.html"
		end if
	end if
	
	if (_is_convert or _is_scriptlink) then
		if not CodeController's check_target() then
			error "No Target." number 1500
			return missing value
		end if
		set is_multiline to false
		if (_is_convert) then
			try
				set script_html to CodeController's markup()
				--log (script_html's contents_ref()'s item_at(-1)'s element_name())
			on error number 1480
				set msg to localized string "No content."
				display alert msg attached to _main_window default button "OK"
				error "No Content." number 1502
			end try
			
		end if
		set doc_name to CodeController's doc_name()
		set button_position to missing value
		if (_is_scriptlink) then
			set a_code to CodeController's target_text()
			set mode_index to DefaultsManager's value_for("ScriptLinkModeIndex")
			set mode_text to item (mode_index + 1) of {"new", "insert", "append"}
			if not DefaultsManager's value_for("ObtainScriptLinkTitleFromFilename") then
				set a_title to DefaultsManager's value_for("ScriptLinkTitle")
				if length of a_title is not 0 then
					set doc_name to a_title
					call method "addToHistory:forKey:" of user defaults with parameters {doc_name, "ScriptLinkTitleHistory"}
				end if
			end if
			(*
			log a_code
			log doc_name
			log mode_text
			*)
			set a_scriptlink to ScriptLinkMaker's button_with_template(a_code, doc_name, mode_text, "button_template.html")
			if _is_css then
				set pos_index to DefaultsManager's value_for("ScriptLinkPositionIndex")
				if pos_index is 0 then
					set button_position to "top : 0.5em;"
				else
					set button_position to "bottom : 0.5em;"
				end if
			end if
		end if
	end if
	if template_name is not missing value then
		set template_file to path to resource template_name
		set a_template to TemplateProcessor's make_with_file(template_file)
		if (_is_convert) then a_template's insert_text("$BODY", script_html's as_unicode())
		if (_is_css) then
			a_template's insert_text("$CSS", ASHTML's css_as_unicode())
			a_template's insert_text("$TITLE", doc_name)
		else
			if full_flag then
				set template_file to path to resource "template_full_body.html"
				set a_template2 to TemplateProcessor's make_with_file(template_file)
				a_template2's insert_text("$BODY", a_template's as_unicode())
				a_template2's insert_text("$TITLE", doc_name)
				set a_template to a_template2
			end if
		end if
		if (_is_scriptlink) then
			a_template's insert_text("$SCRIPTBUTTON", a_scriptlink's as_unicode())
			if (button_position is not missing value) and (_is_convert or _is_css) then
				a_template's insert_text("$BUTTONPOSITION", button_position)
			end if
		end if
		set a_result to a_template
	else
		if _is_css then
			set a_result to ASHTML's formatting_style()'s as_css()
			set content_type to "css"
		else
			if _is_scriptlink then
				set a_result to a_scriptlink
			else if _is_convert then
				set a_result to script_html
			end if
			
			if full_flag then
				set template_file to path to resource "template_full_body.html"
				set a_template to TemplateProcessor's make_with_file(template_file)
				a_template's insert_text("$BODY", a_result's as_unicode())
				a_template's insert_text("$TITLE", doc_name)
				set a_result to a_template
			else if CodeController's is_multiparagraph() then
				set template_file to path to resource "template_sourcecode_noscriptlink.html"
				set a_template to TemplateProcessor's make_with_file(template_file)
				a_template's insert_text("$BODY", a_result's as_unicode())
				set a_result to a_template
			end if
		end if
	end if
	
	return {content:a_result, kind:content_type}
end do

on copy_to_clipboard()
	try
		set a_result to do without fullhtml
	on error msg number errno
		if errno is not in {1500, 1501, 1502} then
			error msg number errno
		end if
		return missing value
	end try
	set a_result's content to a_result's content's as_unicode()
	return a_result
end copy_to_clipboard

on save_location()
	if (_is_css and (not (_is_convert and _is_scriptlink))) then
		set html_path to choose file name with prompt "Save a CSS file" default name "AppleScript.css"
	else
		tell application id "com.apple.ScriptEditor2"
			set file_path to path of front document
		end tell
		
		try
			get file_path
			set is_saved to true
		on error
			set is_saved to false
		end try
		
		if is_saved then
			set a_xfile to XFile's make_with(POSIX file file_path)
			set a_xfile to a_xfile's change_path_extension("html")
			set html_path to choose file name with prompt "Save a HTML file" default name a_xfile's item_name() default location (a_xfile's parent_folder()'s as_alias())
			
		else
			set html_path to choose file name with prompt "Save a HTML file" default name "AppleScript HTML.html"
		end if
	end if
	return html_path
end save_location

on save_location_name()
	set a_location to missing value
	set a_name to missing value
	set save_to_source_location to DefaultsManager's value_for("SaveToSourceLocation")
	if (_is_css and (not (_is_convert or _is_scriptlink))) then
		set a_name to "AppleScript.css"
	else
		if _use_scripteditor then
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
				set a_xfile to XFile's make_with(POSIX file a_path)
				set a_xfile to a_xfile's change_path_extension("html")
				set a_name to a_xfile's item_name()
				if save_to_source_location then
					set a_location to a_xfile's parent_folder()'s as_alias()
				end if
				
			else
				set a_name to "AppleScript HTML.html"
			end if
		else
			set a_path to DefaultsManager's value_for("TargetScript")
			set a_xfile to XFile's make_with(POSIX file a_path)
			set a_xfile to a_xfile's change_path_extension("html")
			set a_name to a_xfile's item_name()
			if save_to_source_location then
				set a_location to a_xfile's parent_folder()'s as_alias()
			end if
		end if
	end if
	return {a_location, a_name}
end save_location_name

on after_save(a_path)
	set reveal_label to localized string "Reveal"
	set open_label to localized string "Open"
	set cancel_label to localized string "Cancel"
	set msg to localized string "Success to Make a HTML file."
	display alert msg attached to _main_window default button open_label other button reveal_label alternate button cancel_label
	script AfterAlert
		on sheet_ended(sender, a_reply)
			set a_result to button returned of a_reply
			if a_result is reveal_label then
				set a_file to (POSIX file a_path) as alias
				tell application "Finder"
					reveal a_file
				end tell
				--call method "selectFile:inFileViewerRootedAtPath:" of workspace with parameters {a_path, ""}
				call method "activateAppOfIdentifier:" of class "SmartActivate" with parameter "com.apple.finder"
			else if a_result is open_label then
				set workspace to call method "sharedWorkspace" of class "NSWorkspace"
				call method "openFile:" of workspace with parameter a_path
			end if
		end sheet_ended
	end script
	register_sheet of SheetManager given attached_to:_main_window, delegate:AfterAlert
end after_save

on save_to_file()
	try
		set a_result to do with fullhtml
	on error msg number errno
		if errno is not in {1500, 1501, 1502} then
			error msg number errno
		end if
		return false
	end try
	set {a_location, a_name} to save_location_name()
	if a_location is missing value then
		display save panel attached to _main_window with file name a_name
	else
		display save panel attached to _main_window with file name a_name in directory a_location
	end if
	
	script FileWriter
		on sheet_ended(sender, a_replay)
			close panel sender
			if a_replay is not 1 then
				return
			end if
			set a_path to path name of sender
			tell AppleScript
				set file_ref to a_result's content's write_to_file(POSIX file a_path)
				set an_alias to (file_ref as alias)
			end tell
			tell application "System Events"
				set creator type of an_alias to ""
				set file type of an_alias to ""
			end tell
			-- an_alias does not works after removing a creator and a type  due to unknown reason
			call method "setContent:type:" of class "MonitorWindowController" with parameters {a_result's content's as_unicode(), a_result's kind}
			after_save(a_path)
		end sheet_ended
	end script
	
	register_sheet of SheetManager given attached_to:_main_window, delegate:FileWriter
	
	return true
end save_to_file