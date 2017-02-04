#!/usr/bin/ruby -w
require "./simplefilesession"
require "./getljposts"

sessionID = ARGV[0]
sessOptions = {"session_id" => sessionID, "new_session" => false, "prefix" => "ljbackupsess", "no_cookies" => true}
newSess = SimpleFileSession.new(sessOptions)
params = {}
begin
    keys = newSess.keys
    keys.each { |key|
        if key.start_with?('param')
            params[key['param'.length, key.length - 'param'.length]] = newSess[key]
            # don't need it (and it has a password!), delete it
            newSess.delete_key key
        end
    }
    newSess.update
    sessionLogger = LJBackup::SessionLogger.new(newSess, sessOptions)
    # Update the calendar.  Be sure to rescue exceptions
    dirName = newSess['dirName']
    #newSess.close
    #newSess = nil
    LJBackup::LJRetriever.doLJBackup(dirName + "/", params, sessionLogger)
rescue Exception => exc
    #newSess = CGI::Session.new(newCGI, sessOptions)
    newSess = SimpleFileSession.new(sessOptions)
    if (exc and exc.message and exc.message != "")
        newSess['status'] = "ERROR - #{exc.message} (backtrace is #{exc.backtrace.to_s}" + "\n, old status: " + newSess['status'] + ")"
    else
        newSess['status'] = "ERROR (backtrace is #{exc.backtrace.to_s}, " + "\nold status: " + newSess['status'] + ")"
    end
    newSess['done'] = true
    newSess['error'] = true
    newSess.update
end
