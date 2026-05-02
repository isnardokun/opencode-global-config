.PHONY: validate check install uninstall doctor

validate:
	./validate.sh

check:
	bash -n install.sh
	bash -n oc
	bash -n uninstall.sh
	bash -n validate.sh
	jq empty opencode.json
	@for f in profiles/*.json; do jq empty "$$f" && echo "OK: $$f"; done

install:
	bash install.sh

dry-run:
	bash install.sh --dry-run

uninstall:
	bash uninstall.sh

doctor:
	oc --doctor
