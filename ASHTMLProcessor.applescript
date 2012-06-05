global ScriptLinkMaker
global ASHTML
global TemplateProcessor
global HTMLElement
global DefaultsManager
global XFile
global EditorController
global FileController
global ClipboardController

property _is_css : missing value
property _is_convert : missing value
property _is_scriptlink : missing value

on do given fullhtml:full_flag
	ASHTML's initialize()
	set content_type to "html"
	set _is_css to DefaultsManager's value_for("GenerateCSS")
	set _is_convert to DefaultsManager's value_for("CodeToHTML")
	set _is_scriptlink to DefaultsManager's value_for("MakeScriptLink")
	if not (_is_css or _is_convert or _is_scriptlink) then
		error "No action is selected." number 1501
	end if
	set target_mode to DefaultsManager's value_for("TargetMode")
	if target_mode is 0 then
		set CodeController to FileController
	else if target_mode is 1 then
		--log "use Script Editor"
		set CodeController to EditorController
	else
		set CodeController to ClipboardController
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
			return missing value
		end if
		set is_multiline to false
		if (_is_convert) then
			try
				set script_html to CodeController's markup()
				--log (script_html's contents_ref()'s item_at(-1)'s element_name())
			on error number 1480
				error "No content." number 1502
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
		tell main bundle
			set template_file to path for resource template_name
		end tell
		--set template_file to path to resource template_name
		set a_template to TemplateProcessor's make_with_file(template_file)
		if (_is_convert) then a_template's insert_text("$BODY", script_html's as_unicode())
		if (_is_css) then
			a_template's insert_text("$CSS", ASHTML's css_as_unicode())
			a_template's insert_text("$TITLE", doc_name)
		else
			if full_flag then
				--set template_file to path to resource "template_full_body.html"
				tell main bundle
					set template_file to path for resource "template_full_body.html"
				end tell
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
				--set template_file to path to resource "template_full_body.html"
				tell main bundle
					set template_file to path for resource "template_full_body.html"
				end tell
				set a_template to TemplateProcessor's make_with_file(template_file)
				a_template's insert_text("$BODY", a_result's as_unicode())
				a_template's insert_text("$TITLE", doc_name)
				set a_result to a_template
			else if CodeController's is_multiparagraph() then
				--set template_file to path to resource "template_sourcecode_noscriptlink.html"
				tell main bundle
					set template_file to path for resource "template_sourcecode_noscriptlink.html"
				end tell
				set a_template to TemplateProcessor's make_with_file(template_file)
				a_template's insert_text("$BODY", a_result's as_unicode())
				set a_result to a_template
			end if
		end if
	end if
	return {content:a_result, kind:content_type}
end do

on copy_to_clipboard()
	set a_result to do without fullhtml
	set a_result's content to a_result's content's as_unicode()
	return a_result
end copy_to_clipboard

on save_to_file()
	set a_result to do with fullhtml
	set a_result's content to a_result's content's as_unicode()
	return a_result
end save_to_file