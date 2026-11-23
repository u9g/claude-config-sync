LABEL = com.u9g.claude-config-sync
PLIST = $(HOME)/Library/LaunchAgents/$(LABEL).plist

sync:
	./sync.sh

test:
	./sync.test.sh

install: sync
	sed -e 's|__REPO_DIR__|$(CURDIR)|g' -e 's|__HOME__|$(HOME)|g' \
		$(LABEL).plist > $(PLIST)
	launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null || true
	launchctl bootstrap gui/$$(id -u) $(PLIST)

uninstall:
	launchctl bootout gui/$$(id -u)/$(LABEL) 2>/dev/null || true
	rm -f $(PLIST)

.PHONY: sync test install uninstall
