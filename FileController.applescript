global ASHTML
global XFile
global DefaultsManager

property _target_text : missing value
property _target_path : missing value

on check_target()
	return true
end check_target

on markup()
	--log "start markup in FileController"
	ASHTML's set_wrap_with_block(false)
	set my _target_path to DefaultsManager's value_for("TargetScript")
	set a_result to ASHTML's process_file(my _target_path, false)
	set my _target_text to ASHTML's target_text()
	--log "end markup in FileController"
	return a_result
end markup

on resolve_target_path()
	if my _target_path is missing value then
		set my _target_path to DefaultsManager's value_for("TargetScript")
	end if
end resolve_target_path

on target_text()
	--log "start target_text in FileController"
	if my _target_text is missing value then
		resolve_target_path()
		set my _target_text to call method "scriptSource:" of class "ASFormatting" with parameter my _target_path
	end if
	--log "end target_text in FileController"
	return my _target_text
end target_text

on doc_name()
	resolve_target_path()
	set a_name to XFile's make_with(POSIX file (my _target_path))'s basename()
	return a_name
end doc_name

on is_multiparagraph()
	return true
end is_multiparagraph
