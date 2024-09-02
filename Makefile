BUILDDIR=bgg3dprints-layer

all: build

build:
	@echo ___ Starting Lambda Layer Creation ____
	mkdir -p $(CURDIR)/$(BUILDDIR)
	docker run -it -v "$(CURDIR)/$(BUILDDIR):/$(BUILDDIR):z" --user "$(shell id -u):$(shell id -g)" python:3.9-bullseye /bin/bash -c "mkdir -p /$(BUILDDIR)/python \
		&& cd /$(BUILDDIR)/python \
		&& pip install requests -t . \
		&& pip install lxml -t . \
		&& pip install markupsafe -t . \
		&& rm -rf *dist-info"

clean:
	@echo ___ Starting Cleanup ____
	rm -rf $(BUILDDIR)