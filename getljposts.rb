#!/usr/bin/ruby1.9.1 -w
# encoding: utf-8

require 'xmlrpc/client'
require 'pp'
require 'digest/md5'
require 'rexml/document'
require 'date'
require 'net/http'
require 'cgi'
require 'fileutils'
#require 'cgi/session'
require './simplefilesession'
require 'rubygems'
require 'tzinfo'
require 'rexml/document'

# Add a starts_with? method
class String
    def starts_with?(text)
        return false if (length < text.length)
        return (self[0,text.length] == text)
    end
    def makeFileNameSafe
        self.tr('/', '')
    end
end

module LJBackup

AuthenticationClear = false

LJAPIPrefix = "LJ.XMLRPC."
ClientName = "Ruby-gregLJBackup/0.0.2"
APISleepTime = 0.5
APICommentsPath = "/export_comments.bml"
APIPollPath = "/poll/?id="
APIMemoriesPath = "/tools/memories.bml"
OutputDir = "results/"
PostsDir = "posts/"
RecentPostsDir = "recent/"
CommentsDir = "comments/"
MoodsDir = "moods/"
TagsDir = "tags/"
CalendarDir = "calendar/"
ImagesDir = "images/"
SourceImagesDir = "images/"
NumTopComments = 25
NumTopWords = 25
NumRecentPerPage = 25
MoodMap = {2 => 'angry', 1 => 'aggravated', 3 => 'annoyed', 110 => 'bitchy',
    8 => 'cranky', 104 => 'cynical', 12 => 'enraged', 47 => 'frustrated',
    95 => 'grumpy', 19 => 'infuriated', 20 => 'irate', 112 => 'irritated',
    23 => 'moody', 24 => 'pissed off', 28 => 'stressed', 100 => 'rushed',
    87 => 'awake', 6 => 'confused', 56 => 'curious', 45 => 'determined',
    118 => 'predatory', 130 => 'devious', 11 => 'energetic', 59 => 'bouncy',
    52 => 'hyper', 13 => 'enthralled', 15 => 'happy', 44 => 'amused',
    125 => 'cheerful', 99 => 'chipper', 98 => 'ecstatic', 41 => 'excited',
    16 => 'high', 17 => 'horny', 126 => 'good', 132 => 'grateful',
    116 => 'impressed', 21 => 'jubilant', 86 => 'loved', 70 => 'optimistic',
    43 => 'hopeful', 109 => 'pleased', 69 => 'refreshed', 62 => 'rejuvenated',
    53 => 'relaxed', 68 => 'calm', 57 => 'mellow', 58 => 'peaceful',
    77 => 'recumbent', 26 => 'satisfied', 64 => 'content', 63 => 'complacent',
    65 => 'indifferent', 93 => 'full', 42 => 'relieved', 66 => 'silly',
    106 => 'crazy', 35 => 'ditzy', 67 => 'flirty', 120 => 'giddy',
    72 => 'giggly', 36 => 'mischievous', 117 => 'naughty', 105 => 'quixotic',
    96 => 'weird', 121 => 'surprised', 122 => 'shocked', 131 => 'thankful',
    32 => 'touched', 48 => 'indescribable', 102 => 'nerdy', 115 => 'dorky',
    103 => 'geeky', 61 => 'okay', 92 => 'blah', 33 => 'lazy', 78 => 'exanimate',
    114 => 'apathetic', 113 => 'blank', 75 => 'lethargic', 76 => 'listless',
    25 => 'sad', 5 => 'bored', 7 => 'crappy', 129 => 'crushed',
    9 => 'depressed', 55 => 'disappointed', 10 => 'discontent', 80 => 'envious',
    38 => 'gloomy', 71 => 'pessimistic', 133 => 'jealous', 22 => 'lonely',
    39 => 'melancholy', 37 => 'morose', 124 => 'numb', 123 => 'rejected',
    81 => 'sympathetic', 74 => 'uncomfortable', 84 => 'cold', 119 => 'dirty',
    34 => 'drunk', 14 => 'exhausted', 40 => 'drained', 31 => 'tired',
    51 => 'groggy', 49 => 'sleepy', 111 => 'guilty', 83 => 'hot',
    18 => 'hungry', 54 => 'restless', 82 => 'sick', 97 => 'nauseated',
    27 => 'sore', 29 => 'thirsty', 85 => 'worried', 46 => 'scared',
    4 => 'anxious', 127 => 'distressed', 79 => 'embarrassed',
    128 => 'intimidated', 134 => 'nervous', 30 => 'thoughtful',
    101 => 'contemplative', 60 => 'nostalgic', 73 => 'pensive', 88 => 'working',
    90 => 'accomplished', 108 => 'artistic', 91 => 'busy', 107 => 'creative',
    89 => 'productive'}
LJPollCSS = ".ljpoll-results-line{position:relative;display:inline-block;height:7px;min-width:6px;max-width:90%;margin:0 0 7px;padding:0;vertical-align:-5px;border-radius:3px;background:#7A202C;background:-webkit-linear-gradient(top,#7A202C 0,#9D2738 1px,#9F021A 2px,#AD0720 3px,#DB0728 4px,#F0072B 5px,#840116 6px);background:linear-gradient(to bottom,#7A202C 0,#9D2738 1px,#9F021A 2px,#AD0720 3px,#DB0728 4px,#F0072B 5px,#840116 6px);font:0/0 a}"

# Add a starts_with? method
class String
    def starts_with?(text)
        return false if (length < text.length)
        return (self[0,text.length] == text)
    end
end

class TextLogger
    def logError(message, isFatal)
        if isFatal
            raise message
        else
            puts message
        end
    end

    def logText(message, isDone)
        puts message
    end

    def logDebug(message)
        puts "DEBUG: " + message.to_s
    end
end

class SessionLogger
    def initialize(session, params)
        @session = session
        #@cgi = cgi
        @params = params
        self.closeSess
        @debug = ''
        @realMessage = ''
    end

    def openSess()
        #@session = CGI::Session.new(@cgi, @params)
        @session = SimpleFileSession.new(@params)
    end

    def closeSess()
        @session.update
        @session.close
        @session = nil
    end

    def logError(message, isFatal)
        @realMessage = message.to_s
        self.openSess
        @session['status'] = @debug + @realMessage
        @session['done'] = isFatal
        @session['error'] = isFatal
        self.closeSess
        if (isFatal)
            raise message
        end
    end

    def logText(message, isDone)
        @realMessage = message 
        self.openSess
        @session['status'] = @debug + @realMessage
        @session['done'] = isDone
        self.closeSess
    end

    def logDebug(message)
        @debug = @debug + "DEBUG: " + message
        self.openSess
        @session['status'] = @debug + @realMessage
        @session.update
        self.closeSess
    end
end

class LJRetriever

def getAuthHash(challenge)
    response = Digest::MD5.hexdigest(challenge + Digest::MD5.hexdigest(@password))
    return {:username => @username, :auth_method => "challenge", :auth_challenge => challenge, :auth_response => response, :ver => 1}
end

def getLJUserString(user)
    if (user == "anonymous")
        return "anonymous"
    else
        return "<a href=\"http://#{ user }.livejournal.com\">#{ user }</a>"
    end
end

def getLJSession()
    if (@ljsession == nil)
        result = doMethod("sessiongenerate", :expiration => "long")
        @ljsession = result['ljsession']
    end
    return @ljsession
end

def getPageWithRetry(path, headers={})
    ljsession = getLJSession()
    ljsite = Net::HTTP.new("www.livejournal.com")
    sleep(APISleepTime + @delay)
    # Try to handle transient errors
    numAttempts = 1
    realHeaders = {}
    realHeaders.replace(headers)
    realHeaders['Cookie'] = 'ljsession=' + ljsession
    realHeaders['User-Agent'] = ClientName
    begin
        resp = ljsite.get2(path, realHeaders)
    rescue Exception
        if (numAttempts < @attempts)
            @logger.logText("Got exception for poll, retrying: #{ $! }", false)
            sleep(2.0 + @delay)
            numAttempts = numAttempts + 1
            retry
        else
            @logger.logError("Error getting LJ page #{ path }. Check that your password is correct. If it is, wait a bit and try again.", true)
        end
    end
    return resp
end

def getPostSummary(postInfo, pathToRoot)
    toReturn = ''
    if (postInfo['locked'])
        toReturn += "<img src=\"#{ pathToRoot + ImagesDir}icon_protected.gif\" alt=\"locked\">"
    end
    toReturn += "<a href=\"#{ pathToRoot + PostsDir + postInfo['linkId'].to_s }.html\">#{ postInfo['subject'] }</a>"
    return toReturn
end

def writePostMain(aFile, postInfo, pathToRoot, doComments=false)
    aFile.write("<p style=\"background-color: lightgray\">")
    if (postInfo['locked'])
        aFile.write("<img src=\"#{ pathToRoot + ImagesDir}icon_protected.gif\" alt=\"locked\">")
    end
    aFile.write("#{ postInfo['subject'] }<br>\n")
    if (postInfo.include?('moodtext'))
        aFile.write("Mood: #{ postInfo['moodtext'] }<br>\n")
    end
    if (postInfo.include?('music'))
        aFile.write("Music: #{ postInfo['music'] }<br>\n")
    end
    if (postInfo.include?('location'))
        aFile.write("Location: #{ postInfo['location'] }<br>\n")
    end
    aFile.write("Posted on <a href=\"http://#{ @username }.livejournal.com/#{ postInfo['linkId'] }.html\">#{ postInfo['date'] }</a>\n")
    if (postInfo['tags'] != nil)
        aFile.write("<br>Tags: ")
        postInfo['tags'].each {|tag| aFile.write("<a href=\"#{ pathToRoot}tags/#{ tag }.html\">#{ tag }</a> ")}
    end
    aFile.write("<br>Words: #{ postInfo['numWords'] }\n")
    aFile.write("</p>\n")
    event = postInfo['event']
    # Tidy up the post here.
    event = tidyUpPost(event, pathToRoot, postInfo['id'])
    aFile.write("<p>\n")
    aFile.write("#{ event }\n")
    aFile.write("</p>\n")
    if (doComments)
        numComments = postInfo['numComments']
        aFile.write("<p style=\"background-color: lightgray\"><a href=\"#{ pathToRoot + PostsDir + postInfo['linkId'].to_s }.html\">#{ numComments } comment#{ if numComments != 1 then 's' end}</a></p>")
    end
 
end

def getLinks(html)
    links = []
    linkRE = Regexp.new('<a\s+href\s*=\s*"(.*?)"')
    linkMatch = linkRE.match(html)
    while (linkMatch != nil)
        links.push(linkMatch[1])
        linkMatch = linkRE.match(linkMatch.post_match)
    end
    return links
end

def getMemories()
    resp = getPageWithRetry(APIMemoriesPath)
    keywordLinks = getLinks(resp.body)
    keywordLinks = keywordLinks.find_all {|href| href.starts_with?(APIMemoriesPath + "?user=#{@username}")}
    keywordRE = Regexp.new('keyword=(.*?)&amp;')
    memoryLinkRE = Regexp.new("http://#{ @username }\.livejournal\.com/(\\d+)\.html")
    keywordLinks.each do |keywordLink|
        keywordMatch = keywordRE.match(keywordLink)
        if (keywordMatch == nil)
            @logger.logError("Couldn't get keyword match for link #{ keywordLink }", false)
        else
            keyword = CGI::unescape(keywordMatch[1])
            if (keyword == "*")
                keyword = "Uncategorized"
            end
            resp = getPageWithRetry(CGI::unescapeHTML(keywordLink))
            memoryLinks = getLinks(resp.body)
            memoryLinks = memoryLinks.find_all {|href| memoryLinkRE.match(href)}
            memoryLinks.each do |href|
                @memories[keyword].push(memoryLinkRE.match(href)[1].to_i)
            end
        end
    end
end

def getComments()
    # First gather the comments
    maxId = -1
    highestIdSeen = -1000
    while (highestIdSeen < maxId) do
        origMaxId = maxId
        @logger.logText("Getting comment page with startId #{ maxId + 1} (highestIdSeen=#{ highestIdSeen })", false)
        resp = getPageWithRetry(APICommentsPath + "?get=comment_meta&startid=#{ maxId + 1}")
        @logger.logText("Got comment page with startId #{ maxId + 1} (highestIdSeen=#{ highestIdSeen })", false)
        commentDoc = REXML::Document.new(resp.body)
        if maxId == -1
            commentDoc.elements.each("/livejournal/maxid") do |elem|
                maxId = elem.text.to_i
            end
        end
        commentDoc.elements.each("/livejournal/usermaps/usermap") do |elem|
            if (not @userIdToUser.include?(elem.attributes['id'].to_i))
                @userIdToUser[elem.attributes['id'].to_i] = elem.attributes['user']
            end
        end
        commentDoc.elements.each("/livejournal/comments/comment") do |elem|
            id = elem.attributes['id'].to_i
            if (id > highestIdSeen)
                highestIdSeen = id
            end
            @comments[id] = {}
        end
        if (origMaxId == maxId) then
            break
        end
    end
    highestCommentDownloaded = -1
    while (highestCommentDownloaded < maxId) do
        oldHighestCommentDownloaded = highestCommentDownloaded
        resp = getPageWithRetry(APICommentsPath + "?get=comment_body&startid=#{ highestCommentDownloaded + 1}")
        #File.open('TEMPTODO', 'w') do |aFile|
        #    aFile.write(resp.body)
        #end
        # We think this is in UTF-8, but some old entries may be in some
        # codepage. String's encode method won't replace invalid characters
        # if the source and dest encoding are the same, so go back and forth
        # to UTF-16.
        respBody = resp.body.encode('utf-16', 'utf-8', {:invalid => :replace})
        respBody.encode!('utf-8', 'utf-16')
        commentDoc = REXML::Document.new(respBody)
        commentDoc.elements.each('//comments/comment') do |elem|
            id = elem.attributes['id'].to_i
            if (id > highestCommentDownloaded) then highestCommentDownloaded = id end
            commentInfo = {}
            commentInfo['parentid'] = if (elem.attributes.include?('parentid'))
                                          elem.attributes['parentid'].to_i
                                      else
                                          0
                                      end
            commentInfo['posterid'] = if (elem.attributes.include?('posterid'))
                                          elem.attributes['posterid'].to_i
                                      else
                                          0
                                      end
            commentInfo['jitemid'] = elem.attributes['jitemid'].to_i
            if elem.elements['subject']
                commentInfo['subject'] = elem.elements['subject'].text
            end
            if elem.elements['body']
                commentInfo['body'] = elem.elements['body'].text
            end
            if elem.elements['date']
                commentInfo['date'] = DateTime::parse(elem.elements['date'].text)
            end
            commentInfo['id'] = id
            #if (id == 1 or id == maxId)
            #    pp commentInfo
            #end
            # If there's no body we're not interested.
            if (commentInfo.include?('body'))
                @comments[id] = commentInfo
            else
                @comments.delete(id)
            end
        end
        if (oldHighestCommentDownloaded == highestCommentDownloaded)
            break
        end
    end
end

def doMethod(methodName, *args)
    if (AuthenticationClear)
        params = {:username => @username, :hpassword => Digest::MD5.hexdigest(@password)}
        #params = {:username => @username, :password => @password}
    else
        result = callMethod("getchallenge")
        #pp result
        challenge = result['challenge']
        params = getAuthHash(challenge)
    end
    #pp params
    if (args.length > 0)
        params.update(*args)
    end
    callMethod(methodName, params)
end

def callMethod(methodName, *args)
    # Try to handle transient errors
    firstTime = true
    recreatedServer = false
    begin
        sleep(APISleepTime)
        #@server.http_header_extra = {'Accept-Encoding': 'identity'}
        return @server.call(LJAPIPrefix + methodName, *args)
    rescue Exception
        if (firstTime)
            if not recreatedServer and ($!.to_s.strip == 'Broken pipe' or $!.to_s.strip == 'end of file reached')
                createServer()
                login()
                recreatedServer = true
                sleep(2.0)
                retry
            end
            @logger.logText("Got exception, retrying: #{ $! }", false)
            sleep(2.0)
            firstTime = false
            retry
        else
            @logger.logError("Error calling LJ method '#{ methodName }' - got exception #{ $! }. Check that your password is correct. If it is, wait a bit and try again.", true)
        end
    end
end

def login()
    @logger.logText("Doing login...", false)
    result = doMethod("login")
    @logger.logText("Logged in", false)
    @userInfo['fastserver'] = if (result.include?('fastserver')) then result['fastserver'] else 0 end
    if (@userInfo['fastserver'] == 1)
        @server.cookie = "ljfastserver=1"
    end
end

def makeEmptyDir(dirName)
    if (File.exists?(dirName))
        FileUtils.rm(Dir.glob(dirName + "*"))
    else
        Dir.mkdir(dirName)
    end
end

def makeEmptyDirHtml(dirName)
    if (File.exists?(dirName))
        FileUtils.rm(Dir.glob(dirName + "*.html"))
    else
        Dir.mkdir(dirName)
    end
end

def createServer()
    @server = XMLRPC::Client.new2("http://www.livejournal.com/interface/xmlrpc")
end

def sum(list)
    list.inject(0) { |sum,x| sum+x }
end
def std_dev(list)
    list_squared = list.map {|item| item*item}
    n = list.size

    right = (Float(sum(list)**2))/n
    return ((Float(sum(list_squared)) - right) / (n-1)) ** 0.5
end

def main()
    makeEmptyDirHtml(@targetDir)
    makeEmptyDir(@targetDir + PostsDir)
    makeEmptyDir(@targetDir + RecentPostsDir)
    makeEmptyDir(@targetDir + CommentsDir)
    makeEmptyDir(@targetDir + MoodsDir)
    makeEmptyDir(@targetDir + TagsDir)
    makeEmptyDir(@targetDir + CalendarDir)
    makeEmptyDir(@targetDir + ImagesDir)
    # Copy images to the images directory
    FileUtils.copy(Dir.glob(SourceImagesDir + "*"), @targetDir + ImagesDir)
    createServer()
    login()
    getComments()
    firstDate = nil
    result = doMethod("getevents", :selecttype => "lastn", :howmany => 50, :lineendings => "unix")
    donePages = 0
    stop = false
    while (result.include?('events') and result['events'] != nil and result['events'].length > 0 and not stop)
        @logger.logText("Processing #{ result['events'].length } pages (first is #{ result['events'][0]['eventtime'] }) - completed #{ donePages } pages so far", false)
        result['events'].each do |event|
            #if (event.include?('subject') and event['subject'] == 'ups and downs')
                #pp event['props']
            #end
            savePageWithComments(event)
            if (firstDate == nil or event['eventtime'] < firstDate)
                firstDate = event['eventtime']
            end
        end
        donePages = donePages + result['events'].length
        result = doMethod("getevents", :selecttype => "lastn", :howmany => 50, :lineendings => "unix", :beforedate => firstDate)
        #stop = @maxPosts > 0 and @pages.length >= @maxPosts
    end
    getMemories()
    @tagsToPosts.each do |tp|
        saveTagsPage(tp[0], tp[1])
    end
    saveXml()
    saveTagsIndexPage()
    saveStatsPage()
    saveMonthPages()
    saveYearPages()
    saveRecentPostsPages()
    saveIndexPage()
    @logger.logText("Done retrieving posts!  Creating zip file...", true)
end
    
def initialize(targetDir, username, password, timeZoneString, delay, attempts, publicOnly, maxPosts, logger)
    @logger = logger
    @targetDir = targetDir
    @maxPosts = maxPosts
    @userInfo = {}
    @username = username
    @password = password
    @timeZone = TZInfo::Timezone.get(timeZoneString.to_s)
    @delay = delay
    @attempts = attempts
    if (@attempts < 0)
        @attempts = 2
    end
    @publicOnly = publicOnly
    @comments = {}
    @userIdToUser = {0 => "anonymous"}
    @pages = {}
    @polls = {}
    @pagesWithPolls = []
    @tagsToPosts = Hash.new { |hash,key| hash[key] = [] }
    @memories = Hash.new { |hash,key| hash[key] = [] }
    @ljsession = nil
end

def saveTagsIndexPage()
    baseFileName = "tags.html"
    fileName = @targetDir + baseFileName
    File.open(fileName, 'w') do |aFile|
        aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
        aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
        aFile.write("<style>" + LJPollCSS + "</style>\n")
        aFile.write("<title>Tags</title></head>\n")
        aFile.write("<body>\n")
        aFile.write("<p style=\"background-color: lightgray\">Tags</p>\n")
        aFile.write("<div style=\"float: left\">\n")
        alphaTags = @tagsToPosts.sort {|a,b| a[0] <=> b[0]}
        alphaTags.each do |tagPair|
            aFile.write("<a href=\"#{ TagsDir + tagPair[0] }.html\">#{ tagPair[0] }</a> (#{ tagPair[1].length } entries)<br>\n")
        end
        aFile.write("</div>\n")
        aFile.write("<div style=\"float: left\">\n")
        alphaTags = @tagsToPosts.sort {|a,b| b[1].length <=> a[1].length}
        alphaTags.each do |tagPair|
            aFile.write("<a href=\"#{ TagsDir + tagPair[0] }.html\">#{ tagPair[0] }</a> (#{ tagPair[1].length } entries)<br>\n")
        end
        aFile.write("</div>\n")

        aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
        aFile.write("</body></html>")
    end
end

def saveTagsPage(tag, posts)
    safeTag = tag.makeFileNameSafe
    baseFileName = TagsDir + safeTag + ".html"
    fileName = @targetDir + baseFileName
    File.open(fileName, 'w') do |aFile|
        aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
        aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
        aFile.write("<style>" + LJPollCSS + "</style>\n")
        aFile.write("<title>Tag #{ tag } (#{ posts.length })</title></head>\n")
        aFile.write("<body>\n")
        aFile.write("<p style=\"background-color: lightgray\">Tag #{ tag } (#{ posts.length })</p>\n")
        # Sort the posts by date (put latest ones first)
        posts.sort! {|a,b| b['date'] <=> a['date']}
        posts.each do |postInfo|
            writePostMain(aFile, postInfo, '../', true)
        end
        aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
        aFile.write("</body></html>")
    end
    return baseFileName
end

def getRecentPostsFilename(numToSkip)
    if (numToSkip > 0)
        "indexskip" + numToSkip.to_s + ".html"
    else
        "index.html"
    end
end

def saveRecentPostsPages()
    # Sort the posts by date (put latest ones first)
    posts = @pages.sort {|a,b| b[1]['date'] <=> a[1]['date']}
    postsDoneTotal = 0  
    while posts.length > 0
        postsDoneOnPage = 0  
        baseFileName = RecentPostsDir + getRecentPostsFilename(postsDoneTotal)
        fileName = @targetDir + baseFileName
        File.open(fileName, 'w') do |aFile|
            aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
            aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
            aFile.write("<style>" + LJPollCSS + "</style>\n")
            aFile.write("<title>#{@username}'s posts</title></head>\n")
            aFile.write("<body>\n")
            while (posts.length > 0 and postsDoneOnPage < NumRecentPerPage)
                curPost = posts.shift
                writePostMain(aFile, curPost[1], "../", true)
                postsDoneOnPage += 1
                postsDoneTotal += 1
            end
            # link to others
            if (posts.length > 0 or postsDoneTotal > NumRecentPerPage)
                aFile.write("<p style=\"background-color: lightgray\">Go ")
                if (posts.length > 0)
                    aFile.write("<a href=\"#{ getRecentPostsFilename(postsDoneTotal)}\">earlier</a>")
                    if (postsDoneTotal > NumRecentPerPage)
                        aFile.write("/")
                    end
                end
                if (postsDoneTotal > NumRecentPerPage)
                    aFile.write("<a href=\"#{ getRecentPostsFilename(((postsDoneTotal - NumRecentPerPage - 1)/NumRecentPerPage) * NumRecentPerPage) }\">later</a>")
                end
                aFile.write("</p>")
            end
            aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
            aFile.write("</body></html>")
        end
    end
end

# Returns [monthName, day, year, month]
def dateToFriendlyDate(date)
    return [Date::MONTHNAMES[date.slice(5, 2).to_i], date.slice(8, 2).to_i.to_s, date.slice(0, 4).to_i.to_s, date.slice(5, 2).to_i]
end

def saveDayPage(year, month, day, posts)
    if (posts.length == 0)
        return
    end
    baseFileName = CalendarDir + year + "-" + month + "-" + day + ".html"
    fileName = @targetDir + baseFileName
    friendlyMonth = Date::MONTHNAMES[month.to_i]
    File.open(fileName, 'w') do |aFile|
        aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
        aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
        aFile.write("<style>" + LJPollCSS + "</style>\n")
        aFile.write("<title>Posts on #{ friendlyMonth } #{ day }, #{ year}</title></head>\n")
        aFile.write("<body>\n")
        aFile.write("<p style=\"background-color: lightgray\">Posts on #{ friendlyMonth } #{ day }, #{ year }</p>\n")
        posts = posts.sort {|a,b| a['date'] <=> b['date']}
        posts.each do |postInfo|
            writePostMain(aFile, postInfo, '../', true)
        end
        aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
        aFile.write("</body></html>")
    end
    return baseFileName
end

# Returns [date saved, URL, number of pages]
def saveNextDayPage(daySortedPosts)
    monthDay = dateToFriendlyDate(daySortedPosts[0][0])
    postsToUse = daySortedPosts.shift()[1]
    dayUsed = Date.new(monthDay[2].to_i, monthDay[3].to_i, monthDay[1].to_i)
    if (postsToUse.length == 1)
        # Only one post, so don't make a new page for it.
        return [dayUsed, "../" + PostsDir + postsToUse[0]['linkId'].to_s + '.html', postsToUse.length]
    else
        baseFileName = CalendarDir + monthDay[2].to_s + "-" + monthDay[3].to_s + "-" + monthDay[1].to_s + ".html"
        fileName = @targetDir + baseFileName
        File.open(fileName, 'w') do |aFile|
            aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
            aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
            aFile.write("<style>" + LJPollCSS + "</style>\n")
            aFile.write("<title>Posts on #{ monthDay[0] } #{ monthDay[1] }, #{ monthDay[2] }</title></head>")
            aFile.write("<body>\n")
            aFile.write("<p style=\"background-color: lightgray\">Posts on #{ monthDay[0] } #{ monthDay[1] }, #{ monthDay[2] }</p>\n")
            postsToUse.each do |postInfo|
                writePostMain(aFile, postInfo, '../', true)
            end
            aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
            aFile.write("</body></html>")
        end 
        return [dayUsed, "../" + baseFileName, postsToUse.length]
    end
end

def saveYearPages()
    # Sort the posts by date (earliest first)
    dayPosts = Hash.new { |hash,key| hash[key] = [] }
    @pages.each {|p| dayPosts[p[1]['date'].slice(0,10)].push(p[1]) }
    daySortedPosts = dayPosts.sort{ |a,b| a[0] <=> b[0] }
    firstYear = daySortedPosts[0][0].slice(0, 4).to_i
    lastYear = daySortedPosts[-1][0].slice(0, 4).to_i
    if (daySortedPosts.length == 0)
        return
    end
    nextDayInfo = saveNextDayPage(daySortedPosts)
    (firstYear .. lastYear).each do |curYear|
        baseFileName = CalendarDir + curYear.to_s + ".html"
        fileName = @targetDir + baseFileName
        File.open(fileName, 'w') do |aFile|
            aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
            aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
            aFile.write("<style>" + LJPollCSS + "</style>\n")
            aFile.write("<title>Posts in #{ curYear }</title></head>\n")
            aFile.write("<body>\n")
            aFile.write("<p style=\"background-color: lightgray\">Posts in #{ curYear }</p>\n")
            aFile.write("<p style=\"background-color: lightgray\">")
            (firstYear .. lastYear).each do |linkYear|
                if (linkYear == curYear)
                    aFile.write(" #{ linkYear } ")
                else
                    aFile.write(" <a href=\"#{ linkYear }.html\">#{ linkYear }</a> ")
                end
            end
            aFile.write("</p>\n")
            (1 .. 12).each do |monthNum|
                friendlyMonth = Date::MONTHNAMES[monthNum]
                aFile.write("<table cellpadding=\"2\" cellspacing=\"0\" border=\"0\">\n")
                aFile.write("<tr><td style=\"background-color: #999999; align: center\">\n")
                aFile.write("<table cellpadding=\"5\" cellspacing=\"0\" border=\"0\">\n")
                aFile.write("<tr><td>#{ friendlyMonth } #{ curYear }</td><td style=\"align: right;\">[<a href=\"#{ curYear }-#{ if (monthNum < 10) then "0" + monthNum.to_s else monthNum end }.html\">subjects</a>]</td></tr>\n")
                aFile.write("<tr><td colspan=\"2\" style=\"background-color: #eeeeee;\">\n")
                aFile.write("<table width=\"100%\" cellpadding=\"5\" cellspacing=\"0\" border=\"0\">\n")
                aFile.write("<tr style=\"align: center\"><td>Sun</td><td>Mon</td><td>Tue</td><td>Wed</td><td>Thu</td><td>Fri</td><td>Sat</td></tr>\n")
                # OK, how many blank spaces before the first?
                curDay = Date.new(curYear, monthNum, 1)
                numBlankSpaces = curDay.wday()
                aFile.write("<tr style=\"vertical-align: top\">")
                if (numBlankSpaces > 0)
                    aFile.write("<td colspan=\"#{ numBlankSpaces }\"></td>")
                end
                (1 .. 7 - numBlankSpaces).each do |dayNum|
                    aFile.write("<td>#{ dayNum }")
                    if (curDay == nextDayInfo[0]) 
                        aFile.write("<div style=\"align: center\"><a href=\"#{ nextDayInfo[1] }\">#{ nextDayInfo[2] }</a></div>")
                        if (daySortedPosts.length > 0)
                            nextDayInfo = saveNextDayPage(daySortedPosts)
                        end
                    else
                        aFile.write("&nbsp;")
                    end
                    aFile.write("</td>")
                    curDay = curDay.next()
                end
                aFile.write("</tr>\n")
                startOfWeek = 7 - numBlankSpaces + 1
                while (curDay.month() == monthNum) do
                    overflow = 0
                    aFile.write("<tr style=\"vertical-align: top\">")
                    (startOfWeek .. startOfWeek + 6).each do |dayNum|
                        if (curDay.month() == monthNum)
                            aFile.write("<td>#{ dayNum }")
                            if (curDay == nextDayInfo[0]) 
                                aFile.write("<div style=\"align: center\"><a href=\"#{ nextDayInfo[1] }\">#{ nextDayInfo[2] }</a></div>")
                                if (daySortedPosts.length > 0)
                                    nextDayInfo = saveNextDayPage(daySortedPosts)
                                end
                            else
                                aFile.write("&nbsp;")
                            end
                            aFile.write("</td>")
                        else
                            overflow = overflow + 1
                        end
                        curDay = curDay.next()
                    end
                    if (overflow > 0)
                        aFile.write("<td colspan=\"#{ overflow }\"></td>")
                    end
                    aFile.write("</tr>\n")
                    startOfWeek = startOfWeek + 7
                end
                aFile.write("</table></td></tr></table></td></tr></table><p/>")
            end
            aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
            aFile.write("</body></html>")
        end
    end
end

def saveMonthPages()
    # Sort the posts by date (earliest first)
    sortedPosts = @pages.sort { |a,b| a[1]['date'] <=> b[1]['date'] }
    while sortedPosts.length > 0
        curMonth = sortedPosts[0][1]['date'].slice(0, 7)
        baseFileName = CalendarDir + curMonth + ".html"
        fileName = @targetDir + baseFileName
        #puts "curMonth is #{ curMonth }"
        File.open(fileName, 'w') do |aFile|
            aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
            aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
            aFile.write("<style>" + LJPollCSS + "</style>\n")
            monthDay = dateToFriendlyDate(sortedPosts[0][1]['date'])
            month = monthDay[0]
            year = monthDay[2]
            aFile.write("<title>Posts in #{ month } #{ year }</title></head>\n")
            aFile.write("<body>\n")
            aFile.write("<p style=\"background-color: lightgray\">Posts in #{ month } #{ year }</p>\n")
            while (sortedPosts.length > 0 and sortedPosts[0][1]['date'].slice(0,7) == curMonth)
                curPost = sortedPosts[0][1]
                monthDay = dateToFriendlyDate(curPost['date'])
                month = monthDay[0]
                day = monthDay[1]
                aFile.write("<p>#{ month } #{ day }  #{ curPost['date'].slice(11, curPost['date'].length) } - #{ getPostSummary(curPost, '../') }")
                if (curPost['numComments'] > 0)
                    aFile.write(" (#{ curPost['numComments'] } comments)")
                end
                aFile.write("</p>")
                sortedPosts.delete_at(0)
            end
            aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
            aFile.write("</body></html>")
        end
    end
end

def saveMoodsPage(mood, posts)
    safeMood = mood.makeFileNameSafe
    baseFileName = MoodsDir + safeMood + ".html"
    fileName = @targetDir + baseFileName
    File.open(fileName, 'w') do |aFile|
        aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
        aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
        aFile.write("<style>" + LJPollCSS + "</style>\n")
        aFile.write("<title>Posts with mood #{ mood } (#{ posts.length })</title></head>\n")
        aFile.write("<body>\n")
        aFile.write("<p style=\"background-color: lightgray\">Posts with mood #{ mood } (#{ posts.length })</p>\n")
        # Sort the comments by date (put latest ones first)
        posts.sort! {|a,b| b['date'] <=> a['date']}
        posts.each do |postInfo|
            writePostMain(aFile, postInfo, '../', true)
        end
        aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
        aFile.write("</body></html>")
    end
    cgiMood = (safeMood.split(' ').collect {|x| CGI::escape(x) }).join("%20")
    return MoodsDir + cgiMood + ".html"
end

def saveCommentsPage(id, comments)
    username = @userIdToUser[id]
    if username == nil
        return
    end
    baseFileName = CommentsDir + username + ".html"
    fileName = @targetDir + baseFileName
    File.open(fileName, 'w') do |aFile|
        aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
        aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
        aFile.write("<style>" + LJPollCSS + "</style>\n")
        user = @userIdToUser[id]
        aFile.write("<title>Comments of #{ @userIdToUser[id] } (#{ comments.length })</title></head>\n")
        aFile.write("<body>\n")
        aFile.write("<p style=\"background-color: lightgray\">Comments of #{ getLJUserString(user) } (#{ comments.length })</p>\n")
        # Sort the comments by date (put latest ones first)
        comments.sort! {|a,b| b['date'] <=> a['date']}
        comments.each do |comment|
            aFile.write("<p><span style=\"background-color: lightgray\">Comment on post #{ getPostSummary(@pages[comment['jitemid']], '../') }:<br>#{ @timeZone.utc_to_local(comment['date']) }</span><br>#{ tidyUpPost(comment['body'], '../', -1) }</p>\n")
        end
        aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
        aFile.write("</body></html>")
    end
    return baseFileName
end

def saveIndexPage()
    File.open(@targetDir + 'index.html', 'w') do |aFile|
        aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
        aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
        aFile.write("<style>" + LJPollCSS + "</style>\n")
        aFile.write("<title>LiveJournal backup for #{ @username }</title></head>\n")
        aFile.write("<body><p style=\"background-color: lightgray\">LJ backup for #{ getLJUserString(@username) }</p>\n")
        aFile.write("<p>This backup was done on #{ Date.today() } ")
        if (@publicOnly)
            aFile.write("and includes only public posts.  <b>This is not a full backup!</b></p>\n")
        else
            aFile.write("and includes all posts, public and private.  <b>Do not publish this</b> unless you're comfortable with people reading all your posts!</p>\n")
        end
        aFile.write("<p><a href=\"#{ RecentPostsDir }index.html\">Recent posts</a></p>")
        aFile.write("<p><a href=\"stats.html\">Statistics</a></p>\n")
        if (@pages.length > 0)
            sortedPosts = @pages.sort { |a,b| a[1]['date'] <=> b[1]['date'] }
            firstYear = sortedPosts[0][1]['date'].slice(0, 4).to_i
            lastYear = sortedPosts[-1][1]['date'].slice(0, 4).to_i
            aFile.write("<p>Entries in ")
            (firstYear .. lastYear).each do |curYear|
                aFile.write(" <a href=\"#{ CalendarDir + curYear.to_s }.html\">#{ curYear }</a> ")
            end
            aFile.write("</p>\n")
        end
        aFile.write("<p><a href=\"tags.html\">Tags</a></p>\n")
        sortedMemories = @memories.sort {|a,b| a[0] <=> b[0]}
        if (sortedMemories.length > 0) 
            aFile.write("<p>Memories:</p>\n<ul>\n")
            sortedMemories.each do |mem|
                foundOne = false
                mem[1].each do |postNum|
                    pagesToUse = @pages.find_all {|p| p[1]['linkId'] == postNum}
                    if (pagesToUse.length > 0)
                        if (not foundOne)
                            foundOne = true
                            aFile.write("<li>#{ mem[0]}:\n<ul>")
                        end
                        pageToUse = pagesToUse[0]
                        aFile.write("<li>#{ pageToUse[1]['date']} - #{ getPostSummary(pageToUse[1], "") }</li>\n")
                    end
                end
                if (foundOne)
                    aFile.write("</ul></li>\n")
                end
            end
            aFile.write("</ul>\n")
        end
        aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
        aFile.write("</body></html>")
    end
end

def saveStatsPage()
    commentCounter = Hash.new { |hash,key| hash[key] = [] }
    # Remove comments that are on locked posts, if we're public only
    # Also remove any that are unattached to any posts.
    @comments = @comments.reject {|k,v| not @pages.include?(v['jitemid']) }
    @comments.each {|c| commentCounter[c[1]['posterid']].push(c[1]) }
    sortedComments = commentCounter.sort {|a,b| b[1].length <=> a[1].length }
    moods = @pages.find_all {|a| a[1]['moodtext'] != nil }
    moodCounter = Hash.new { |hash,key| hash[key] = [] }
    moods.each {|a| moodCounter[a[1]['moodtext']].push(a[1]) }
    sortedMoods = moodCounter.sort {|a,b| b[1].length <=> a[1].length }
    File.open(@targetDir + 'stats.html', 'w') do |aFile|
        aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
        aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
        aFile.write("<style>" + LJPollCSS + "</style>\n")
        aFile.write("<title>Statistics</title></head>\n")
        aFile.write("<body><p style=\"background-color: lightgray\">Statistics</p>\n")
        pagesDateSorted = @pages.sort{|a,b| a[1]['date'] <=> b[1]['date'] }
        commentsPerPost = "0"
        wordsPerPost = "0"
        totalWords = (@pages.collect {|a| a[1]['numWords']}).inject(0) {|sum,item| sum + item}
        stdDevWords = std_dev(@pages.collect {|a| a[1]['numWords']})
        stdDevComments = std_dev(@pages.collect {|a| a[1]['numComments']})
        if pagesDateSorted.length > 0
            commentsPerPost = format("%.2f", @comments.length.to_f / pagesDateSorted.length)
            wordsPerPost = format("%.2f", totalWords.to_f / pagesDateSorted.length)
        end
        aFile.write("<p>#{ pagesDateSorted.length } post#{ if (pagesDateSorted.length != 1) then 's' end} total, #{ @comments.length } comment#{ if (@comments.length != 1) then 's' end} total (#{ commentsPerPost } per post, standard deviation #{ format("%.2f", stdDevComments) })</p>\n")
        aFile.write("<p>#{ totalWords } word#{ if (totalWords != 1) then 's' end} total (#{ wordsPerPost } per post, standard deviation #{ format("%.2f", stdDevWords) })</p>\n")
        if (pagesDateSorted.length > 0)
            aFile.write("<p>First post: #{ pagesDateSorted[0][1]['date'] } - #{ getPostSummary(pagesDateSorted[0][1], '') }</p>\n")
        end
        if (pagesDateSorted.length > 1)
            aFile.write("<p>Last post: #{ pagesDateSorted[pagesDateSorted.length - 1][1]['date'] } - #{ getPostSummary(pagesDateSorted[pagesDateSorted.length - 1][1], '') }</p>\n")
        end
        #maxNumComments = -1
        sortedPages = @pages.sort {|a,b| b[1]['numComments'] <=> a[1]['numComments']}
        aFile.write("<p>Most commented posts:</p>\n")
        aFile.write("<table><tr><th>Post</th><th>Comments</th></tr>\n")
        i = 0
        # Allow for the fact that, when the journal gets quite large,
        # we may want more top comments/words/etc.
        numTop = Math.sqrt(sortedPages.length).to_i
        while (i < [numTop,NumTopComments].max and sortedPages.length > i)
            aFile.write("<tr><td>")
            aFile.write(getPostSummary(sortedPages[i][1], ''))
            aFile.write("</td><td>")
            aFile.write(sortedPages[i][1]['numComments'])
            aFile.write("</td></tr>\n")
            i += 1
        end
        aFile.write("</table>\n")
        longPages = @pages.sort {|a,b| b[1]['numWords'] <=> a[1]['numWords']}
        aFile.write("<p>Longest posts:</p>\n")
        aFile.write("<table><tr><th>Post</th><th>Words</th></tr>\n")
        i = 0
        while (i < [numTop,NumTopWords].max and longPages.length > i)
            aFile.write("<tr><td>")
            aFile.write(getPostSummary(longPages[i][1], ''))
            aFile.write("</td><td>")
            aFile.write(longPages[i][1]['numWords'])
            aFile.write("</td></tr>\n")
            i += 1
        end
        aFile.write("</table>\n")
        aFile.write("<table><tr><th>Commentor</th><th>Number</th></tr>\n")
        sortedComments.each do |cc|
            aFile.write("<tr><td>")
            user = @userIdToUser[cc[1][0]['posterid']]
            aFile.write(getLJUserString(user))
            aFile.write("</td><td><a href=\"#{ saveCommentsPage(cc[0], cc[1]) }\">#{ cc[1].length }</a></td></tr>\n")
        end
        aFile.write("</table>\n")

        aFile.write("<table><tr><th>Mood</th><th>Number</th></tr>\n")
        sortedMoods.each do |cc|
            aFile.write("<tr><td>#{ cc[0] }</td>")
            aFile.write("<td><a href=\"#{ saveMoodsPage(cc[0], cc[1]) }\">#{ cc[1].length }</a></td></tr>\n")
        end
        aFile.write("</table>\n")
        if (@pagesWithPolls.length > 0) 
            aFile.write("<p>Pages with polls:</p>\n")
            @pagesWithPolls = @pagesWithPolls.sort {|a,b| b <=> a}
            aFile.write("<ul>\n")
            @pagesWithPolls.each do |id|
                aFile.write("<li>#{ @pages[id]['date'] } - #{ getPostSummary(@pages[id], '') }</li>\n")
            end
            aFile.write("</ul>\n")
        end

        aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
        aFile.write("</body></html>")
    end
end

def getPollText(pollid)
    #puts "Got poll with id #{ pollid }"
    resp = getPageWithRetry(APIPollPath + pollid.to_s + "&mode=results", {})
    pageText = resp.body
    #File.open('/tmp/ljpoll-' + pollid.to_str, 'w') { |file| file.write(pageText) }
    # Starts with <!-- Content -->, ends with <div class='clear'></div>
    # FFV - this is obviously not very robust!
    pollStartRE = Regexp.new('<!-- Content -->')
    #pollEndRE = Regexp.new("<div class=('|\")clear('|\")")
    pollEndRE = Regexp.new("<!-- pocket.*")
    pollStartMatch = pollStartRE.match(pageText)
    if (pollStartMatch == nil)
        @logger.logError("Malformed poll #{ pollid } (couldn't find start)", false)
        return ""
    end
    pollText = pollStartMatch.post_match
    pollEndMatch = pollEndRE.match(pollText)
    if (pollEndMatch == nil)
        @logger.logError("Malformed poll #{ pollid } (couldn't find end)", false)
        return ""
    end
    pollText = pollEndMatch.pre_match
    # Use our own images, and get rid of horizontal bars
    # Don't think this actually happens anymore, it's all css
    ljImageRE = Regexp.new("http://stat.livejournal.com/img/poll/")
    ljImageMatch = ljImageRE.match(pollText)
    while (ljImageMatch != nil)
        pollText = ljImageMatch.pre_match + "../#{ ImagesDir }" + ljImageMatch.post_match
        ljImageMatch = ljImageRE.match(pollText)
    end
    hrRE = Regexp.new("<hr/?>")
    hrMatch = hrRE.match(pollText)
    while (hrMatch != nil)
        pollText = hrMatch.pre_match + hrMatch.post_match
        hrMatch = hrRE.match(pollText)
    end

    #@logger.logText('TODO: getPollText: ' + pollText, false)
    return pollText
end

def tidyUpPost(event, pathToRoot, id)
    event = event.split("\n").join("<br>\n")
    ljUserRE = Regexp.new('\<lj user=\"(.*?)\"\s*/?\>')
    ljUserMatch = ljUserRE.match(event)
    while (ljUserMatch != nil)
        user = ljUserMatch[1]
        event = ljUserMatch.pre_match + getLJUserString(user) + ljUserMatch.post_match
        ljUserMatch = ljUserRE.match(event)
    end
    ljTagRE = Regexp.new("\<a href=\"(http://)?#{ @username }\.livejournal\.com/tag/(.*?)\"")
    ljTagMatch = ljTagRE.match(event)
    while (ljTagMatch != nil)
        user = ljTagMatch[1]
        tag = ljTagMatch[2]
        event = ljTagMatch.pre_match + "<a href=\"" + pathToRoot + TagsDir + tag + ".html\"" + ljTagMatch.post_match
        ljTagMatch = ljTagRE.match(event)
    end
    ljPostRE = Regexp.new("\<a href=\"(http://)?#{ @username }\.livejournal\.com/")
    ljPostMatch = ljPostRE.match(event)
    while (ljPostMatch != nil)
        user = ljPostMatch[1]
        event = ljPostMatch.pre_match + "<a href=\"" + pathToRoot + PostsDir + ljPostMatch.post_match
        ljPostMatch = ljPostRE.match(event)
    end
    ljPollRE = Regexp.new('\<lj-poll-(\d+)\>')
    ljPollMatch = ljPollRE.match(event)
    while (ljPollMatch != nil)
        if (not @pagesWithPolls.include?(id))
            @pagesWithPolls.push(id)
        end
        pollid = ljPollMatch[1]
        if (not @polls.include?(pollid))
            @polls[pollid] = getPollText(pollid)
        end
        event = ljPollMatch.pre_match + @polls[pollid] + ljPollMatch.post_match
        ljPollMatch = ljPollRE.match(event)
        #@logger.logText('TODO: event iteration: ' + event, false)
    end
    
    return event
end

def tidyUpSubject(subject)
    if (subject == nil or subject == '')
        return "(no subject)"
    else
        return subject
    end
end

def appendCommentElems(container, parentMap, parentId)
    if (parentMap[parentId] != nil)
        parentMap[parentId].each do |comment|
            commentElem = container.add_element 'comment'
            posterid = comment[1]['posterid']
            commentElem.attributes['posterid'] = posterid
            username = @userIdToUser[posterid]
            if username != nil
                commentElem.attributes['username'] = username.encode("UTF-8")
            end
            commentElem.attributes['date'] = comment[1]['date']
            bodyElem = commentElem.add_element 'body'
            bodyElem.add_text(comment[1]['body'].encode("UTF-8"))
            if (parentMap.include?(comment[0]))
                repliesElem = commentElem.add_element 'replies'
                appendCommentElems(repliesElem, parentMap, comment[0])
            end
        end
    end
end
 
def saveXml()
    doc = REXML::Document.new
    doc << REXML::XMLDecl.new
    journalElem = REXML::Element.new "journal"
    journalElem.attributes['username'] = @username
    journalElem.attributes['publicOnly'] = @publicOnly
    #TODO - overall props
    @pages.each do |postId, post|
        postElem = journalElem.add_element "post"
        postElem.attributes["id"] = postId
        titleElem = postElem.add_element "title"
        titleElem.add_text post['subject']
        if post['locked']
            postElem.attributes['locked'] = post['locked']
        end
        ['moodtext', 'music', 'location'].each do |attrName|
            if post.include?(attrName)
                #pp post[attrName]
                #pp post[attrName].encoding
                postElem.attributes[attrName] = post[attrName].encode("UTF-8")
            end
        end
        postElem.attributes['linkId'] = post['linkId']
        postElem.attributes['date'] = post['date']
        memoryInfos = @memories.find_all {|m| m[1].include?(post['linkId']) }
        if memoryInfos.length > 0
            memoryTags = memoryInfos.map {|m| m[0]}
            memoriesElem = postElem.add_element "memories"
            memoryTags.each do |tagName|
                memoryElem = memoriesElem.add_element "memory"
                memoryElem.add_text tagName
            end
        end
        if (post['tags'] != nil)
            tagsElem = postElem.add_element 'tags'
            post['tags'].each do |tag|
                tagElem = tagsElem.add_element 'tag'
                tagElem.add_text tag
            end
        end
        postElem.attributes['numWords'] = post['numWords']
        bodyElem = postElem.add_element 'body'
        bodyElem.add_text(post['event'].split("\n").join("<br>\n"))
        postElem.attributes['numComments'] = post['numComments']
        if (post['numComments'] > 0)
            commentsElem = postElem.add_element 'comments'
            appendCommentElems(commentsElem, post['commentParentMap'], 0)
        end
    end
    doc << journalElem

    File.open(@targetDir + 'allPosts.xml', 'w') do |aFile|
        doc.write(aFile, 2)
    end
end

def savePageWithComments(post)
    # First, find the corresponding comments.
    # FFV - hash this up if performance is a problem
    #pp post
    commentList = @comments.find_all {|c| c[1]['jitemid'] == post['itemid'].to_i}
    parentMap = {}
    commentList.each do |comment|
        parent = comment[1]['parentid']
        if (parentMap.include?(parent))
            parentMap[parent].push(comment)
        else
            parentMap[parent] = []
            parentMap[parent].push(comment)
        end
        if (comment[1]['date'] == nil)
            @logger.logError("---NIL DATE ON COMMENT--- (#{ comment[0] })", false)
            #pp comment[1]
        end
    end
    parentMap.each do |parent|
        parent[1].sort {|a,b| a[1]['date'] <=> b[1]['date']}
    end
    postInfo = {}
    # Don't save the page if we're public only and locked.
    postInfo['locked'] = (post.include?('security') and post['security'] != "public")
    if (postInfo['locked'] and @publicOnly)
        return
    end
    postInfo['id'] = post['itemid'].to_i
    postInfo['linkId'] = post['itemid'].to_i * 256 + post['anum'].to_i
    postInfo['date'] = post['eventtime']
    postInfo['numComments'] = commentList.length
    postInfo['commentParentMap'] = parentMap
    wordRE = Regexp.new('\w')
    tempPost = post['event'].to_s.dup
    # For word counting, collapse lj user= to one word...
    ljUserRE = Regexp.new('<lj user="(.*?)".*?>', Regexp::IGNORECASE)
    tempPost.gsub!(ljUserRE, '\1')
    # and remove tags.
    tagRE = Regexp.new('<.*?>')
    tempPost.gsub!(tagRE, ' ')
    postInfo['numWords'] = tempPost.split(/\s+/).select {|x| wordRE.match(x) != nil }.length
    postInfo['subject'] = tidyUpSubject(post['subject'].to_s.force_encoding("UTF-8"))
    postInfo['tags'] = nil
    postInfo['event'] = post['event'].to_s
    if (post.include?('props'))
        if (post['props'].include?('current_moodid'))
            postInfo['moodid'] = post['props']['current_moodid']
        end
        if (post['props'].include?('current_mood'))
            postInfo['moodtext'] = post['props']['current_mood'].to_s.force_encoding("UTF-8")
        elsif postInfo.include?('moodid')
            postInfo['moodtext'] = MoodMap[postInfo['moodid'].to_i].to_s
        end
        if (post['props'].include?('current_music'))
            postInfo['music'] = post['props']['current_music'].to_s.force_encoding("UTF-8")
        end
        if (post['props'].include?('current_location'))
            postInfo['location'] = post['props']['current_location'].to_s.force_encoding("UTF-8")
        end
        if (post['props'].include?('taglist'))
            postInfo['tags'] = post['props']['taglist'].to_s.force_encoding("UTF-8").split(',')
            postInfo['tags'] = postInfo['tags'].collect {|x| x.strip()}
            postInfo['tags'].each { |tag| @tagsToPosts[tag].push(postInfo) }
        end
    end
    @pages[postInfo['id']] = postInfo
    File.open(@targetDir + PostsDir + postInfo['linkId'].to_s + '.html', 'w') do |aFile|
        aFile.write("<!DOCTYPE html PUBLIC \"-//W3C//DTD HTML 4.01//EN\" \"http://www.w3.org/TR/html4/strict.dtd\">\n")
        aFile.write("<html><head><meta http-equiv=\"Content-Type\" content=\"text/html; charset=utf-8\"><meta http-equiv=\"Content-Style-Type\" content=\"text/css\">\n")
        aFile.write("<style>" + LJPollCSS + "</style>\n")
        aFile.write("<title>#{ postInfo['subject'] }</title></head>\n")
        aFile.write("<body>")
        writePostMain(aFile, postInfo, '../')
        aFile.write("<hr>\n")
        if (commentList.length > 0)
            aFile.write("<p style=\"background-color: lightgray\">#{ commentList.length } comment#{ if commentList.length != 1 then 's' end}</p>\n")

            printComments(parentMap, 0, 0, aFile, '../')
        end
        aFile.write("<p>This backup was done by <a href=\"http://gregstoll.dyndns.org/secure/ljbackup\">LJBackup</a>.</p>")
        aFile.write("</body></html>")
    end
    return
end


def printComments(parentMap, parentId, indent, aFile, pathToRoot)
    if (parentMap[parentId] != nil)
        parentMap[parentId].each do |comment|
            username = @userIdToUser[comment[1]['posterid']]

            aFile.write("<p style=\"margin-left: #{ 50 * indent }px\"><span style=\"background-color: lightgray\">Comment from #{ getLJUserString(username) }:<br>#{ @timeZone.utc_to_local(comment[1]['date']) }</span><br>#{ tidyUpPost(comment[1]['body'], pathToRoot, -1) }</p>\n")
            if (parentMap.include?(comment[0]))
                printComments(parentMap, comment[0], indent + 1, aFile, pathToRoot)
            end
        end
    end
end

def LJRetriever.doLJBackup(targetDir, params, logger)
    ljr = LJRetriever.new(targetDir, params['username'], params['password'], params['TimeZoneString'], params['Delay'].to_f, params['Attempts'].to_i, (params.include?('PublicOnly')), -1, logger)
    ljr.main()
end

end # class LJRetriever

if __FILE__ == $0 then
    require './parseconfigfile'
    params = ParseConfigFile::parseConfigFile('.logininfo')
    ljr = LJRetriever.new(OutputDir, params['Username'], params['Password'], params['TimeZoneString'], params['Delay'].to_f, params['Attempts'].to_i, (params['PublicOnly'].to_i == 1), params['MaxPosts'].to_i, TextLogger.new)
    ljr.main()
end

end
