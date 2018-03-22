LIBPATH = ./lib
PLUGINPATH = ./realms

# this is the application name for building thekeep.exe
APP = realms/*
MAIN = rosh.pl
CONTAINER = ickooch/rosh

# leave empty for hub.docker.com
DOCKER_REGISTRY = 

# special utilities used for maintaining/releasing the rosh CLI
MKLICENCE = perl ../util/mklicence.pl
MKBUILDID = perl ../util/mk_build_id.pl

BUILD_ID = lib/build_id.pm

LIB := $(subst :, ,$(LIBPATH) $(PLUGINPATH))

PERLAPP_LIBPATH := $(subst :,\;,$(LIBPATH))
PERLINCLUDES := $(foreach lib,$(LIB),-I$(lib) )

PERL = perl
#PLFILES = $(TOOL_EXECUTABLES:.exe=.pl)
PLFILES = $(MAIN)
PMODULES = $(wildcard $(APP)/*.pm)
LIBMODULES = $(wildcard $(LIBPATH)/*.pm)

OKTARGETS = $(PMODULES:.pm=.pm.ok) $(LIBMODULES:.pm=.pm.ok) $(PLFILES:.pl=.pl.ok)

LAST_STAGE = $(TARGET)/.last_update

%.pm.ok: %.pm
	$(PERL) -c $(PERLINCLUDES) $<
	@touch $@

%.pl.ok: %.pl
	$(PERL) -c $(PERLINCLUDES) $<
	@touch $@

all: compile build

docker: docker_build

docker_build: compile check_git_creds
	@docker build -t $(CONTAINER) --build-arg GIT_USER=$(GIT_USER) --build-arg GIT_TOKEN=$(GIT_TOKEN) .

docker_push: compile check_docker_creds docker_build
	@docker login -u $(DOCKER_USER) -p $(DOCKER_TOKEN) $(DOCKER_REGISTRY)
	@docker push $(CONTAINER)

echook:
	@echo $(OKTARGETS)

echolib:
	@echo $(LIB)
	@echo $(LIBMODULES)

echoplugin:
	@echo $(APP)
	@echo $(PMODULES)

install: compile build stage touch_stage

stage:  compile build
	@if test -f $(LAST_STAGE) ; \
	then \
		st=`cat $(LAST_STAGE)`; \
		echo Updating files changed since $$st ; \
		tar cf - -U --newer-mtime "$$st" $(STAGE_FILES) | (cd $(TARGET); rm -f `tar tf -`) ; \
		tar cvf - -U --newer-mtime "$$st" $(STAGE_FILES) | (cd $(TARGET); tar xvf -) ; \
	else \
		echo Doing full update of files ; \
		tar cvf - -U $(STAGE_FILES) | (cd $(TARGET); tar xvf -) ; \
	fi;

touch_stage:
	date '+%Y-%m-%d %X' > $(LAST_STAGE)

clean:
	@echo cleaning target directory $(TARGET)
	@rm -rf $(TARGET)

compile: $(OKTARGETS)

check_git_creds:
	@if [ -z "$(GIT_USER)" ] || [ -z "$(GIT_TOKEN)" ]; then echo Please define environment variable GIT_USER and GIT_TOKEN for build; exit 1; fi

check_docker_creds:
	@if [ -z "$(DOCKER_USER)" ] || [ -z "$(DOCKER_TOKEN)" ]; then echo Please define environment variable DOCKER_USER and DOCKER_TOKEN for build; exit 1; fi

build: mk_build_id $(TOOL_EXECUTABLES)

mk_build_id:
	@echo "1;" > $(BUILD_ID)
	@$(MKBUILDID) $(BUILD_ID)

rm_build_id:
	@$(MKBUILDID) $(BUILD_ID) undef

app_licence:
	@$(MKLICENCE) --app $(APP)

