#!/bin/bash -l

numWins=45
NprocperNode=8

for ((iWin=1; iWin<=numWins; iWin++))
do
	currentNode=$((($iWin+7)/NprocperNode))

	echo $currentNode
done