global ScriptLinkMaker
global ASHTML
global TemplateProcessor
global DefaultsManager
global XFile
global SheetManager
global _main_window
global _monitor_textview

property _is_css : missing value
property _is_convert : missing value
property _is_scriptlink : missing value
property _use_scripteditor : missing value

script EditorController
	property _target_text : missing value
	on check_target()
		tell application "System Events"
			set run_flag to exists application process "Script Editor"
		end tell
		
		if not run_flag then
			display alert "Script Editor is not Launched" attached to _main_window
			return false
		end if
		
		tell application "Script Editor"
			set run_flag to exists front document
		end tell
		
		if not run_flag then
			display alert "No documents in Script Editor" attached to _main_window
			return false
		end if
		return true
	end check_target
	
	on markup()
		ASHTML's set_wrap_with_block(false)
		set a_result to ASHTML's process_document(front document of application "Script Editor")
		set my _target_text to ASHTML's target_text()
		return a_result
	end markup
	
	on target_text()
		if my _target_text is not missing value then
			return my _target_text
		end if
		tell application "Script Editor"
			set runForSelection to ("" is not (contents of selection of document 1))
			
			if runForSelection then
				set my _target_text to contents of selection of document 1 as Unicode text
			else
				set my _target_text to contents of document 1 as Unicode text
			end if
		end tell
		return my _target_text
	end target_text
	
	on doc_name()
		set a_name to name of front document of application "Script Editor"
		if (a_name starts with "ñºèÃñ¢ê›íË") or (a_name starts with "Untitled") then
			set a_name to "edit"
		else
			set a_name to XFile's make_with(a_name)'s basename()
		end if
		
		return a_name
	end doc_name
end script

script FileController
	property _target_text : missing value
	property _target_path : missing value
	on check_target()
		return true
	end check_target
	
	on markup()
		ASHTML's set_wrap_with_block(false)
		set my _target_path to DefaultsManager's value_for("TargetScript")
		set a_result to ASHTML's process_file(my _target_path, false)
		set my _target_text to ASHTML's target_text()
		return a_result
	end markup
	
	on resolve_target_path()
		if my _target_path is missing value then
			set my _target_path to DefaultsManager's value_for("TargetScript")
		end if
	end resolve_target_path
	
	on target_text()
		if my _target_text is missing value then
			resolve_target_path()
			set my _target_text to call method "scriptSource:" of class "ASFormatting" with parameter my _target_path
		end if
		return my _target_text
	end target_text
	
	on doc_name()
		resolve_target_path()
		set a_name to XFile's make_with(POSIX file (my _target_path))'s basename()
		return a_name
	end doc_name
end script

on do given fullhtml:full_flag
	--log "start do"
	ASHTML's initialize()
	
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
			set script_html to CodeController's markup()
			--log (script_html's contents_ref()'s item_at(-1)'s element_name())
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
			end if
		end if
	end if
	
	return a_result
end do

on copy_to_clipboard()
	try
		set a_result to do without fullhtml
	on error msg number errno
		if errno is not in {1500, 1501} then
			error msg number errno
		end if
		return false
	end try
	set a_text to a_result's as_unicode()
	tell application (path to frontmost application as Unicode text)
		set the clipboard to a_text
	end tell
	set content of _monitor_textview to a_text
end copy_to_clipboard

on save_location()
	if (_is_css and (not (_is_convert and _is_scriptlink))) then
		set html_path to choose file name with prompt "Save a CSS file" default name "AppleScript.css"
	else
		tell application "Script Editor"
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
			set a_xfile to a_xfile's change_path_extension(".html")
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
	if (_is_css and (not (_is_convert or _is_scriptlink))) then
		set a_name to "AppleScript.css"
	else
		if _use_scripteditor then
			tell application "Script Editor"
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
				set a_xfile to a_xfile's change_path_extension(".html")
				set a_name to a_xfile's item_name()
				set a_location to a_xfile's parent_folder()'s as_alias()
				
			else
				set a_name to "AppleScript HTML.html"
			end if
		else
			set a_path to DefaultsManager's value_for("TargetScript")
			set a_xfile to XFile's make_with(POSIX file a_path)
			set a_xfile to a_xfile's change_path_extension(".html")
			set a_name to a_xfile's item_name()
			set a_location to a_xfile's parent_folder()'s as_alias()
		end if
	end if
	return {a_location, a_name}
end save_location_name

on after_save(a_file)
	set reveal_label to localized string "Reveal"
	set open_label to localized string "Open"
	set cancel_label to localized string "Cancel"
	set msg to localized string "Success to Make a HTML file."
	display alert msg attached to _main_window default button open_label other button reveal_label alternate button cancel_label
	script AfterAlert
		on sheet_ended(sender, a_reply)
			set the_result to button returned of a_reply
			if the_result is reveal_label then
				tell application "Finder"
					reveal a_file
				end tell
				call method "activateAppOfIdentifier:" of class "SmartActivate" with parameter "com.apple.finder"
			else if the_result is open_label then
				tell application "Finder"
					open a_file
				end tell
			end if
		end sheet_ended
	end script
	register_sheet of SheetManager given attached_to:_main_window, delegate:AfterAlert
end after_save

on save_to_file()
	try
		set a_result to do with fullhtml
	on error msg number errno
		if errno is not in {1500, 1501} then
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
			a_result's write_to_file(POSIX file a_path)
			set html_path to (POSIX file a_path) as alias
			tell application "System Events"
				set creator type of html_path to ""
				set file type of html_path to ""
			end tell
			set content of _monitor_textview to a_result's as_unicode()
			after_save(html_path)
		end sheet_ended
	end script
	
	register_sheet of SheetManager given attached_to:_main_window, delegate:FileWriter
	
	return true
end save_to_file