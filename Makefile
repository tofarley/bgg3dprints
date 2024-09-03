BUILDDIR=bgg3dprints-layer

all: build

build:
	@echo ___ Starting Lambda Layer Creation ____
	mkdir -p $(CURDIR)/$(BUILDDIR)
	docker run -it -v "$(CURDIR)/$(BUILDDIR):/$(BUILDDIR):z" --user "$(shell id -u):$(shell id -g)" lambda-test:v1 /bin/bash -c "mkdir -p /$(BUILDDIR)/python \
		&& cd /$(BUILDDIR)/python \
		&& pip install requests -t . \
		&& pip install lxml -t . \
		&& pip install markupsafe -t . \
		&& chmod -R 755 . \
		&& rm -rf *dist-info"

clean:
	@echo ___ Starting Cleanup ____
	rm -rf $(BUILDDIR)