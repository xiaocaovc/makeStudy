# ------------头,源文件目录------------
ROOT_DIR=.
GTEST_INC_DIR = "/usr/local/include"
GMOCK_INC_DIR = "/usr/local/include"
GMOCK_LIB_DIR = "/usr/local/lib"

INCLUDES:=$(ROOT_DIR) $(GTEST_INC_DIR) $(GMOCK_INC_DIR)

# 除了当前目录外，其他的源代码文件目录           
SRCDIR:=$(ROOT_DIR)

# -----------库文件----------------
# 静态库目录
LIBDIR:=.
# 静态库文件名
LIBS=
# 动态库SO目录
LIBSODIR:=$(GMOCK_LIB_DIR)
# 动态库SO
LIBSO= -lpthread -lrt -lgcov -lgmock 

# ---------------文件----------------
# 源文件
SOURCE=  main.cpp a.cpp b.cpp
# obj文件
OBJS = $(patsubst %.cpp,%.o,$(SOURCE))
# 依赖文件
DEPS = $(patsubst %.cpp,%.d,$(SOURCE))
# 输出目录
OUTDIR=output
# 需要覆盖的源文件
GCOVCPP= main.cpp

# 可执行文件名
TARGET= main

# --------------依赖文件-------------
# 依赖文件的搜索路径
VPATH= $(INCLUDES) $(SRCDIR)

# --------------命令-----------------
# 是否调试还是Release
DGDB= -g
# 命令
RM=-rm -fr

# C预处理器参数
CFLAGS= $(DGDB) -Wall
# C++预处理器参数
CPPFLAGS = $(patsubst %,-I%,$(INCLUDES)) $(patsubst %,-I%,$(SRCDIR))
# C C++语言编译选项
CXXFLAGS = $(CFLAGS) -Wextra -pthread -g3 -fprofile-arcs -ftest-coverage
# 连接选项:库,路径
LDFLAGS =  $(patsubst %,-L%,$(LIBDIR)) $(patsubst %,-L%,$(LIBSODIR)) $(LIBSO) $(LIBS)

# CPU
ARCH ?= x86
ifeq ($(ARCH), x86)
CC=gcc
CXX=g++
LD= ld
AR= ar
#CFLAGS += -m32
#CXXFLAGS += -m32
#LDFLAGS += -m32
else
CMD_PREFIX=arm-linux-gnueabi
CXX=$(CMD_PREFIX)-g++
CC=$(CMD_PREFIX)-gcc
LD=$(CMD_PREFIX)-ld
AR=$(CMD_PREFIX)-ar
endif

GET ?=N


.PHONY : clean all

# 最终目标
all : $(TARGET)

# 可执行文件
$(TARGET) : $(OBJS)
	$(CXX) $^ $(LDFLAGS)  -o $@
	$(Get-Result)
	
# 源文件->obj文件
$(OBJS):%.o:%.cpp
	$(CXX) -c $< $(CPPFLAGS) $(CXXFLAGS) -o $@

# 依赖文件生成规则
%.d : %.cpp
	@rm -f $@; \
		$(CXX) -MM  $(CPPFLAGS) $< > $@.$$$$; \
		sed 's,\($*\)\.o[ :]*,\1.o $@ : ,g' < $@.$$$$ > $@; \
		rm -f $@.$$$$''

-include $(DEPS)

clean :
	$(RM) *.d *.o $(TARGET) output *.gcda *.gcno

# 结果命令包

ifeq ($(GET), Y)
define Get-Result
@echo -e "\033[32m"
@echo
@echo '*'
@echo '**************** Generating HTML output ****************'
@echo -e "\033[0m"
lcov --directory . --zerocounters
@echo -e "\033[32m"
@echo "**************** execute $(TARGET) ****************"
@echo -e "\033[0m"
@echo -e "\033[33m"
./$(TARGET)
@echo -e "\033[0m"
@echo -e "\033[32m"
@echo "**************** create OutDir:$(OUTDIR) ****************"
@echo -e "\033[0m"
rm -fr $(OUTDIR)
-mkdir $(OUTDIR)
-mv $(GCOVCPP:.cpp=.gcno) $(GCOVCPP:.cpp=.gcda) $(OUTDIR)
$(RM) *.gcno *.gcda
@echo -e "\033[32m"
@echo "**************** create info file ****************"
@echo -e "\033[0m"
lcov --rc lcov_branch_coverage=1 --capture --directory . --output-file app.info --test-name test_noargs --no-external
genhtml --rc lcov_branch_coverage=1 app.info --output-directory ./$(OUTDIR)/outhtml --title "$(GCOVCPP) coverage test" --show-details --legend
@echo -e "\033[32m"
@echo "*******************************************************************************"
@echo "*                                                                             *"
@echo "    Open ./$(OUTDIR)/outhtml/index.html to see the result of coverage test"
@echo "*                                                                             *"
@echo "*******************************************************************************"
@echo -e "\033[0m"
endef
else
define Get-Result
@echo -e "\033[32m"
@echo "*******************************************************************************"
@echo "*                                                                             *"
@echo "      Run $(TARGET) to see the result "
@echo "*                                                                             *"
@echo "*******************************************************************************"
@echo -e "\033[0m"
endef
endif


