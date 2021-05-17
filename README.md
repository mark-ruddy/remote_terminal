# Remote Terminal
Remote administration tool for Linux written in Ruby.  

Clients are persistent and will stay active waiting to reconnect if the server closes. You can launch clients before starting the server and they will attempt to connect every 2 seconds.

### Gems Required
- colorize
- etc   
- net/http
- socket

### Server Usage
The server is a single standalone file.  
Host is always "localhost", Port defaults to 3200.    
`./server.rb <PORT>`

### Client Usage
client.rb relies on helpers.rb for some commands.  
Host defaults to "localhost", Port defaults to 3200.  
`./client.rb <HOST> <PORT>`

### How To Use
First the Server must be running and client(s) have connected.  
Type `help` to see a list of available commands.  
Type `clients` to see all connected clients.

The `exe` command requires a client to be selected with `select <ID>`.  \
`exe <BASH_COMMAND>` e.g. `exe touch new_file.txt`, `exe shutdown now`, `exe wget -r --tries=10 www.google.com`. \
Some specific commands that Ruby cannot execute will have no effect, such as `exe cd /opt`.


`hardexit` will close the server, and also send a destroy message to clients, closing them too. `exit` will close the server only and clients will continue to listen for a server restart. Use `destroy <ID>` to remove a specific client.

### Shell Output Issue

Most commands like `exe ls` will return text output to the server. \
Other commands such as `exe wget www.google.com` will work but there will be no output to the server until you run `exe ls` to see the downloaded file. The server cannot see all I/O on the client side as its not a full reverse shell.

If you have a fix or any other improvements feel free to contribute it!
