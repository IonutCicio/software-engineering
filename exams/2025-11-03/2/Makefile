CC := g++
CFLAGS := -lm -std=c++11 -O3 
DEBUG_FLAGS := -lm -std=c++11 -ggdb -g3 -Wall -Wextra -pedantic

MOCC_LIB := ../../../mocc
MOCC_CPP := $(wildcard $(MOCC_LIB)/*.cpp)
MOCC_OBJ := $(MOCC_CPP:.cpp=.o)

LOCAL_HPP := $(wildcard *.hpp)
LOCAL_CPP := $(wildcard *.cpp)
LOCAL_OBJ := $(LOCAL_CPP:.cpp=.o)


main: $(MOCC_OBJ) $(LOCAL_OBJ)
	$(CC) $(CFLAGS) $^ -o $@

debug: $(MOCC_CPP) $(LOCAL_CPP)
	$(CC) $(DEBUG_FLAGS) $^ -o $@

main.o: main.cpp $(LOCAL_HPP)
	$(CC) $(CFLAGS) -c $< -o $@

%.o: %.cpp 
	$(CC) $(CFLAGS) -c $< -o $@

.PHONY: clean

clean:
	rm -f main debug *.o $(MOCC_LIB)/*.o **/*.o
