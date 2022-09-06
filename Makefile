ORIGIN = README.md
DOC = doc/autolist.txt

SRC = lua/autolist

all: tags doc

# The command used to generate the help file is from <https://github.com/gaoDean/md2vim>
doc: $(ORIGIN)
	@echo "Making docs"
	@md2vim -generate-tags -desc "Minimal automatic list continuation for neovim, powered by lua" $(ORIGIN) $(DOC) && echo "vim:tw=78:ts=8:noet:ft=help:norl:" >> $(DOC)

tags: $(SRC)/*
	@echo "Making tags"
	@cd $(SRC) && ctags -R *

# make gives error 1 if no prints found
test:
	rg "print" $(SRC)/*
