START_PAGE := 7623
END_PAGE   := 7624

include common.mak

PAGE_SEQUENCES = $(shell seq $(START_PAGE) $(END_PAGE))

PAGE_BASE_URL = http://jandan.net/pic/page-

all: metadata

define pagerule
$$(CACHE_DIR)/page-$(1).html:
	@mkdir -pv $$(dir $$@)
	$(WGET) "$$(PAGE_BASE_URL)$(1)" -U $(USER_AGENT) -O $$@

$$(META_DIR)/page-$(1).json: $$(CACHE_DIR)/page-$(1).html
	@mkdir -pv $$(dir $$@)
	cat $$< | pup '.commentlist .text img json{}' > $$@

$$(MAK_DIR)/page-$(1).mak: $$(META_DIR)/page-$(1).json
	@mkdir -pv $$(dir $$@)
	echo "include common.mak" > $$@
	cat $$< | jq '.[] | if has("org_src") then .org_src else .src end' \
		| sed -nE 's/"(http.*)\/([^\/]*)"/$$$$(DIST_DIR)\/page-$(1)\/\2:\
					,;@mkdir -pv $$$$(dir $$$$@)\
					,;$$$$(WGET) \1\/\2 -O $$$$@\
					,,images: $$$$(DIST_DIR)\/page-$(1)\/\2,/gp' \
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


.PHONY: all metadata images clean*
