global ScriptLinkMaker
global ASHTML
global TemplateProcessor
global DefaultsManager

on do()
	log "start do"
	ASHTML's initialize()
	
	set is_css to DefaultsManager's value_for("GenerateCSS")
	log is_css
	set is_convert to DefaultsManager's value_for("CodeToHTML")
	log is_convert
	set is_scriptlink to DefaultsManager's value_for("MakeScriptLink")
	log is_scriptlink
	set use_scripteditor to DefaultsManager's value_for("UseScriptEditorSelection")
	
	set template_name to missing value
	if is_css then
		set css_text to ASHTML's build_css()
		if (is_convert) then
			if (is_scriptlink) then
				set template_name to "template_full_scriptlink.html"
			else
				set template_name to "template_full.html"
			end if
		end if
	else
		if (is_convert and is_scriptlink) then
			set template_name to "template_sourcecode.html"
		end if
	end if
	log "aaa"
	if (is_convert or is_scriptlink) then
		tell application "Script Editor"
			set run_flag to exists front document
		end tell
		
		if not run_flag then
			display dialog "No documents in Script Editor" giving up after 20
			return
		end if
		log "bbb"
		if (is_convert) then
			ASHTML's set_wrap_with_block(false)
			set script_text to ASHTML's process_document(front document of application "Script Editor")
			--log script_text
			log "ccc"
			
			if script_text ends with "</div>" then
				set button_position to "-2em"
			else
				set button_position to "0em"
			end if
			log "lll"
			set doc_name to name of front document of application "Script Editor"
			log "ooo"
			if (doc_name starts with "ñºèÃñ¢ê›íË") or (doc_name starts with "Untitled") then
				set doc_name to "edit"
			end if
			log "kkk"
			set a_text to target_text() of ASHTML
			log "jjj"
		end if
		log "ddd"
		if (is_scriptlink) then
			set button_text to ScriptLinkMaker's button_with_template(a_text, doc_name, "new", "button_template.html")
		end if
	end if
	log "eee"
	
	if template_name is not missing value then
		log template_name
		set template_file to path to resource template_name
		set a_template to TemplateProcessor's make_with_file(template_file)
		if (is_convert) then a_template's insert_text("$BODY", script_text)
		if (is_css) then
			a_template's insert_text("$CSS", css_text)
			a_template's insert_text("$TITLE", doc_name)
		end if
		if (is_scriptlink) then
			a_template's insert_text("$SCRIPTBUTTON", button_text)
			if (is_css) then
				a_template's insert_text("$BUTTONPOSITION", button_position)
			end if
		end if
		set outtext to a_template's output()
	else
		if is_css then
			set outtext to css_text
		else if is_scriptlink then
			set outtext to button_text
		else if is_convert then
			set outtext to script_text
		end if
	end if
	--log contentText
	tell application (path to frontmost application as Unicode text)
		set the clipboard to outtext
	end tell
	
	display dialog "The HTML formatted script has been placed on the clipboard." giving up after 20
end do
