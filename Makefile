GLUON_BUILD_DIR := gluon-build
GLUON_GIT_URL := https://github.com/freifunk-gluon/gluon.git
GLUON_GIT_REF := v2016.2.4

SECRET_KEY_FILE ?= ${HOME}/.gluon-secret-key

GLUON_TARGETS ?= \
	ar71xx-generic \
	ar71xx-nand \
	brcm2708-bcm2708 \
	brcm2708-bcm2709 \
	mpc85xx-generic \
	x86-64 \
	x86-generic \
	x86-kvm_guest

GLUON_ATH10K_MESH := 11s
	
GLUON_RELEASE := $(shell git describe --tags 2>/dev/null)
ifneq (,$(shell git describe --exact-match --tags 2>/dev/null))
  GLUON_BRANCH := stable
else
  GLUON_BRANCH := experimental
endif

JOBS ?= $(shell cat /proc/cpuinfo | grep processor | wc -l)

GLUON_MAKEFLAGS := -C ${GLUON_BUILD_DIR} \
			GLUON_RELEASE=${GLUON_RELEASE} \
			GLUON_BRANCH=${GLUON_BRANCH}

all: info
	$(MAKE) manifest

info:
	@echo
	@echo '#########################'
	@echo '# TECFF Firmware build'
	@echo '# Building release ${GLUON_RELEASE} for branch ${GLUON_BRANCH}'
	@echo

build: gluon-prepare
	+for target in ${GLUON_TARGETS}; do \
		echo ""Building target $$target""; \
		$(MAKE) ${GLUON_MAKEFLAGS} GLUON_TARGET="$$target"; \
	done

manifest: build
	$(MAKE) ${GLUON_MAKEFLAGS} manifest
	mv ${GLUON_BUILD_DIR}/output .

sign: manifest
	${GLUON_BUILD_DIR}/contrib/sign.sh ${SECRET_KEY_FILE} output/images/sysupgrade/${GLUON_BRANCH}.manifest

${GLUON_BUILD_DIR}:
	git clone ${GLUON_GIT_URL} ${GLUON_BUILD_DIR}

gluon-prepare: output-clean ${GLUON_BUILD_DIR}
	(cd ${GLUON_BUILD_DIR} \
	  && git remote set-url origin ${GLUON_GIT_URL} \
	  && git fetch origin \
	  && git checkout -q ${GLUON_GIT_REF})
	ln -sfT .. ${GLUON_BUILD_DIR}/site
	$(MAKE) ${GLUON_MAKEFLAGS} update

target-clean:
	+for target in ${GLUON_TARGETS}; do \
		echo ""Cleaning target $$target ...""; \
		(cd ${GLUON_BUILD_DIR} \
		  && $(MAKE) target/linux/clean GLUON_TARGET="$$target") \
	done

gluon-clean:
	rm -rf ${GLUON_BUILD_DIR}

output-clean:
	rm -rf output

clean: gluon-clean output-clean
