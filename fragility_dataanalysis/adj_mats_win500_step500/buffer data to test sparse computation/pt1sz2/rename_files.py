import os, glob
import types

for file in glob.glob("*.mat"):
	# print file
	indexcount = file.count('.')
	index = file.find('.')
	newfile = file 
	if indexcount > 1:
		newfile = file[0:index] + '_' + file[index+1:len(file)]
	
	os.rename(file, newfile)
