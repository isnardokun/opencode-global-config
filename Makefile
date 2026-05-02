.PHONY: validate check test install dry-run uninstall doctor format

validate:
	./validate.sh

check:
	bash -n install.sh
	bash -n oc
	bash -n hooks/pre-commit
	bash -n hooks/pre-push
	bash -n uninstall.sh
	bash -n validate.sh
	jq empty opencode.json
	jq empty opencode.strict.json
	@for f in profiles/*.json; do jq empty "$$f" && echo "OK: $$f"; done

test:
	bash tests/run.sh

format:
	@command -v shfmt >/dev/null 2>&1 && shfmt -w -i 2 -ci install.sh oc validate.sh uninstall.sh hooks/pre-commit hooks/pre-push || echo "shfmt not installed — skipping shell format"
	jq . opencode.json > /tmp/_oc_fmt.json && mv /tmp/_oc_fmt.json opencode.json
	jq . opencode.strict.json > /tmp/_oc_fmt.json && mv /tmp/_oc_fmt.json opencode.strict.json
	@for f in profiles/*.json; do jq . "$$f" > /tmp/_oc_fmt.json && mv /tmp/_oc_fmt.json "$$f"; done

install:
	bash install.sh

dry-run:
	bash install.sh --dry-run

uninstall:
	bash uninstall.sh

doctor:
	oc --doctor
