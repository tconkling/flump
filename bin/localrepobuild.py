#!/usr/bin/env python
'''Builds swcs for base projects and copies them to the user's maven repo'''

import optparse, os, shutil, stat, subprocess, sys, time
from xml.etree import ElementTree

DEBUG = False
def debug(msg, *args):
    if not DEBUG:
        return
    if args:
        detail = ', '.join(('%s=%s' % (args[i], args[i + 1]) for i in range(len(args))[::2]))
        msg = "%s [%s]" % (msg, detail)
    print msg

def mtime(path):
    if os.path.exists(path):
        return os.stat(path)[stat.ST_MTIME]
    return 0

def j(*components):
    return '/'.join(components)

def makeasbuilder(root, lib, result=None,
    srcs=['src/main/as', 'src/main/resources', 'src/main/swfresources'],
    ngscript=None, pom='as-pom.xml', nailguntarget='aslib', deploy=True, clean=False):
    if result is None:
        result = 'dist/' + lib + 'lib.swc'
    if ngscript is None:
        ngscript = 'dist/%s.ng.sh' % lib
    builder = Builder(root, lib, result, srcs, ['sh', ngscript], pom,
            buildforupstream=result.endswith('.swf'), deploy=deploy)
    scriptgenerationreason = None
    scriptpath = j(builder.base, ngscript)
    builder.srcs.append(scriptpath)
    if clean:
        print "Cleaning", lib
        if builder.execute(['ant', 'clean']) != 0:
            print "Cleaning failed"
            sys.exit(1)
    if not os.path.exists(scriptpath):
        scriptgenerationreason = "Creating"
    elif mtime(builder.pom) > mtime(scriptpath) or mtime(j(builder.base, "build.xml")) > mtime(scriptpath):
        scriptgenerationreason = "Refreshing"
    if scriptgenerationreason is not None:
        print scriptgenerationreason, "nailgun script", scriptpath, "for", lib
        if builder.execute(['ant', '-Dngwrite=true', nailguntarget]) != 0:
            print "Creating the nailgun script failed"
            sys.exit(1)
    return builder

def makejavabuilder(root, lib, result=None, srcs=['src/main/java', 'src/main/resources', 'etc'],
    buildcmd=['ant', 'dist'], pom='pom.xml'):
    if result is None:
        result = 'dist/' + lib + '.jar'
    return Builder(root, lib, result, srcs, buildcmd, pom)

class Builder(object):
    def __init__(self, root, lib, result, srcs, buildcmd, pom, buildforupstream=False, deploy=True):
        self.lib = lib
        self.base = j(root, lib)
        self.cmd = buildcmd
        self.pom = j(self.base, pom)
        self.srcs = [j(self.base, src) for src in srcs]
        # Rebuild if our pom or build.xml changed
        self.srcs.extend([self.pom, j(self.base, 'build.xml')])
        self.result = j(self.base, result)
        self.artifact = self.makeresultmavenpath()
        self.previousmod = {}
        self.built = False
        self.buildforupstream = buildforupstream
        self.deploy = deploy
        debug("Created", "lib", lib, "base", self.base, "srcs", srcs, "cmd", self.cmd, "pom", pom,
                "result", result, "artifact", self.artifact, "deploy", self.deploy,
                "buildforupstream", self.buildforupstream)

    def makeresultmavenpath(self):
        tree = ElementTree.parse(self.pom)
        g = tree.findtext("{http://maven.apache.org/POM/4.0.0}groupId").replace('.', '/')
        a = tree.findtext("{http://maven.apache.org/POM/4.0.0}artifactId")
        p = tree.findtext("{http://maven.apache.org/POM/4.0.0}packaging")
        v = tree.findtext("{http://maven.apache.org/POM/4.0.0}version")
        path = '~/.m2/repository/%s/%s/%s/%s-%s.%s' % (g, a, v, a, v, p)
        return os.path.expanduser(path)

    def execute(self, cmd):
        return subprocess.call(cmd, cwd=self.base)

    def build(self, force=False, quiet=False, upstreambuilt=False):
        self.built = False
        force = force or (upstreambuilt and self.buildforupstream)
        if not force:
            if not quiet:
                debug("Checking", "lib", self.lib)
            modified = self.needsBuild()
            if not modified:
                debug("Not modified", "lib", self.lib)
                return True
            elif modified == [self.result]:
                print self.result, "doesn't exist"
            elif len(modified) < 10:
                print self.lib, "modified", modified
            else:
                print self.lib, len(modified), "files modified"
        else:
            print "Building", self.lib
        if self.execute(self.cmd) != 0:
            debug("Failed", "lib", self.lib)
            return False
        if self.deploy:
            print "Copying", self.result, "to", self.artifact
            if not os.path.exists(os.path.dirname(self.artifact)):
                os.makedirs(os.path.dirname(self.artifact))
            shutil.copy(self.result, self.artifact)
        self.built = True
        return True

    def needsBuild(self):
        if not os.path.exists(self.result): # Rebuild if our file disappeared
            debug("No result", "lib", self.lib, "result", self.result)
            return [self.result]
        self.previousmod = {}
        return self.modifiedSinceBuildAttempt(True)

    def modifiedSinceBuildAttempt(self, update=False):
        if self.deploy:
            result = mtime(self.artifact)
        else:
            result = mtime(self.result)

        modified = []
        def check(fullfn):
            time = mtime(fullfn)
            if time > self.previousmod.get(fullfn, 0) and time > result:
                modified.append(fullfn)
            if update or fullfn not in self.previousmod:
                self.previousmod[fullfn] = time
        for src in self.srcs:
            if os.path.isdir(src):
                for path, dirs, files in os.walk(src):
                    if '.svn' in dirs: # .svn can be modified without any src changes
                        dirs.remove('.svn')
                    for fn in files:
                        check(j(path, fn))
            else:
                check(src)
        return modified

def buildall(builders, buildrequired=False, retry=False, quiet=False, onfailure=None,
        onsuccess=None):
    ranbuild = [] # builds run in the last try
    def anybuilt():
        return any((builder.built for builder in builders))
    def build(builder):
        ranbuild.append(builder)
        worked = builder.build(quiet=quiet, upstreambuilt=anybuilt())
        if not worked:
            if onfailure:
                subprocess.check_call(onfailure, shell=True)
            if not retry:
                sys.exit(1)
        return worked

    def runbuildstillfailure():
        return all((build(builder) for builder in builders))
    while not runbuildstillfailure() or (not anybuilt() and buildrequired):
        print "Retrying builds when changed till all succeed"
        buildrequired = False
        quiet = True
        # For the builds that ran in the last time in the outer loop, check for a new modification
        # to their source every half-second
        while not any((builder.modifiedSinceBuildAttempt() for builder in ranbuild)):
            time.sleep(.5)
        ranbuild = [] # Reset the builds that ran for the coming calls to build
    if onsuccess:
        subprocess.check_call(onsuccess, shell=True)

def buildasprojects(base, buildermaker, target="client", assemblage=None):
    parser = optparse.OptionParser(usage="Usage: asbuild [<swf building ant target>]")
    parser.add_option("--require-build", dest="buildrequired", default=False, action="store_true",
            help="Wait until something changes and a build occurs")
    parser.add_option("--on-failure", dest="onfailure", default=None,
            help="Command to run when a build fails")
    parser.add_option("--on-success", dest="onsuccess", default=None,
            help="Command to run when the whole sequence succeeds")
    parser.add_option("--clean", dest="clean", default=False, action="store_true",
            help="Should all the projects be cleaned")
    parser.add_option("--assemblage", dest="assemblage", default=assemblage,
        help="The directory for assemblage. Defaults to ../assemblage")
    parser.add_option("-v", "--verbose", dest="verbose", default=False,
        action="store_true", help="Print out more detail on what's happening")

    options, args = parser.parse_args()

    if args:
        target = args[0]

    # Find our paths
    if options.assemblage:
        assemblage = options.assemblage
    else:
        assemblage = base + "/assemblage"

    # Add aspirin to the python path so we can import_action
    sys.path.append(assemblage + "/aspirin/bin")
    import import_action

    global DEBUG
    DEBUG = options.verbose

    def b(*args, **kwargs):
        kwargs["clean"] = options.clean
        return makeasbuilder(*args, **kwargs)

    builders = buildermaker(b, assemblage, target)
    for b in builders:
        for src in b.srcs:
            import_action.process(src)
    # BUILD!
    try:
        buildall(builders, options.buildrequired, retry=options.buildrequired,
            onfailure=options.onfailure, onsuccess=options.onsuccess)
    except KeyboardInterrupt:
        pass

if __name__ == "__main__":
    parser = optparse.OptionParser()
    parser.add_option("--assemblage", dest="assemblage",
            default=j(*os.path.dirname(__file__).split('/')[:-2]),
            help="Location of assemblage")
    parser.add_option("--require-build", dest="buildrequired", default=False, action="store_true",
            help="Wait until something changes and a build occurs")
    parser.add_option("--check", dest="checks", default="samskivert,depot,narya,nenya,vilya",
            help="Assemblage projects to build")
    parser.add_option("--project", dest="projects", default=[], action="append",
            help="Directories of additional projects to build")
    parser.add_option("--on-failure", dest="onfailure", default=None,
            help="Command to run when a build fails")
    parser.add_option("--on-success", dest="onsuccess", default=None,
            help="Command to run when the whole sequence succeeds")
    parser.add_option("-v", "--verbose", dest="verbose", default=False,
        action="store_true", help="Print out more detail on what's happening")
    options, args = parser.parse_args()

    DEBUG = options.verbose

    checks = options.checks.split(',')
    builders = []
    for proj in  ["samskivert", "depot"]:# samskivert and depot use package instead of dist
        if proj in checks:
            checks.remove(proj)
            builders.append(makejavabuilder(options.assemblage, proj, buildcmd=["ant", "package"]))
    builders.extend(makejavabuilder(options.assemblage, proj) for proj in checks)
    for projs in options.projects:
        for proj in projs.split(','):
            pieces = os.path.expanduser(proj).split('/')
            builders.append(makejavabuilder(j(*pieces[:-1]), pieces[-1]))
    try:
        buildall(builders, options.buildrequired, retry=options.buildrequired, onfailure=options.onfailure, onsuccess=options.onsuccess)
    except KeyboardInterrupt:
        pass
