global XFile

property _target_text : missing value

on check_target()
    set run_flag to (application id "com.apple.ScriptEditor2" is running)
	if not run_flag then
		error "Script Editor is not Launched." number 1500
		return false
	end if
	
	tell application id "com.apple.ScriptEditor2"
		set run_flag to exists front document
	end tell
	
	if not run_flag then
		error "No documents in Script Editor." number 1500
		return false
	end if
	return true
end check_target

on markup()
	--log "start markup in EditorController"
	my _ashtml's set_wrap_with_block(false)
	set a_result to my _ashtml's process_document(front document of application id "com.apple.ScriptEditor2")
	set my _target_text to my _ashtml's target_text()
	return a_result
end markup

on target_text()
	if my _target_text is not missing value then
		return my _target_text
	end if
	tell application id "com.apple.ScriptEditor2"
		set run_for_selection to ("" is not (contents of selection of document 1))
		
		if run_for_selection then
			set my _target_text to contents of selection of document 1 as Unicode text
		else
			set my _target_text to contents of document 1 as Unicode text
		end if
	end tell
	return my _target_text
end target_text

on doc_name()
	set a_name to name of front document of application id "com.apple.ScriptEditor2"
	if (a_name starts with "名称未設定") or (a_name starts with "Untitled") then
		set a_name to "edit"
	else
		set a_name to XFile's make_with(a_name)'s basename()
	end if
	
	return a_name
end doc_name

on is_multiparagraph()
	return (count paragraphs of target_text()) > 1
end is_multiparagraph

on make_with(an_ashtml)
	set self to me
	script EditorControllerCore
		property parent : self
		property _ashtml : an_ashtml
		property _target_text : missing value
	end script
	return result
end make_with
