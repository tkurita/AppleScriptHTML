global ScriptLinkMaker
global ASHTML
global TemplateProcessor
global DefaultsManager
global XFile

property _is_css : missing value
property _is_convert : missing value
property _is_scriptlink : missing value
property _use_scripteditor : missing value

script EditorController
	property _target_text : missing value
	on check_target()
		tell application "Script Editor"
			set run_flag to exists front document
		end tell
		
		if not run_flag then
			display dialog "No documents in Script Editor" giving up after 20
			return fasel
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
	
	on target_text()
		if my _target_text is missing value then
			set my _target_path to DefaultsManager's value_for("TargetScript")
			set my _target_text to call method "scriptSource:" of class "ASFormatting" with parameter my _target_path
		end if
		
		return my _target_text
	end target_text
	
	on doc_name()
		set a_name to XFile's make_with(POSIX file (my _target_path))'s item_name()
		return a_name
	end doc_name
end script

on do given fullhtml:full_flag
	log "start do"
	ASHTML's initialize()
	
	set _is_css to DefaultsManager's value_for("GenerateCSS")
	set _is_convert to DefaultsManager's value_for("CodeToHTML")
	set _is_scriptlink to DefaultsManager's value_for("MakeScriptLink")
	set _use_scripteditor to DefaultsManager's value_for("UseScriptEditorSelection")
	if _use_scripteditor then
		set CodeController to EditorController
	else
		set CodeController to FileController
	end if
	log "000"
	set template_name to missing value
	if _is_css then
		if (_is_convert) then
			if (_is_scriptlink) then
				set template_name to "template_full_scriptlink.html"
			else
				set template_name to "template_full.html"
			end if
		end if
	else
		if (_is_convert and _is_scriptlink) then
			set template_name to "template_sourcecode.html"
		end if
	end if
	if (_is_convert or _is_scriptlink) then
		if not CodeController's check_target() then
			return false
		end if
		
		if (_is_convert) then
			set script_html to CodeController's markup()
			--log (script_html's contents_ref()'s item_at(-1)'s element_name())
			set roottag to script_html's contents_ref()'s item_at(-1)'s element_name()
			if roottag is "div" then
				set button_position to "-2em"
			else
				set button_position to "0em"
			end if
			
		end if
		set doc_name to CodeController's doc_name()
		if (_is_scriptlink) then
			set a_text to CodeController's target_text()
			set a_scriptlink to ScriptLinkMaker's button_with_template(a_text, doc_name, "new", "button_template.html")
		end if
	end if
	if template_name is not missing value then
		log template_name
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
			if (_is_css) then
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
	--display dialog "The HTML formatted script has been placed on the clipboard." giving up after 20
end do

on copy_to_clipboard()
	set a_result to do without fullhtml
	tell application (path to frontmost application as Unicode text)
		set the clipboard to a_result's as_unicode()
	end tell
end copy_to_clipboard

on save_location()
	if (_is_css and (not (_is_convert and _is_scriptlink))) then
		set html_path to choose file name with prompt "Save a HTML file" default name "AppleScript.css"
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

on save_to_file()
	set a_result to do with fullhtml
	try
		set html_path to save_location()
	on error msg number errno
		if errno is not -128 then
			error msg number errno
		end if
		return
	end try
	
	a_result's write_to_file(html_path)
	set html_path to html_path as alias
	tell application "Finder"
		set creator type of html_path to missing value
		set file type of html_path to missing value
	end tell
	
	display dialog "Success to Make a HTML file." buttons {"Cancel", "Reveal", "Open"}
	set the_result to button returned of the result
	if the_result is "Reveal" then
		tell application "Finder"
			reveal html_path
		end tell
		activate process "Finder"
	else if the_result is "Open" then
		tell application "Finder"
			open html_path
		end tell
	end if
end save_to_file