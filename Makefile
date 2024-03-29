.PHONY: install
install:
	bash install.sh faster-zsh
	bash install.sh vim
	bash install.sh programming

.PHONY: clean
clean:
	@echo "Removing vim configs"
	rm -rf ~/.*vim* ~/.config/nvim ~/.config/coc
