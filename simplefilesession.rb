#!/usr/bin/ruby -w

require 'tmpdir'
require 'cgi'

# Modeled on CGI::Session
class SimpleFileSession
    #
    # Create a new session id.
    #
    # The session id is an MD5 hash based upon the time,
    # a random number, and a constant string.  This routine
    # is used internally for automatically generated
    # session ids.
    def create_new_id
      require 'securerandom'
      begin
        session_id = SecureRandom.hex(16)
      rescue NotImplementedError
        require 'digest/md5'
        md5 = Digest::MD5::new
        now = Time::now
        md5.update(now.to_s)
        md5.update(String(now.usec))
        md5.update(String(rand(0)))
        md5.update(String($$))
        md5.update('foobar')
        session_id = md5.hexdigest
      end
      session_id
    end
    private :create_new_id
    attr_reader :session_id

    def initialize(option={})
        @new_session = false
        session_id = option['session_id']
        unless session_id
            if option['new_session']
                session_id = create_new_id
                @new_session = true
            end
        end
        unless session_id
            raise ArgumentError, "session_key `session_id' should be supplied"
        end
        @session_id = session_id
        dir = option['tmpdir'] || Dir::tmpdir
        prefix = option['prefix'] || 'cgi_sfs_'
        suffix = option['suffix'] || ''
        require 'digest/md5'
        md5 = Digest::MD5.hexdigest(@session_id)[0,16]
        @path = dir+"/"+prefix+md5+suffix
        if File::exist? @path
            @hash = nil
        else
            unless @new_session
                raise ArgumentError, "uninitialized session"
            end
            @hash = {}
        end
    end
    # Restore session state from the session's FileStore file.
    #
    # Returns the session state as a hash.
    def restore
        unless @hash
            @hash = {}
            begin
                lockf = File.open(@path+".lock", "r")
                lockf.flock File::LOCK_SH
                f = File.open(@path, 'r')
                for line in f
                    line.chomp!
                    k, v = line.split('=',2)
                    #@hash[CGI::unescape(k)] = Marshal.restore(CGI::unescape(v))
                    # Just supports bools and strings
                    valueString = CGI::unescape(v)
                    type = valueString[0]
                    if type == 'B'
                        if valueString[1] == 'T'
                            value = true
                        else
                            value = false
                        end
                    elsif type == 'S'
                        value = valueString[1, valueString.length - 1]
                    else
                        value = nil
                    end
                    @hash[CGI::unescape(k)] = value
                end
            ensure
                f.close unless f.nil?
                lockf.close if lockf
            end
        end
        @hash
    end

    def keys()
        @data ||= restore
        return @data.keys
    end

    #
    # Retrieve the session data for key +key+.
    def [](key)
        @data ||= restore
        @data[key]
    end

    # Set the session date for key +key+.
    def []=(key, val)
        @write_lock ||= true
        @data ||= restore
        @data[key] = val
    end
    
    def delete_key(key)
        @data ||= restore
        @data.delete key
    end

    # Save session state to the session's FileStore file.
    def update
        return unless @hash
        begin
            lockf = File.open(@path+".lock", File::CREAT|File::RDWR, 0600)
            lockf.flock File::LOCK_EX
            f = File.open(@path+".new", File::CREAT|File::TRUNC|File::WRONLY, 0600)
            for k,v in @hash
                #f.printf "%s=%s\n", CGI::escape(k), CGI::escape(String(Marshal.dump(v)))
                # Just supports bools and strings
                if v == true
                    valueString = 'BT'
                elsif v == false
                    valueString = 'BF'
                else
                    valueString = 'S' + v.to_s
                end
                f.printf "%s=%s\n", CGI::escape(k), CGI::escape(valueString)
            end
            f.close
            File.rename @path+".new", @path
        ensure
            f.close if f and !f.closed?
            lockf.close if lockf
        end
    end

    # Update and close the session's FileStore file.
    def close
        update
    end

    # Close and delete the session's FileStore file.
    def delete
        File::unlink @path+".lock" rescue nil
        File::unlink @path+".new" rescue nil
        File::unlink @path rescue Errno::ENOENT
    end
end
