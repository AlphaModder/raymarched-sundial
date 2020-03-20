import sys, re

FILES = ["math.glsl", "render.glsl", "scene.glsl"]
MAIN = "render.glsl"
TIGER = "main.glsl"

begin_pattern = re.compile(r"^\/\/\/ BEGIN ([^\s]*)$")
end_pattern = re.compile(r"^\/\/\/ END ([^\s]*)$")
include_pattern = re.compile(r"^#include\s*\"([^\"]*)\"$")
reclude_pattern = re.compile(r"^\/\/\/ (#include\s*\"[^\"]*\")$")

def cat():
    
    with open(TIGER, "w") as writeFile:

        # read main file
        readFiles = {}
        with open(MAIN) as readFile:
            readFiles[MAIN] = readFile.readlines()
        
        # handle includes
        included = {}
        line = 0
        while line < len(readFiles[MAIN]):
            match = include_pattern.match(readFiles[MAIN][line])
            if match != None:
                name = match.group(1)
                # only include if not already included
                if name not in included:
                    with open(name) as readFile:
                        # read included file
                        readFiles[name] = readFile.readlines()
                        if readFiles[name][-1][-1] != "\n":
                            readFiles[name][-1] += "\n"
                    readFiles[MAIN][line:line+1] = ["/// BEGIN " + name + "\n"] + readFiles[name] + ["/// END " + name + "\n"]
                    included[name] = True
                else:
                    readFiles[MAIN][line] = "/// " + readFiles[MAIN][line]
            line += 1 
        
        writeFile.writelines(readFiles[MAIN])

def uncat():
    
    with open(TIGER) as readFile:
        lines = readFile.readlines()
        recursive_uncat(MAIN, lines)

def recursive_uncat(path, lines):
    
    with open(path, "w") as writeFile:
        include = None
        included = []
        for line in lines:
            begin_match = begin_pattern.match(line)
            end_match = end_pattern.match(line)

            if begin_match != None:
                name = begin_match.group(1)
                if include == None:
                    include = name
                else:
                    included.append(line)
            elif end_match != None:
                name = end_match.group(1)
                if include == name:
                    writeFile.write("#include \"" + include + "\"\n")
                    recursive_uncat(include, included)
                    include = None
                    included = []
                else:
                    included.append(line)
            elif include == None:
                reclude_match = reclude_pattern.match(line)
                # check if this is a commented include
                if reclude_match != None:
                    writeFile.write(reclude_match.group(1) + "\n")
                else:
                    writeFile.write(line)
            else:
                included.append(line)


if __name__ == "__main__":
    arg = None
    if len(sys.argv) == 2:
        arg = sys.argv[1]
    if arg == "cat":
        cat()
    elif arg == "uncat":
        uncat()
    else:
        print("Usage: python3 make.py [cat|uncat]")