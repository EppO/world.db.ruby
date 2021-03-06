# encoding: utf-8

require 'commander/import'

require 'logutils/db'   # add support for logging to db
require 'worlddb/cli/opts'

LogUtils::Logger.root.level = :info   # set logging level to info 


program :name,  'worlddb'
program :version, WorldDb::VERSION
program :description, "world.db command line tool, version #{WorldDb::VERSION}"


# default_command :help
default_command :load

program :help_formatter, Commander::HelpFormatter::TerminalCompact

## program :help, 'Examples', 'yada yada -try multi line later'

=begin
### add to help use new sections

Examples:
    worlddb at/cities                      # import austrian cities
    worlddb --create                       # create database schema

More Examples:
    worlddb                                # show stats (table counts, table props)

Further information:
  http://geraldb.github.com/world.db=end
=end


## todo: find a better name e.g. change to settings? config? safe_opts? why? why not?
myopts = WorldDb::Opts.new

### global option (required)
## todo: add check that path is valid?? possible?

global_option '-i', '--include PATH', String, "Data path (default is #{myopts.data_path})"
global_option '-d', '--dbpath PATH', String, "Database path (default is #{myopts.db_path})"
global_option '-n', '--dbname NAME', String, "Database name (datault is #{myopts.db_name})"

global_option '-q', '--quiet', "Only show warnings, errors and fatal messages"
### todo/fix: just want --debug/--verbose flag (no single letter option wanted) - fix
global_option '-w', '--verbose', "Show debug messages"


def connect_to_db( options )
  puts WorldDb.banner

  puts "working directory: #{Dir.pwd}"

  db_config = {
    :adapter  => 'sqlite3',
    :database => "#{options.db_path}/#{options.db_name}"
  }

  puts "Connecting to db using settings: "
  pp db_config

  ActiveRecord::Base.establish_connection( db_config )
  
  LogDb.setup  # turn on logging to db
end


command :create do |c|
  c.syntax = 'worlddb create [options]'
  c.description = 'Create DB schema'
  c.action do |args, options|

    LogUtils::Logger.root.level = :warn    if options.quiet.present?
    LogUtils::Logger.root.level = :debug   if options.verbose.present?

    myopts.merge_commander_options!( options.__hash__ )
    connect_to_db( myopts )
    
    LogDb.create
    WorldDb.create
    puts 'Done.'
  end # action
end # command create

command :setup do |c|
  c.syntax = 'worlddb setup [options]'
  c.description = "Create DB schema 'n' load all data"

  c.option '--delete', 'Delete all records'

  c.action do |args, options|

    LogUtils::Logger.root.level = :warn    if options.quiet.present?
    LogUtils::Logger.root.level = :debug   if options.verbose.present?

    myopts.merge_commander_options!( options.__hash__ )
    connect_to_db( myopts )

    if options.delete.present?
      # w/ delete flag assume tables already exit
      WorldDb.delete!
    else
      LogDb.create
      WorldDb.create
    end

    WorldDb.read_all( myopts.data_path )
    puts 'Done.'
  end # action
end  # command setup

command :load do |c|
  ## todo: how to specify many fixutes <>... ??? in syntax
  c.syntax = 'worlddb load [options] <fixtures>'
  c.description = 'Load fixtures'

  c.option '--country KEY', String, "Default country for regions 'n' cities"
  
  ### todd/check - type flags still needed? dispatch using name and convention?
  c.option '--countries', 'Use country plain text fixture reader'
  c.option '--regions',   'Use regions plain text fixture reader'
  c.option '--cities',    'Use cities  plain text fixture reader'

  c.option '--delete', 'Delete all records'

  c.action do |args, options|

    LogUtils::Logger.root.level = :warn    if options.quiet.present?
    LogUtils::Logger.root.level = :debug   if options.verbose.present?

    myopts.merge_commander_options!( options.__hash__ )
    connect_to_db( myopts )
    
    WorldDb.delete! if options.delete.present?

    # read plain text country/region/city fixtures
    reader = WorldDb::Reader.new( myopts.data_path )
    args.each do |arg|
      name = arg     # File.basename( arg, '.*' )

      if myopts.countries?
        reader.load_countries( name )
      elsif myopts.regions?
        reader.load_regions( myopts.country, name )
      elsif myopts.cities?
        reader.load_cities( myopts.country, name )
      else
        reader.load( name )
        ## todo: issue a warning here; no fixture type specified; assume country?
      end
      
    end # each arg
    
    puts 'Done.'
  end
end # command load


command :stats do |c|
  c.syntax = 'worlddb stats [options]'
  c.description = 'Show stats'
  c.action do |args, options|

    LogUtils::Logger.root.level = :warn    if options.quiet.present?
    LogUtils::Logger.root.level = :debug   if options.verbose.present?

    myopts.merge_commander_options!( options.__hash__ )
    connect_to_db( myopts ) 
    
    WorldDb.tables
    
    puts 'Done.'
  end
end


command :props do |c|
  c.syntax = 'worlddb props [options]'
  c.description = 'Show props'
  c.action do |args, options|

    LogUtils::Logger.root.level = :warn    if options.quiet.present?
    LogUtils::Logger.root.level = :debug   if options.verbose.present?

    myopts.merge_commander_options!( options.__hash__ )
    connect_to_db( myopts ) 
    
    WorldDb.props
    
    puts 'Done.'
  end
end


command :logs do |c|
  c.syntax = 'worlddb logs [options]'
  c.description = 'Show logs'
  c.action do |args, options|

    LogUtils::Logger.root.level = :warn    if options.quiet.present?
    LogUtils::Logger.root.level = :debug   if options.verbose.present?

    myopts.merge_commander_options!( options.__hash__ )
    connect_to_db( myopts ) 
    
    LogDb::Models::Log.all.each do |log|
      puts "[#{log.level}] -- #{log.msg}"
    end
    
    puts 'Done.'
  end
end



command :test do |c|
  c.syntax = 'worlddb test [options]'
  c.description = 'Debug/test command suite'
  c.action do |args, options|
    puts "hello from test command"
    puts "args (#{args.class.name}):"
    pp args
    puts "options:"
    pp options
    puts "options.__hash__:"
    pp options.__hash__
    puts 'Done.'
  end
end
