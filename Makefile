PROJECT_NAME = $(shell basename $(CURDIR))

CC_BUILD = g++
SRC_EXTN = mm
CC_FLAGS = -c -Wall -std=c++11 -Wno-char-subscripts -Iinclude -I/usr/local/include -O3
LD_FLAGS = -L/usr/local/lib        \
           -lmysqlcppconn          \
           -framework CoreWLAN     \
           -framework Cocoa        \
           -lboost_system          





rwildcard = $(wildcard $1$2) $(foreach d, $(wildcard $1*), $(call rwildcard,$d/,$2))

SRC_FILES = $(call rwildcard,src/,*.$(SRC_EXTN))
OBJ_FILES = $(addprefix .bin/,$(SRC_FILES:.$(SRC_EXTN)=.o))

all: header $(SRC_FILES) $(PROJECT_NAME)

LIBRARY= lib$(PROJECT_NAME).a
EXECUTABLE= $(PROJECT_NAME)

$(PROJECT_NAME): $(OBJ_FILES)
	@echo "[link]"
	@$(CC_BUILD) $(OBJ_FILES) $(LD_FLAGS) -o $@
	@echo "[done] $(EXECUTABLE): Compilation finished!"

$(OBJ_FILES): $(SRC_FILES)
	@echo "[make] $(subst .bin/,,$*.$(SRC_EXTN)) -> $@"
	@mkdir -p $(dir $@)
	@$(CC_BUILD) $(CC_FLAGS) $(subst .bin/,,$*.$(SRC_EXTN)) -o $@

lib:
	ar rcs $(LIBRARY) $(OBJ_FILES)
	@echo "[make] $(LIBRARY): Compilation finished!"

clean:
	@echo "[make] clean: Deleting object files"
	@rm -r .bin/*
	@echo "[make] clean: Deleting builds"
	@rm -f $(EXECUTABLE)

rebuild: clean all
	

destroy:
	@rm -f $(EXECUTABLE)
	@rm -rf .bin/ include/ .proj/ src/

project:
	@mkdir -p .proj
	@touch .proj/$(PROJECT_NAME).sublime-project
	@echo "{\n\t\"folders\":\n\t[\n\t\t{\"path\": \"$(CURDIR)\"\n\t\t,\"file_exclude_patterns\": [\"$(PROJECT_NAME)\"],\"folder_exclude_patterns\": [\".proj\", \".bin\"]\n\t\t}\n\t]\n}" > .proj/$(PROJECT_NAME).sublime-project
	
dummy:
	@echo "[make] creating template main.cpp"
	@mkdir src
	@touch src/main.cpp
	@echo "#include <iostream>\n\nint main(int argc, char** argv)\n{\n\tstd::cout << \"Hello World!\";\n\tstd::cout << std::endl;\n}\n" > src/main.cpp
	

create: header project dummy
	@echo "[make] creating project folders."
	@mkdir .bin
	@mkdir include
	@echo "[done] $(PROJECT_NAME) project ready! use 'make sublime' to open project."

sublime:
	@open /Applications/Sublime\ Text\ 2.app .proj/$(PROJECT_NAME).sublime-project

run: all
	@clear
	@./$(PROJECT_NAME)

info:
	@echo ""
	@echo "Project Information ($(PROJECT_NAME))"
	@echo "--------------------------------------------------"
	@echo ""
	@echo "Lines of Code: $(shell wc -l `find include -name '*.h' -print && find src -name '*.cpp' -print` | grep total)"
	@echo ""
	@wc -l `find include -name '*.h' -print && find src -name '*.cpp' -print` | sort --reverse | grep -v total

header:
	@echo "--------------------------------------------------------------------------------"
	@echo "\n\n\n\n\n\n\n\n\n\n\n"
	@echo "                                      MAKE"
	@echo "      Project : $(PROJECT_NAME)"
	@echo "       Author : Denis Coady"
	@echo ""
	@echo "     Location : $(shell pwd)"
	@echo "\n\n\n\n\n\n\n\n\n\n\n"
	@echo "--------------------------------------------------------------------------------"
	
class:
	@touch include/$(name).h
	@touch src/$(name).cpp
	@echo "#ifndef INCLUDE_$(shell echo $(name) | tr a-z A-Z)_H\n#define INCLUDE_$(shell echo $(name) | tr a-z A-Z)_H\n\nclass $(name) {\n\tprivate:\n\n\tpublic:\n\t\t$(name) ();\n\t\t~$(name) ();\n};\n\n\n#endif" > include/$(name).h
	@echo "#include <$(name).h>\n\n$(name)::$(name) ()\n{\n}\n\n$(name)::~$(name) ()\n{\n}" > src/$(name).cpp

