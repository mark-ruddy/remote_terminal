# ryat
Lightweight Linux RAT  
Written in Ruby 3.0.0  
### Gems Required
- colorize
- etc   
- net/http

### Server Usage
The server is a single standalone file  
Host is always "localhost", Port defaults to 3000  
`./server.rb <PORT>`

### Client Usage
client.rb relies on helpers.rb for some commands  
Host defaults to "localhost", Port defaults to 3000  
`./client.rb <HOST> <PORT>`
