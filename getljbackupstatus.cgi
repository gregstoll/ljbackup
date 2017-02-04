#!/usr/bin/ruby -w

require "fileutils"
#FileUtils.touch '/tmp/lja'
require "cgi"
#FileUtils.touch '/tmp/ljb'
#require "cgi/session"
require "./simplefilesession"
#FileUtils.touch '/tmp/ljc'

#sess = {'done' => 'false', 'error' => 'false', 'status' => 'got here'}
#FileUtils.touch '/tmp/ljd'
cgi = CGI.new
#FileUtils.touch '/tmp/lje'
begin
    #sess = CGI::Session.new(cgi, "session_id" => cgi['session_id'], "new_session" => false, "prefix" => "ljbackupsess", "no_cookies" => true)
    session_id = cgi['session_id']
    #FileUtils.touch '/tmp/lje2'
    sess = SimpleFileSession.new("session_id" => session_id, "new_session" => false, "prefix" => "ljbackupsess")
    #FileUtils.touch '/tmp/ljf'
rescue ArgumentError # if no old session
    cgi.out("text/plain") {"11Error getting session - please try again.  If this continues to happen, contact Greg (reachable from www.gregstoll.com)" }
    return
end
#FileUtils.touch '/tmp/ljg'
doneCode = if (sess['done']) then "1" else "0" end
errorCode = if (sess['error']) then "1" else "0" end
status = if sess['status'] then sess['status'].to_s else 'Unknown' end
# Clean up if there was an error and remove the session and directory
if (sess['error'])
    dirName = sess['dirName']
    if (dirName != '')
        FileUtils.remove_dir(dirName, true)
    end
    # TODO
    sess.delete
else
    # TODO
    sess.close
end
#FileUtils.touch '/tmp/ljh'
cgi.out("text/plain") {
    doneCode + errorCode + status
}
