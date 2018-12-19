import yaml
import os
import string


jobList = os.listdir("./jjb")
artifactList = []
scriptsUsed = []
scripList = os.listdir("./scripts")
test = []

for job in jobList:
    if "job" in job or "libpvm" in job:
        if "jenkins_jobs.ini" in job:
            continue
        f = open("./jjb/" + job, "r")
        test = test + yaml.load(f)

graphOutput = 'digraph G {\n'

def getJobDependancies(i, graphOutput):
    try:
        currentJob = i["job-template"]["name"]

        for j in i["job-template"]["publishers"]:
            if "trigger-parameterized-builds" in j:
                try:
                    for k in j["trigger-parameterized-builds"]:
                        try:
                            for l in k['project']:
                                graphOutput = graphOutput + '   "' + currentJob + '" -> "CADETS/bsd/{branch}/' + l + '";\n'
                        except:
                            continue
                except:
                    continue
            elif "trigger" in j:
                try:
                    l = j["trigger"]["project"]
                    graphOutput = graphOutput + '   "' + currentJob + '" -> "' + l + '";\n'
                except:
                    continue

        for j in i["job-template"]["triggers"]:
            try:
                l = j["reverse"]["jobs"]
                l = l.partition("/")
                if l[len(l) - 1] == "":
                    l = l[0]
                else:
                    l = l[len(l) - 1]
                if ".." in l:
                    l = "CADETS" + l[2:]
                graphOutput = graphOutput + '   "' + l + '" -> "' + currentJob + '";\n'
            except:
                continue
    except:
        return graphOutput
    return graphOutput

def getDependanciesOnArtifacts(i, graphOutput):
    try:
        currentJob = i["job-template"]["name"]

        for j in i["job-template"]["builders"]:
            if "copyartifact" in j:
                try:
                    parser = j["copyartifact"]['filter']
                    parser = string.split(parser, "/")
                    for part in parser:
                        subParser = string.split(part, ",")
                        for subPart in subParser:
                            if "." in subPart:
                                artifactList.append(subPart)
                                graphOutput = graphOutput + '   "' + subPart + '" -> "' + currentJob + '" [style = dashed];\n'
                except:
                    continue

    except:
        return graphOutput
    return graphOutput

def getDependanciesOnScripts(i, graphOutput):
    try:
        currentJob = i["job-template"]["name"]

        for j in i["job-template"]["builders"]:
            if "shell" in j:
                try:
                    for script in scripList:
                        if script in j["shell"]:
                            scriptsUsed.append(script)
                            graphOutput = graphOutput + '   "' + script + '" -> "' + currentJob + '" [style = bold];\n'
                except:
                    continue

    except:
        return graphOutput
    return graphOutput

def getArtifactDependancies(i, graphOutput):
    try:
        currentJob = i["job-template"]["name"]

        for j in i["job-template"]["publishers"]:
            if "archive" in j:
                try:
                    parser = j["archive"]['artifacts']
                    parser = string.split(parser, "/")
                    for part in parser:
                        subParser = string.split(part, ",")
                        for subPart in subParser:
                            if "." in subPart:
                                artifactList.append(subPart)
                                graphOutput = graphOutput + '   "' + currentJob + '" -> "' + subPart + '" [style = dashed];\n'
                except:
                    continue
    except:
        return graphOutput
    return graphOutput

for i in test:
    graphOutput = getJobDependancies(i, graphOutput)
    graphOutput = getDependanciesOnArtifacts(i, graphOutput)
    graphOutput = getDependanciesOnScripts(i, graphOutput)

scriptsUsed = list(set(scriptsUsed))
artifactList = list(set(artifactList))
for i in test:
    graphOutput = getArtifactDependancies(i, graphOutput)

for i in scriptsUsed:
    scriptContents = open("./scripts/" + i, "r")
    for art in artifactList:
        for line in scriptContents:
            if art in line:
                graphOutput = graphOutput + '   "' + art + '" -> "' + i + '" [style = dashed];\n'

artifactList = list(set(artifactList))

for art in artifactList:
    graphOutput = graphOutput + '   "' + art + '" [shape = rectangle];\n'

for script in scriptsUsed:
    graphOutput = graphOutput + '   "' + script + '" [shape = diamond];\n'

graphOutput = graphOutput + "}"
output = open("graph.txt", "w")
output.write(graphOutput)
output.close()