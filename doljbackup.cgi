#!/usr/bin/ruby -w

require "cgi"
#require "cgi/session"
require "./simplefilesession"
require "./getljposts"
require "tempfile"
require "fileutils"
require "English"

# turn this on for debugging
RemoveOutput = false

cgi = CGI.new
#sess = CGI::Session.new(cgi, "new_session" => true, "prefix" => "ljbackupsess", "no_cookies" => true)
sess = SimpleFileSession.new("new_session" => true, "prefix" => "ljbackupsess")
sess['status'] = 'Retrieving posts...'
sess['done'] = false
sess['error'] = false
params = cgi.params
begin
    # Only take the first parameter of each.
    params.each { |key, value| params[key] = value.to_a[0].to_s }
    params.each { |key, value| sess['param' + key] = value }
    # Create a directory to hold the results.
    ljBackupDir = Tempfile.new('ljbackup')
    ljBackupDirName = ljBackupDir.path
    ljBackupDir.close!
    FileUtils.mkdir ljBackupDirName
    sess['dirName'] = ljBackupDirName
rescue Exception => exc
    #newSess = CGI::Session.new(newCGI, sessOptions)
    #newSess = SimpleFileSession.new(sessOptions)
    if (exc and exc.message and exc.message != "")
        sess['status'] = "ERROR - #{exc.message} (backtrace is #{exc.backtrace.to_s}" + "\n, old status: " + newSess['status'] + ")"
    else
        sess['status'] = "ERROR (backtrace is #{exc.backtrace.to_s}, " + "\nold status: " + newSess['status'] + ")"
    end
    sess['done'] = true
    sess['error'] = true
    sess.update
    cgi.out("text/text") { sessionID }
    Kernel.exit
end

sess.update
sessionID = sess.session_id
cgi.out("text/text") { sessionID }
sess.close

pid = Process.spawn('./startljbackup.rb ' + sessionID, [:in, :out, :err]=>:close)
Process.detach(pid)
