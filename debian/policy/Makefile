
NULL =
INSTALL_STUFF =			\
	vim-policy.html/	\
	vim-policy.txt		\
	$(NULL)

all: html text

html: vim-policy.html/index.html
text: vim-policy.txt

export LC_ALL=C.UTF-8

vim-policy.html/index.html: vim-policy.xml *.xml
	docbook2html $< -o $(dir $@)
vim-policy.txt: vim-policy.xml *.xml
	docbook2txt $<

clean:
	$(RM) -rf $(INSTALL_STUFF)

.PHONY: html text
