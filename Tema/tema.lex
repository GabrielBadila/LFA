%{ 
#include<stdio.h>
#include<string.h>
#include<iostream>
#include<vector>
#include<string>
#include<set>
#include<map>

using namespace std;

int i;
bool errorFound = false;
char startSymbol, key;
set<char> states, alphabet;
multimap<char, string> rules;
%}

%s ALPHABET STATES SEPARATOR PRODUCTION_RULES NONTERMINAL REPLACEMENT START_SYMBOL

terminal			{lower-case-letter}|{digit}|{other}
lower-case-letter	[a-df-z]
digit				[0-9]
other				"'"|"-"|"="|"["|"]"|";"|"`"|"\\"|"."|"/"|"~"|"!"|"@"|"#"|"$"|"%"|"^"|"&"|"*"|"_"|"+"|":"|"\""|"|"|"<"|">"|"?"
vid					"e"

alphabet			{terminal}+?
word				{vid}|{terminal}+

CFG					{{states},{alphabet},{production-rules},{start-symbol}}
state				{nonterminal}|{terminal}
states				{state}+
production-rule		\({whitespace}{nonterminal}{whitespace},{whitespace}{replacement}{whitespace}\)
production-rules	{production-rule}+?
nonterminal			{upper-case-letter}
replacement			{vid}|{state}+
upper-case-letter	[A-Z]
start-symbol		{upper-case-letter}

whitespace			[ \t\r\n]*

%%
<INITIAL>
	{whitespace}"("{whitespace}"{"{whitespace} {
		BEGIN(STATES);
	}
			
<STATES>{
	{state}{whitespace}","{whitespace} {	
		states.insert(yytext[0]);
	}

	{state}{whitespace}"}"{whitespace}","{whitespace}"{"{whitespace} {
		states.insert(yytext[0]);
		BEGIN(ALPHABET);
	}

	{state}{whitespace}"}"{whitespace}","{whitespace}"{"{whitespace}"}"{whitespace}","{whitespace}"{"{whitespace} {
		states.insert(yytext[0]);
		BEGIN(PRODUCTION_RULES);
	}
}
		
<ALPHABET>{
	{terminal}{whitespace}","{whitespace} {
		alphabet.insert(yytext[0]);
	}

	{terminal}{whitespace}"}"{whitespace}","{whitespace}"{"{whitespace} {
		alphabet.insert(yytext[0]);
		BEGIN(PRODUCTION_RULES);
	}
}	
	
<PRODUCTION_RULES>{
	"("{whitespace} {
		BEGIN(NONTERMINAL);
	}

	"}"{whitespace}","{whitespace} {
		BEGIN(START_SYMBOL);
	}
}
	
<NONTERMINAL>
	{nonterminal}{whitespace}","{whitespace} {
		key = yytext[0];
		BEGIN(REPLACEMENT);
	}

<REPLACEMENT>
	{replacement} {
		rules.emplace(key, yytext);
		BEGIN(SEPARATOR);
	}

<SEPARATOR>{
	{whitespace}")"{whitespace}","{whitespace}"("{whitespace} {
		BEGIN(NONTERMINAL);
	}

	{whitespace}")"{whitespace}"}"{whitespace}","{whitespace} {
		BEGIN(START_SYMBOL);
	}
}
	
<START_SYMBOL>
	{start-symbol}{whitespace}")"{whitespace} {
		startSymbol = yytext[0];
	}	
	
	
.	{
		// afiseaza eroare de sintaxa daca citeste ceva ce nu corespunde gramaticii
		errorFound = true;
		fprintf(stderr,"Syntax error\n");
		return 0;
	}

%%

// functie ce verifica aparitia erorilor semantice
void checkSemanticError() {
	for (auto it : alphabet) {
		if (states.find(it) == states.end()) {
			errorFound = true;
			fprintf(stderr, "Semantic error\n");
			return;
		}
	}

	for(auto it : states) {
		if (!isupper(it) && alphabet.find(it) == alphabet.end()) {
			errorFound = true;
			fprintf(stderr, "Semantic error\n");
			return;
		}
	}

	if (states.find(startSymbol) == states.end()) {
		errorFound = true;
		fprintf(stderr, "Semantic error\n");
		return;
	}

	for(auto it:rules) {
		if(states.find(it.first) == states.end()) {
			errorFound = true;
			fprintf(stderr, "Semantic error\n");
			return;
		}

		for (i = 0; i < it.second.length(); i++) {
			if (states.find(it.second[i]) == states.end() && it.second[i] != 'e') {
				errorFound = true;
				fprintf(stderr, "Semantic error\n");
				return;
			}
		}
	}
}

// functie ce verifica daca limbajul generat contine sirul vid
void has_e () {
	int dim = 0;
	set<char> auxSet = {'e'};

	while (dim != auxSet.size()) {
		dim = auxSet.size();
		for (auto it : rules) {
			if (auxSet.find(it.first) == auxSet.end()) {
				bool found = true;
				for (i = 0; i < it.second.length(); i++) {
					if (auxSet.find(it.second[i]) == auxSet.end()) {
						found = false;
						break;
					}
				}

				if (found == true) {
					auxSet.insert(it.first);
					if (it.first == startSymbol)
						break;
				}
			}
		}
	}

	if (auxSet.find(startSymbol) == auxSet.end())
		cout <<"No\n";
	else
		cout <<"Yes\n";
}


// functie ce verifica daca limbajul este vid sau intoarce nonterminalii inutili 
// in functie de argumentul primit
void checkLanguage(char* arg) {
	int dim = -1;
	set<char> auxSet;

	while (dim != auxSet.size()) {
		dim = auxSet.size();
		for(auto it : rules) {
			if (auxSet.find(it.first) == auxSet.end()) {
				bool found = true;
				for (i = 0; i < it.second.length(); i++) {
					if (isupper(it.second[i]) && auxSet.find(it.second[i]) == auxSet.end()) {
						found = false;
						break;
					}
				}

				if (found == true) {
					auxSet.insert(it.first);
				}
			}
		}
	}

	// afisez nonterminalii inutili sau verific daca limbajul e vid
	if (!strcmp(arg, "--useless-nonterminals")) {
		for (auto it : states) {
			if (isupper(it) && auxSet.find(it) == auxSet.end())
				cout << it << "\n";
		}
	}
	else if (!strcmp(arg, "--is-void")) {
		if (auxSet.find(startSymbol) == auxSet.end())
			cout << "Yes\n";
		else
			cout << "No\n";
	}
}


int main(int argc, char **argv) {

	if((argc != 2) || (strcmp(argv[1], "--is-void") != 0 && strcmp(argv[1], "--has-e") != 0 && strcmp(argv[1], "--useless-nonterminals") != 0)) {
		fprintf(stderr, "Argument error\n");
		return 0;
	}

	FILE* f = fopen("grammar", "rt");
   	yyrestart(f);
	yylex();

	// verifica eroarea semantica
	if (!errorFound) {
		checkSemanticError();
	}

	// verifica daca limbajul contine sirul vid
	if (!errorFound && !strcmp(argv[1], "--has-e")) { 
		has_e();
	}

	// verifica daca limbajul este vid sau afiseaza nonterminalii inutili
	if (!errorFound) { 
		checkLanguage(argv[1]);
	}

	return 0;
}