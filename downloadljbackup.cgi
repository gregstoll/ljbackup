#!/usr/bin/ruby

require "cgi"
#require "cgi/session"
require "./simplefilesession"
require "tempfile"
require 'fileutils'
require 'rubygems'
require 'zip/zipfilesystem'

def addToZipFile(zipfile, name, baseDir, parentDir)
    if (name != "." and name != "..")
        if (File.directory?(baseDir + parentDir + name)) then
            zipfile.dir.mkdir(parentDir + name)
            Dir.foreach(baseDir + parentDir + name) do |entry|
                addToZipFile(zipfile, entry, baseDir, parentDir + name + "/")
            end
        else
            zipfile.file.open(parentDir + name, "w") do |outfile|
                infile = File.new(baseDir + parentDir + name, "r")
                FileUtils.copy_stream(infile, outfile)
                infile.close()
            end
        end
    end
end

cgi = CGI.new
begin
    #sess = CGI::Session.new(cgi, "session_id" => cgi['session_id'], "new_session" => false, "prefix" => "ljbackupsess", "no_cookies" => true)
    sess = SimpleFileSession.new("session_id" => cgi['session_id'], "new_session" => false, "prefix" => "ljbackupsess", "no_cookies" => true)
rescue ArgumentError # if no old session
    cgi.out("text/plain") {
        ""
        #"tried session_id=" + cgi['session_id'] + " and key length is " + cgi.keys.length.to_s + " first key is " + cgi.keys[0] + " and value is " + cgi[cgi.keys[0]]
    }
    exit
end
if (sess['done'] == true and not (sess['error'] == true))
    # Find the directory, make the zip file.
    dirName = sess['dirName']
    # Creating the zip file makes a huge number of temporary files, so at least
    # constrain them to a subdirectory of /tmp.
    zipFileDir = Tempfile.new('ljbackup')
    zipFileDirName = zipFileDir.path
    zipFileDir.close!
    FileUtils.mkdir zipFileDirName
    sess.update
    zipFile = Tempfile.new('ljbackup', zipFileDirName)
    zipFileName = zipFile.path + '.zip'
    zipFile.close!
    sess.close
    Zip::ZipFile.open(zipFileName, Zip::ZipFile::CREATE) { |zipfile|
        Dir.foreach(dirName) { |x| addToZipFile(zipfile, x, dirName + "/", '') }
    }
    cgi.out("type" => "application/zip", "Content-Disposition" => "attachment; filename=\"ljbackup.zip\"") {
        File.new(zipFileName, "rb").read()
    }
    # Clean up!
    sess.delete
    File.delete(zipFileName) 
    sleep 1
    Dir.rmdir(zipFileDirName)
    FileUtils.remove_dir(dirName, true)
else
    cgi.out("text/plain") {
        ""
    }
    sess.close
end

