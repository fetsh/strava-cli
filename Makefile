.PHONY: build install uninstall clean completion-bash completion-zsh

build:
	dune build

install:
	dune install

uninstall:
	dune uninstall

clean:
	dune clean

# Install bash completion (user-level)
completion-bash:
	@echo "Installing bash completion..."
	@mkdir -p ~/.bash_completion.d
	@cp strava-completion.bash ~/.bash_completion.d/strava
	@if ! grep -q "source ~/.bash_completion.d/strava" ~/.bashrc; then \
		echo "source ~/.bash_completion.d/strava" >> ~/.bashrc; \
		echo "Added completion source to ~/.bashrc"; \
	fi
	@echo "Bash completion installed. Run: source ~/.bashrc"

# Install zsh completion (user-level)
completion-zsh:
	@echo "Installing zsh completion..."
	@mkdir -p ~/.zsh/completion
	@cp strava-completion.zsh ~/.zsh/completion/_strava
	@echo "Zsh completion installed."
	@echo "Make sure your ~/.zshrc contains:"
	@echo "  fpath=(~/.zsh/completion \$$fpath)"
	@echo "  autoload -Uz compinit && compinit"
	@echo "Then run: source ~/.zshrc"

# Install bash completion (system-wide, requires sudo)
completion-bash-system:
	@echo "Installing bash completion system-wide..."
	@sudo cp strava-completion.bash /etc/bash_completion.d/strava
	@echo "System-wide bash completion installed."

# Install zsh completion (system-wide, requires sudo)
completion-zsh-system:
	@echo "Installing zsh completion system-wide..."
	@sudo cp strava-completion.zsh /usr/local/share/zsh/site-functions/_strava
	@echo "System-wide zsh completion installed."

help:
	@echo "Strava CLI - Makefile targets:"
	@echo "  build                  - Build the project"
	@echo "  install                - Install the binary"
	@echo "  uninstall              - Uninstall the binary"
	@echo "  clean                  - Clean build artifacts"
	@echo "  completion-bash        - Install bash completion (user-level)"
	@echo "  completion-zsh         - Install zsh completion (user-level)"
	@echo "  completion-bash-system - Install bash completion (system-wide)"
	@echo "  completion-zsh-system  - Install zsh completion (system-wide)"
