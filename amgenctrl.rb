#!/usr/bin/env /home/nemoto_hideaki/.rvm/bin/ruby-1.9.3-p125

=begin

 Specifications
 +- control the generation of apt repositories created by apt-mirror
 +- repository name must be $REPOS/fooYYYYMMDD (YYYYMMDD is the date)
 +- be able to set the number of generations
 +- be able to set if we compress the old ones
 +- output logs adequately
 +- make "remove" interactive, but provide -y option which forces yes to all

=end

#################
#
# require packages
#
require 'optparse'
require 'fileutils'
require 'logger'

#################
#
# define constants
#
generation = 3
basedir    = "/mnt/external"
basestar   = "#{basedir}/*"
repodir    = "/mnt/external/repository"
scriptname = File.basename($0)
lfile=File.basename($0, File.extname($0))
lockfile="/tmp/#{lfile}.lock"

#################
#
# define binaries
#
echo     = "/bin/echo"
date     = `/bin/date '+%Y%m%d'`
find     = "/usr/bin/find"
lsd      = "/bin/ls -dr"
grep     = "/bin/grep -E"
#repodirs = `#{find} #{basedir} -maxdepth 1 -type d -regex ".*/repository[0-9]+$" 2>&1`
repodirs = `#{lsd} #{basestar} | #{grep} 'repository[0-9]{8}$' 2>&1`

#################
#
# define functions
#
def delLockFile(lockfile)
  begin
    File.unlink(lockfile)
  rescue
    puts "[Warning] Lock file may not have been deleted correctly.\n"
  end
end

#################
#
# check for duplicate process
#
def checkDupProcess(lockfile)
  
  if File.exists?(lockfile)
    File.open(lockfile, 'r') {|f|
      pid = f.gets
      puts "#{File.basename($0)} is already running in PID #{pid}."
      f.close
    }
    exit
  else
    pid = $$
    File.open(lockfile, 'w') {|f| f.write(pid)}
  end
end

#################
#
# check if there is any dirs to remove
#
def numRmDirs?(repos, gen, rmDirNum)
  if gen >= repos.length or rmDirNum == 0
    puts "There are no repositories to remove"
    puts "Set Generation:#{gen}"
    puts "Number of current repositories:#{repos.length}"
    puts "Done."
    return 0
  end

  return rmDirNum
end

#################
#
# remove repositories
#
def rmRepos(repos, gen)

  print "\n"
  print "######################################\n"
  print "#      Starting delete process       #\n"
  print "######################################\n"

  for i in gen..repos.length - 1
    print "Removing... ", repos[i], "\n"
    FileUtils.rm_rf(repos[i])
  end
  puts "Done."

end

#################
#
# setup Logger
#
log       = Logger.new(STDOUT)
log.level = Logger::WARN

log.debug("Created Logger")
log.info("Program Started")
log.warn("Nothing to do !")
log.error("Nothing to do !")
log.fatal("Nothing to do !")

################################################################################
#
# Process auguments
#
################################################################################

options = {}

optparse = OptionParser.new do|opts|
  opts.banner = "Usage: gencontrol.rb [options] testnumbers ..."

  options[:verbose] = false
  opts.on( '-v', '--verbose', 'Output more information' ) do
    options[:verbose] = true
  end

  options[:removeOk] = false
  opts.on( '-y', 'Remove repositories without prompting' ) do
    options[:removeOk] = true
  end

  options[:compress] = false
  opts.on( '-c', 'Compress old repositories' ) do
    options[:compress] = true
  end

  options[:logfile] = nil
  opts.on( '-l', '--logfile [FILE]', 'Write log to FILE' ) do|file|
    unless file.nil?
      options[:logfile] = file
    else
      puts "You need to designate a log filename.\n"
      exit 
    end
  end

  opts.on_tail( '-h', '--help', 'Display this screen' ) do
    puts opts
    exit
  end
end

optparse.parse!

#################
#
# main(remove old directories)
#
checkDupProcess(lockfile)
repoarray = repodirs.split("\n")

print "######################################\n"
print "## These repositories will be kept. ##\n"
print "######################################\n"
removeDirs = 0
for i in 0..generation-1
  unless repoarray[i].nil?
    puts repoarray[i] 
    removeDirs += 1
  end
end

print "\n"
print "######################################\n"
print "# These repositories will be removed.#\n"
print "######################################\n"
for i in generation..repoarray.length
  puts repoarray[i] unless repoarray[i].nil?
end

unless options[:removeOk] then
  if numRmDirs?(repoarray, generation, removeDirs) == 0 
    delLockFile(lockfile)
    exit
  end

  while true
    puts "Proceed with the remove process?[y|N]"
    STDOUT.flush
    removeOk = gets.chomp
  
    removeOk.match('[yYnN]') && break
  end

  case removeOk
  when "y", "Y"
    rmRepos(repoarray, generation, removeDirs)
  when "n", "N"
    puts "Exit program"
  end
else
  rmRepos(repoarray, generation, removeDirs)
end

delLockFile(lockfile)

