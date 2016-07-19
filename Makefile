#
# dist/
#   生成物の配置先。このディレクトリ以下がそのままzipしてアプリ登録する元ネタとなる。
#   Git管理対象外。clobberすると消える。
#
# src/*.{js,coffee}
#   jsまたはcoffeeのソースコード。coffeeから変換された中間生成物のjsは含まない。
#
# view/*.html,rubic.less
#   UI設計部
#   外部jsやfont、cssなどのリンクが含まれている。
#
# cache/*
#   上記に含まれる外部js等のキャッシュ。原則としてコンパイル時にインターネットアクセスを不要とするためにある。
#   Git管理対象外。clobberすると消える。
#
# locales/*.yaml
#   翻訳情報。ファイル名はChromeの言語コード。
#
# test/*
#   テストコード。rubic.gitの管理対象外で、別途rubic-test.gitから取得する。
#   (ただしサブモジュールではない)
#

include common.mk

dist_ver = $(shell sed -ne 's/\s\+"version": "\([^"]\+\)".*/\1/p' $(DIST_DIR)/manifest.json)

all: recursive-all
clean: recursive-clean
clobber: recursive-clobber

release: recursive-all
	d=$(shell pwd)/rubic-$(dist_ver).zip && cd $(DIST_DIR) && test ! -e $$d && zip -r $$d *

recursive-%:
	$(Q)$(MAKE) -C $(SRC_DIR) $*
	$(Q)$(MAKE) -C $(LIBS_DIR) $*
	$(Q)$(MAKE) -C $(LOCALE_DIR) $*
	$(Q)$(MAKE) -C $(VIEW_DIR) $*

server:
	nohup http-server > /dev/null 2>&1 &

