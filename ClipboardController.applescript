property _target_text : missing value

on check_target() -- required
	set my _target_text to missing value
	return true
end check_target

on markup() -- required
	--log "start markup in ClipboardController"
	my _ashtml's set_wrap_with_block(false)
	set a_text to target_text()
	set a_result to my _ashtml's process_text(a_text, false)
	--log "end markup in ClipboardController"
	return a_result
end markup

on target_text() -- required
	--log "start target_text in ClipboardController"
	if my _target_text is missing value then
		try
			set my _target_text to the clipboard as text
		on error number -1700
			error "No text data in the clipboard" number 1504
		end try
	end if
	--log "end target_text in FileController"
	return my _target_text
end target_text

on doc_name() -- required
	return "Script in Clipboard"
end doc_name

on is_multiparagraph() -- required
	return (count paragraphs of target_text()) > 1
end is_multiparagraph

on make_with(an_ashtml)
	set self to me
	script ClipboardControllerCore
		property parent : self
		property _ashtml : an_ashtml
		property _target_text : missing value
	end script
	return result
end make_with