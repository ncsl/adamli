import os, glob

for file in glob.glob("*.5"):
	os.rename(file, file+'.mat')
