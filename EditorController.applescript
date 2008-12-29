global ASHTML
global XFile

global _main_window

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
	--log "start markup in EditorController"
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
	set a_name to name of front document of application "Script Editor"
	if (a_name starts with "名称未設定") or (a_name starts with "Untitled") then
		set a_name to "edit"
	else
		set a_name to XFile's make_with(a_name)'s basename()
	end if
	
	return a_name
end doc_name
