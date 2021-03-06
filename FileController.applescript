global PathInfo

property NSUserDefaults : class "NSUserDefaults"
property NSURL : class "NSURL"
property _target_text : missing value
property _target_path : missing value

on check_target()
	set my _target_text to missing value
	set my _target_path to missing value
	return true
end check_target

on markup()
	--log "start markup in FileController"
	my _ashtml's set_wrap_with_block(false)
	tell NSUserDefaults's standardUserDefaults()
        set bmdata to its dataForKey:"TargetScriptBookmark"
	end tell
    set opt to (current application's NSURLBookmarkResolutionWithoutUI as integer) + (current application's NSURLBookmarkResolutionWithSecurityScope as integer)
    tell NSURL's URLByResolvingBookmarkData:bmdata options:opt relativeToURL:(missing value) bookmarkDataIsStale:(missing value) |error|:(missing value)
        its startAccessingSecurityScopedResource
        set an_url to it
        set my _target_path to its |path|() as text
    end tell
    set a_result to my _ashtml's process_url(an_url, false)
	set my _target_text to my _ashtml's target_text()
    an_url's stopAccessingSecurityScopedResource()
	--log "end markup in FileController"
	return a_result
end markup

on resolve_target_path()
	if my _target_path is not missing value then
		return
	end if
	tell NSUserDefaults's standardUserDefaults()
		set my _target_path to stringForKey_("TargetScript") as text
	end tell
end resolve_target_path

on target_text()
	--log "start target_text in FileController"
	if my _target_text is missing value then
		resolve_target_path()
		tell current application's class "ASFormatting"
			set my _target_text to scriptSource_(my _target_path) as text
		end tell
	end if
	--log "end target_text in FileController"
	return my _target_text
end target_text

on doc_name()
	--log "start doc_name"
	resolve_target_path()
	--log my _target_path
	set a_name to PathInfo's make_with((my _target_path) as POSIX file)'s basename()
	--log a_name
	--log "end doc_name"
	return a_name
end doc_name

on is_multiparagraph()
	return true
end is_multiparagraph

on make_with(an_ashtml)
	set self to me
	script FileControllerCore
		property parent : self
		property _ashtml : an_ashtml
		property _target_text : missing value
		property _target_path : missing value
	end script
	return result
end make_with
