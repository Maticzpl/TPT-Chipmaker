#!/bin/python3

from os import listdir
from os.path import isfile, join, isdir


def listFilesInDirRecursive(dirName):
    fileList = listdir(dirName)
    fileList.sort()
    out = list()

    for entry in fileList:
        path = join(dirName, entry)

        if isdir(path):
            out = out + listFilesInDirRecursive(path)
        else:
            out.append(path)
                
    return out


combinedStr = ""

for filePath in listFilesInDirRecursive('src'):
    file = open(filePath,'r')
    combinedStr += file.read()
    combinedStr += '\n\n'


finalFile = open("Lua Chipmaker.lua","w+t")
  
finalFile.seek(0)
finalFile.write(combinedStr)
finalFile.truncate()
  
finalFile.close()