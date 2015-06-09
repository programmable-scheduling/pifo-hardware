
include Makefile.common

.phony: help

# create folder if needed
%/.created:
	mkdir -p $(dir $@)
	touch $@

$(BUILD): $(BUILD_DIR)/$(DESIGN)/$(BUILD)/.created
	cd $(BUILD_DIR)/$(DESIGN)/$(BUILD); \
	cp $(SRC_DIR)/scripts/$(DESIGN)/Makefile.include .; \
	cp $(SRC_DIR)/scripts/$(DESIGN)/$(BUILD)/* .; \
	make -I $(PROJ_DIR); \
	cd $(PROJ_DIR);

link: $(BUILD_DIR)/$(DESIGN)/$(BUILD)/.created
	ln -s $(BUILD_DIR)/$(DESIGN)/$(BUILD)/$(shell readlink $(BUILD_DIR)/$(DESIGN)/$(BUILD)/current) $(BUILD_DIR)/$(DESIGN)/$(BUILD)/$(NAME)


help:
	echo "make DESIGN=design_name BUILD=[dc|enc]"
