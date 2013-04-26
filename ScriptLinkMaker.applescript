global TemplateProcessor

on href_with_text(a_text, an_action)
	--set escaped_text to URI Escape a_text additional "'&"
	--tell current application's class "NSString"'s stringWithString_(a_text)
	--set escaped_text to call method "stringByAddingPercentEscapesUsingEncoding:leavings:additionals:" of a_text with parameters {134217984, "", "&'+"}
	set escaped_text to a_text's stringByAddingPercentEscapesUsingEncoding_leavings_additionals_(134217984, "", "&'+") as text
	set href_text to "applescript://com.apple.scripteditor?action=" & an_action & "%26script=" & escaped_text
	return href_text
end href_with_text

on button_with_template(a_text, link_text, an_action, template_name)
	set href_text to href_with_text(a_text, an_action)
	(*
	tell main bundle
		set template_file to path for resource template_name
	end tell
	*)
	set template_file to path to resource template_name
	--set template_file to path to resource template_name
	set a_template to TemplateProcessor's make_with_file(template_file)
	a_template's insert_text("$LINKTEXT", link_text)
	a_template's insert_text("$HREF", href_text)
	return a_template
end button_with_template