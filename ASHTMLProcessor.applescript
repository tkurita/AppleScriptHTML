global ScriptLinkMaker
global ASHTML
global TemplateProcessor

property lineFeed : ASCII character 10

on do()
	tell application "Script Editor"
		set run_flag to exists front document
	end tell
	
	if not run_flag then
		display dialog "No documents in Script Editor" giving up after 20
		return
	end if
	
	ASHTML's initialize()
	ASHTML's set_wrap_with_block(false)
	set script_text to ASHTML's process_document(front document of application "Script Editor")
	--log script_text
	if script_text ends with "</div>" then
		set button_position to "-2em"
	else
		set button_position to "0em"
	end if
	
	set doc_name to name of front document of application "Script Editor"
	if (doc_name starts with "ñºèÃñ¢ê›íË") or (doc_name starts with "Untitled") then
		set doc_name to "edit"
	end if
	set a_text to target_text() of ASHTML
	
	set button_text to ScriptLinkMaker's button_with_template(a_text, doc_name, "new", "button_template.html")
	
	set template_file to path to resource "template.html"
	set a_template to TemplateProcessor's make_with_file(template_file)
	a_template's insert_text("$BODY", script_text)
	a_template's insert_text("$SCRIPTBUTTON", button_text)
	a_template's insert_text("$BUTTONPOSITION", button_position)
	
	--log contentText
	tell application (path to frontmost application as Unicode text)
		set the clipboard to (a_template's output())
	end tell
	
	display dialog "The HTML formatted script has been placed on the clipboard." giving up after 20
end do
