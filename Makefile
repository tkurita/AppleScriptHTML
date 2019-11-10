PRODUCT_NAME := AsHtmlizer
CONFIG := Release

.PHONY:install clean

default: trash clean install

trash:
	trash ${HOME}/Applications/$(PRODUCT_NAME).app

install:
	xcodebuild -workspace AppleScriptHTML.xcworkspace -scheme $(PRODUCT_NAME) -configuration $(CONFIG) install DSTROOT=${HOME}

clean:
	xcodebuild -workspace AppleScriptHTML.xcworkspace -scheme $(PRODUCT_NAME) -configuration $(CONFIG) clean DSTROOT=${HOME}

