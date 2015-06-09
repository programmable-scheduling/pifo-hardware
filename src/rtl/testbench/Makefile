
include Makefile.inc

.PHONY: clean

all:
ifeq ($(RUN_VCS),1)
	echo "Build model"
	$(RM) -rf csrc $(SIMV_NAME).* $(SIMV_NAME)
	vcs -f $(INCLUDE_FILE) $(VCS_OPTIONS) -l simv.log
endif
	mkdir -p $(LOG_FOLDER)
	date
ifeq ($(REDIRECT_LOG), 1)
	./$(SIMV_NAME) $(SIMV_OPTIONS) > $(LOG_FOLDER)/$(LOG_NAME)
else
	./$(SIMV_NAME) $(SIMV_OPTIONS)
endif
	date

clean:
	$(RM) simv.log srec_parse.log ucli.key
	$(RM) -rf csrc $(SIMV_NAME).* $(SIMV_NAME)

