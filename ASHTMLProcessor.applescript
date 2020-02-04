property NSUserDefaults : class "NSUserDefaults"
property NSDictionary : class "NSDictionary"


on boot_for(a_script)
    application (get "AppleScriptHTMLLib")'s loader()'s setup(a_script)
	return
end boot_for

script ASHTMLProcessor
	property HTMLElement : "@module"
	property XCharacterSet : "@module"
	property XDict : "@module"
	property XList : "@module"
	property XText : "@module"
	property RGBColor : "@module"
    property PathInfo: "@module"
	property CSSBuilder : "@module"
	property TemplateProcessor : "@module"
	property _only_local_ : true
	
	property _ : boot_for(me)
	
	property ASFormattingStyle : missing value
	property ASHTML : missing value
	property ScriptLinkMaker : missing value
	property ASHTMLProcessor : missing value
	property EditorController : missing value
	property FileController : missing value
	property ClipboardController : missing value
	
	property _error_info : missing value
    
	on import_script(a_name)
		--log a_name
		return load script (path to resource a_name & ".scpt")
	end import_script
	
	on awakeFromNib()
		--log "start awakeFromNib"
		set ASHTML to import_script("ASHTML")
		set ASFormattingStyle to import_script("ASFormattingStyle")
		set ASHTMLProcessor to import_script("ASHTMLProcessor")
		set EditorController to import_script("EditorController")
		set FileController to import_script("FileController")
		set ClipboardController to import_script("ClipboardController")
		set ScriptLinkMaker to import_script("ScriptLinkMaker")
		--log "end awakeFromNib"
	end awakeFromNib
	
	on errorInfo()
		return my _error_info
	end errorInfo
	
	on do given fullhtml:full_flag
		--log "start do in ASHTMLProcessor"
		set content_type to "html"
		set user_defaults to NSUserDefaults's standardUserDefaults()
		tell user_defaults
			set css_mode to integerForKey_("CSSModeIndex") as integer
			-- 0: internal, 1:inline, 2: only class names
			set is_convert to boolForKey_("CodeToHTML") as boolean
			set is_scriptlink to boolForKey_("MakeScriptLink") as boolean
		end tell
		if not ((css_mode is 0) or is_convert or is_scriptlink) then
			error "No action is selected." number 1501
		end if
		
		set an_ashtml to make ASHTML
		if css_mode is 1 then
			an_ashtml's use_inline_css()
		end if
		
		set target_mode to user_defaults's integerForKey_("TargetMode") as integer
		if target_mode is 0 then
			set CodeController to FileController's make_with(an_ashtml)
		else if target_mode is 1 then
			--log "use Script Editor"
			set CodeController to EditorController's make_with(an_ashtml)
		else
			set CodeController to ClipboardController's make_with(an_ashtml)
		end if
		set template_name to missing value
		if css_mode is 0 then
			if (is_convert) then
				if (is_scriptlink) then
					set template_name to "template_full_scriptlink.html"
				else
					set template_name to "template_full.html"
				end if
			else if (is_scriptlink) then
				set template_name to "template_full_onlyscriptlink.html"
			end if
		else if css_mode is 1 then
			if (is_convert) then
				if (is_scriptlink) then
					set template_name to "template_sourcecode_inline.html"
				else
					set template_name to "template_sourcecode_noscriptlink_inline.html"
				end if
			else if is_scriptlink then
				set template_name to "template_sourcecode_onlyscriptlink_inline.html"
			end if
			
		else if css_mode is 2 then
			if (is_convert) then
				if (is_scriptlink) then
					set template_name to "template_sourcecode.html"
				else
					set template_name to "template_sourcecode_noscriptlink.html"
				end if
			end if
		end if
        
		if (is_convert or is_scriptlink) then
			if not CodeController's check_target() then
				return missing value
			end if
			set is_multiline to false
			if (is_convert) then
				try
					set script_html to CodeController's markup()
					--log (script_html's contents_ref()'s item_at(-1)'s element_name())
				on error number 1480
					error "No content." number 1502
				end try
			end if
			
			set doc_name to CodeController's doc_name()
			set button_style to missing value
			if (is_scriptlink) then
				set a_code to CodeController's target_text()
				set mode_index to user_defaults's integerForKey_("ScriptLinkModeIndex") as integer
				set mode_text to item (mode_index + 1) of {"new", "insert", "append"}
				if not user_defaults's boolForKey_("ObtainScriptLinkTitleFromFilename") as boolean then
					set a_title to user_defaults's stringForKey_("ScriptLinkTitle") as text
					if length of a_title is not 0 then
                        user_defaults's addToScriptLinkTitleHistoryInMainThread_(a_title)
                        tell XText
                            set doc_name to replace for a_title from "%s" by doc_name
                        end tell
					end if

				end if
				set a_scriptlink to ScriptLinkMaker's button_with_template(a_code, doc_name, mode_text, "button_template.html")
                set pos_index to user_defaults's integerForKey_("ScriptLinkPositionIndex") as integer
                if pos_index is 0 then
                    set button_style to "float:right;"
                    set frame_style to ""
                else
                    set button_style to "position:absolute; right:1em; bottom:0.5em;"
                    set frame_style to "position:relative;"
                end if
			end if
		end if
        
		if template_name is not missing value then
			set template_file to path to resource template_name
			set a_template to TemplateProcessor's make_with_file(template_file)
			if (is_convert) then a_template's insert_text("$BODY", script_html's as_unicode())
			if (css_mode is 0) then
				a_template's insert_text("$CSS", an_ashtml's css_as_unicode())
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
			
			if (is_scriptlink) then
				a_template's insert_text("$SCRIPTBUTTON", a_scriptlink's as_unicode())
				if (button_style is not missing value) and (is_convert or (css_mode is not 2)) then
					a_template's insert_text("$BUTTONSTYLE", button_style)
                    a_template's insert_text("$FRAMESTYLE", frame_style)
				end if
			end if
			set a_result to a_template
		else
			if css_mode is 0 then
				set a_result to an_ashtml's formatting_style()'s as_css()
				set content_type to "css"
			else
				set a_result to a_scriptlink
				
				if full_flag then
					set template_file to path to resource "template_full_body.html"
					
					set a_template to TemplateProcessor's make_with_file(template_file)
					a_template's insert_text("$BODY", a_result's as_unicode())
					a_template's insert_text("$TITLE", doc_name)
					set a_result to a_template
					(*
			else if CodeController's is_multiparagraph() then
				--set template_file to path to resource "template_sourcecode_noscriptlink.html"
				tell main bundle
					set template_file to path for resource "template_sourcecode_noscriptlink.html"
				end tell
				set a_template to TemplateProcessor's make_with_file(template_file)
				a_template's insert_text("$BODY", a_result's as_unicode())
				set a_result to a_template
			*)
				end if
			end if
		end if
		--log "end do in ASHTMLProcessor"
		return {|content|:a_result, |kind|:content_type}
	end do
    
    on generateContents()
        try
			set a_result to do without fullhtml
        on error msg number errno from errsrc
            set more_info to ""
            if errsrc is not missing value
                set more_info to errsrc's error_message()
            end if
            set my _error_info to {|message|:msg, |number|:errno, |more_info|:more_info}
			return missing value
		end try
		set a_result's |content| to a_result's |content|'s as_unicode()
		return a_result
    end
	
	on saveToFile()
		try
			set a_result to do with fullhtml
		on error msg number errno from errsrc
            set more_info to ""
            if errsrc is not missing value
                set more_info to errsrc's error_message()
            end if
            set my _error_info to {|message|:msg, |number|:errno, |more_info|:more_info}
            return missing value
        end try
		set a_result's |content| to a_result's |content|'s as_unicode()
		return a_result
	end saveToFile
	
	on generateCSS()
		return ASHTML's css_as_unicode()
	end generateCSS
	
	on pathOnScriptEditor()
		tell application id "com.apple.ScriptEditor2"
			set a_path to path of front document
		end tell
		
		try
			get a_path
			set is_saved to true
		on error
			set is_saved to false
		end try
		
		if is_saved then
			return a_path
		else
			return missing value
		end if
	end pathOnScriptEditor
end script

