require 'net/ftp'
# require 'pp'

FTP = ::Net::FTP.new

FTP.open_timeout = 55 # seconds
FTP.read_timeout = 55 # seconds
FTP.debug_mode = true

def connect(domain, user, password)
  FTP.connect domain
  response_print
  FTP.login user, password
end

def directory_change(directory)
  FTP.chdir directory
  response_print
end

def domain_file(line_current)
  message = "First line must be \"open {domain name}\".\n"
  line_open = line_current.split ' '
  unless (2 == line_open.length) && ('open' == (line_open.at 0))
    print line_current
    print message
    raise
  end
  line_open.at 1
end

def file_command_ftp_read
  padding = Array.new 3, ' '
  filename = filename_ftp_command
  begin
    f = ::File.open filename, 'r'
    lines = f.readlines + padding
    domain = domain_file lines.at 0
    user = user_file lines.at 1
    password = password_file lines.at 2
    tree = tree_file lines.drop 3
  ensure
    f.close
  end
  [domain, user, password, tree]
end

def file_put(localfile, remotefile)
   FTP.putbinaryfile localfile, remotefile
end

def filename_ftp_command
  filename = ARGV[0]
# print "FTP command file=#{filename}\n"
  unless filename
    print "First argument must be FTP command file.\n"
    raise
  end
  filename
end

def files_list
  print "#{FTP.nlst.join ' '}\n"
end

def files_send
  domain, user, password, tree = file_command_ftp_read
# pp domain, user
# pp password
# pp tree

  begin
    connect domain, user, password
    modes_set
    status_print

    tree.each do |location|
      directory = location.first
      directory_change directory
      pairs = location.last
      pairs.each do |pair|
        file_put *pair
      end
#     files_list
    end
    quit

  rescue => exception
    response_print
    FTP.abort
    raise
  ensure
    FTP.close
  end
end

def modes_set
  FTP.binary = true
  FTP.passive = true
  FTP.resume = false
end

def password_file(line_current)
  message = "Third line must be FTP user password.\n"
  line_password = line_current.split ' '
  unless (1 == line_password.length)
# Don't print FTP user password line.
    print message
    raise
  end
  line_password.at 0
end

def quit
  FTP.quit
end

def response_print
# print "#{FTP.last_response}\n"
end

def status_print
# print "#{FTP.pwd}\n"
  response_print
# print "#{FTP.status}\n"
  response_print
# print "#{FTP.system}\n"
  response_print
end

def tree_file(lines)
  tree = []
  directory = '/'
  files = []
  lines.length.times do |i|
    line_current = lines.at i
    command = line_current.split ' '
    keyword = command.empty? ? '' : (command.at 0)
    case
    when (0 == command.length)
    when (1 == command.length) && ('disconnect' == keyword)
    when (1 == command.length) && ('quit' == keyword)
    when (2 == command.length) && ('cd' == keyword)
      tree.push [directory, files] unless files.empty?
      directory = command.at 1
      files = []
    when (3 == command.length) && ('put' == keyword)
      files.push command[1..2]
    else
      print "Unrecognized command: #{line_current}"
      raise
    end
  end
  tree.push [directory, files] unless files.empty?
  tree
end

def user_file(line_current)
  message = "Second line must be FTP user name.\n"
  line_user = line_current.split ' '
  unless (1 == line_user.length)
# Don't print user name line, in case password is mistakenly there.
    print message
    raise
  end
  line_user.at 0
end

files_send
