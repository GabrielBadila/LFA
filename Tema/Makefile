all: run

.PHONY: clean

build: lexer

lex.yy.c: tema.lex
	flex tema.lex

lexer: lex.yy.c
	g++ -o lexer lex.yy.c -lfl -std=c++11
	
run: build
	./lexer $(arg)

clean:
	rm -f lexer lex.yy.c *~ *.sorted *.err *.out