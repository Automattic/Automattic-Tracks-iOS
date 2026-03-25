SWIFTLINT_CMD = swiftlint --working-directory .. --quiet

define run_in_buildtools
	@export SDKROOT=$$(xcrun --sdk macosx --show-sdk-path) && \
	env -C BuildTools swift package plugin \
		--allow-writing-to-directory .. \
		--allow-writing-to-package-directory \
		$(1)
endef

.PHONY: lint format

lint: ## Lint the codebase
	$(call run_in_buildtools,$(SWIFTLINT_CMD))

format: ## Lint and autocorrect linter errors
	$(call run_in_buildtools,$(SWIFTLINT_CMD) --fix)
