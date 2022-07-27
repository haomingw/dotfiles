.PHONY: install
install:
	bash install.sh vim
	bash install.sh faster-zsh

.PHONY: clean
clean:
	@echo "Removing vim configs"
	rm -rf ~/.*vim* ~/.config/nvim ~/.config/coc
