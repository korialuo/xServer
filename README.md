# xServer
A skynet-based server project for most kinds of games.
This project uses a modified version of skynet: https://github.com/korialuo/skynet

# Usage
1. git clone https://github.com/korialuo/skynet
2. git clone https://github.com/korialuo/xServer
3. cd skynet
4. make linux/macosx/freebsd
5. cp -r skynet lualib luaclib service cservice ../xServer/
6. cd ../xServer/
7. ./skynet config/config.loginsvr
8. ./skynet config/config.gamesvr