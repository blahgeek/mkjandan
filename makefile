START_PAGE := 7623
END_PAGE   := 7624

include common.mak

PAGE_SEQUENCES = $(shell seq $(START_PAGE) $(END_PAGE))

JANDAN := pic
PAGE_BASE_URL = http://jandan.net/$(JANDAN)/page-

all: metadata

directories:
	mkdir -pv $(CACHE_DIR)
	mkdir -pv $(META_DIR)
	mkdir -pv $(MAK_DIR)
	mkdir -pv $(DIST_DIR)

define pagerule

directory-page-$(1): | directories
	@mkdir -pv $$(DIST_DIR)/page-$(1)

$$(CACHE_DIR)/page-$(1).html: | directory-page-$(1)
	@echo "[WGET] Page $(1)"
	@$(WGET) "$$(PAGE_BASE_URL)$(1)" -U $(USER_AGENT) -O $$@ 2> /dev/null

$$(META_DIR)/page-$(1).json: $$(CACHE_DIR)/page-$(1).html
	@echo "[META] Page $(1)"
	@cat $$< | pup '.commentlist .text img json{}' > $$@

$$(MAK_DIR)/page-$(1).mak: $$(META_DIR)/page-$(1).json
	@echo "[MAK]  Page $(1)"
	@echo "include common.mak" > $$@
	@cat $$< | jq '.[] | if has("org_src") then .org_src else .src end' \
		| cat -n \
		| sed -nE 's/^[[:space:]]*([0-9]+)[[:space:]]*"(http.*)\/([^\/]*)"/$$$$(DIST_DIR)\/page-$(1)\/\1-\3:\
					,;@echo "[DOWN] $$$$@"\
					,;@$$$$(WGET) \2\/\3 -O $$$$@ 2> \/dev\/null\
					,,images: $$$$(DIST_DIR)\/page-$(1)\/\1-\3,/gp' \
		| tr ',' '\n' | tr ';' '\t' \
		>> $$@

metadata: $$(META_DIR)/page-$(1).json

include $$(MAK_DIR)/page-$(1).mak

endef

$(foreach page,$(PAGE_SEQUENCES),$(eval $(call pagerule,$(page))))

clean-cache:
	rm -rf $(CACHE_DIR)

clean-meta:
	rm -rf $(META_DIR) $(MAK_DIR)

clean-all: clean-cache clean-meta
	rm -rf $(DIST_DIR)


.PHONY: all metadata images clean* director*
