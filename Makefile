ORIGIN = README.md
DOC = doc/autolist.txt

SRC = lua/autolist

all:

# The command used to generate the help file is from <https://github.com/davysson/md2vim>
doc:
	md2vim -generate-tags -desc "Minimal automatic list continuation for neovim, powered by lua" $(ORIGIN) $(DOC) && echo "vim:tw=78:ts=8:noet:ft=help:norl:" >> $(DOC)

# make gives error 1 if no prints found
test:
	rg "print" $(SRC)/*
