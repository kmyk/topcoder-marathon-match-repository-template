.PHONY: build
.DEFAULT: build

PROBLEM := SameColorPairs
CXX := g++
CXXFLAGS := -std=c++11 -Wall -O2 -g -DLOCAL

build: a.out

run: a.out tester.jar
	java -jar tester.jar -exec ./a.out

a.out: main.cpp ${PROBLEM}.cpp
	${CXX} ${CXXFLAGS} $<

${PROBLEM}Vis.class: ${PROBLEM}Vis.java
	javac $<

tester.jar: ${PROBLEM}Vis.class
	jar cvfe tester.jar ${PROBLEM}Vis *.class

URL := https://community.topcoder.com/longcontest/?module=ViewProblemStatement&rd=17143&pm=14889
submit:
	oj submit '${URL}' ${PROBLEM}.cpp -y --open
submit/full:
	oj submit '${URL}' ${PROBLEM}.cpp -y --open --full

standings:
	python3 -c 'import onlinejudge, tabulate ; url = "${URL}" ; problem = onlinejudge.dispatch.problem_from_url(url) ; headers, table = problem.get_standings() ; print(tabulate.tabulate(map(lambda row: row.values(), table), headers=headers, tablefmt="github"))'
