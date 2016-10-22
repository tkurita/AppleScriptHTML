.PHONY:install clean

default: trash clean install

trash:
	trash ${HOME}/Applications/AppleScriptHTML.app

install: trash clean
	xcodebuild -workspace AppleScriptHTML.xcworkspace -scheme AppleScriptHTML install DSTROOT=${HOME}

clean:
	xcodebuild -workspace AppleScriptHTML.xcworkspace -scheme AppleScriptHTML clean DSTROOT=${HOME}

