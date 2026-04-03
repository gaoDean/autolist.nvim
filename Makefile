LUA_VERSION := 5.1
LUAROCKS := luarocks --local --lua-version $(LUA_VERSION)
NLUA := $(HOME)/.luarocks/bin/nlua
BUSTED := $(HOME)/.luarocks/lib/luarocks/rocks-$(LUA_VERSION)/busted/2.3.0-1/bin/busted

.PHONY: test deps

test:
	eval $$(luarocks path --lua-version $(LUA_VERSION)) && \
		$(NLUA) $(BUSTED) --ignore-lua

deps:
	$(LUAROCKS) install nlua
	$(LUAROCKS) install busted
