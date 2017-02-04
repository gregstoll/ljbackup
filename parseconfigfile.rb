#!/usr/bin/ruby

module ParseConfigFile

def ParseConfigFile.parseConfigFile(fileName)
    entries = {}
    IO.foreach(fileName) do |line|
        if (line =~ /^(.*?)=(.*)$/) then
            entries[$1] = $2
        end
    end
    entries
end

end

if __FILE__ == $0
    puts ParseConfigFile::parseConfigFile('.logininfo').inspect
end
