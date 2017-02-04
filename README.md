# ljbackup
Script to back up a LiveJournal account.  If you want to run this online, see [LJBackup](https://gregstoll.com/ljbackup).

If you want to run it locally, you just need the `getljposts.rb` and `parseconfigfile.rb` scripts.  Make a text file named `.logininfo` in that same directory with the following format:

>      Username=<LJ username>
>      Password=<LJ password>
>      TimeZoneString=<TimeZoneString>
>      PublicOnly=<0 or 1>
>      Delay=0
>      Attempts=2
>      MaxPosts=50000

The `TimeZoneString` should be something like `America/Chicago`.  `PublicOnly` controls whether it downloads protected posts or not.
