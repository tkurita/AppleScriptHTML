PRODUCT_NAME := AsHtmlizer

.PHONY:install clean

default: trash clean install

trash:
	trash ${HOME}/Applications/$(PRODUCT_NAME).app

install: trash clean
	xcodebuild -workspace AppleScriptHTML.xcworkspace -scheme $(PRODUCT_NAME) install DSTROOT=${HOME}

clean:
	xcodebuild -workspace AppleScriptHTML.xcworkspace -scheme $(PRODUCT_NAME) clean DSTROOT=${HOME}

