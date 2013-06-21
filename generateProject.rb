#!/usr/bin/ruby -wKU

require 'trollop'
require 'fileutils'

GENVERSION = '0.0.1'
REPO_CORESTR = 'https://github.com/Sunstrike/LibCorestrike.git'
REPO_CCC = 'https://github.com/Quiddity-Modding/CodeChickenCore.git'

# Parse flags
opts = Trollop::options do
    opt :modname, 'Mod name (human)', :type => :string, :short => 'n'
    opt :modid, 'Mod ID', :type => :string, :short => 'i'
    opt :package, 'Package ID', :type => :string
    opt :codechickencore, 'Add CodeChickenCore submodule (creates Git repo; requires Git on path)', :default => false, :short => 'c'
    opt :libcorestrike, 'Add LibCorestrike submodule (creates Git repo; requires Git on path)', :default => false, :short => 'l'
    version GENVERSION
end

if opts[:modname] == nil || opts[:modid] == nil || opts[:package] == nil
    puts 'Parameters not specified! See --help for flags.'
    exit -1
end

opts[:date] = DateTime.now.strftime('%k:%M %Z (%-d/%-m/%Y)')
opts[:genversion] = GENVERSION

# Directories and pre-clean
FileUtils.rm_r 'output' if Dir.exists? 'output'

outSrc = "output#{File::SEPARATOR}src#{File::SEPARATOR}#{opts[:package].gsub(/\./, File::SEPARATOR)}"
resSrc = "output#{File::SEPARATOR}resources"
libSrc = outSrc + File::SEPARATOR + 'lib'
confSrc = outSrc + File::SEPARATOR + 'configuration'

FileUtils.mkdir_p libSrc
FileUtils.mkdir_p confSrc
FileUtils.mkdir_p resSrc

# Assemble filters
filters = {
    '@MODNAME@' => opts[:modname],
    '@MODID@' => opts[:modid],
    '@PACKAGE@' => opts[:package],
    '@PACKAGE_START@' => opts[:package][/[a-z]+/],
    '@DATE@' => opts[:date],
    '@GENVERSION@' => opts[:genversion]
}

puts "Filters: #{filters}\n\n"

# Get code from project
files = {}
Dir.glob(File.join('template', '**', '*'), File::FNM_DOTMATCH) { |file|
    next if File.directory? file
    next if file == '.' || file == '..' # We need DOTMATCH to catch .gitignore, so we ignore . and ..
    files[file] = IO.read file
}

puts 'Copying and filtering from template:'
files.each { |file, content|
    # Get target fname
    f = file.gsub /template/, 'output'
    f = f.gsub /src/, 'src' + File::SEPARATOR + opts[:package].gsub(/\./, File::SEPARATOR)
    f = f.gsub /@MODNAME@/, opts[:modid]

    # Filter file contents
    filters.each { |key, target|
        content.gsub! /#{key}/, target
    }

    # Write file
    File.open(f, 'w') { |f|
        f.write(content)
    }
    puts "#{file} => #{f}"
}

# Git support (submodules)
need_git = opts[:codechickencore] || opts[:libcorestrike]
puts "\nBuild git repo: #{if !need_git; 'Not needed.' end}"
if need_git
    Dir.chdir 'output'
    system 'git', 'init'
    system 'git', 'add', '.'
    system 'git', 'commit', '-m', '(Skeleton) Initial commit.'
    if opts[:codechickencore]
        puts "\nAdding submodule CodeChickenCore:"
        system 'git', 'submodule', 'add', REPO_CCC, 'CodeChickenCore'
    end
    if opts[:libcorestrike]
        puts "\nAdding submodule LibCorestrike:"
        system 'git', 'submodule', 'add', REPO_CORESTR, 'LibCorestrike'
    end
    puts "\nCommitting submodules:"
    system 'git', 'commit', '-m', '(Skeleton) Commit submodules.'
end

puts "\nFINISHED: See output directory for completed repo."
