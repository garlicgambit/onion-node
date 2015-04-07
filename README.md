Plug and play Bitcoin onion node - create a more private Bitcoin network for yourself and others

What is it:
- Plug-and-play Bitcoin node with privacy and security enhancements.

The goal is simple:
- Make it really easy to run a Bitcoin node ('Hey look pa: even grandma can run a Bitcoin onion node')
- Make Bitcoin transactions more private
- Make the Bitcoin network more censorship resistant
- Make it cheap to run a Bitcoin node (cheap hardware to buy/low electric bill)

How is this done:
- All Bitcoin traffic is routed trough the Tor network and stays inside the Tor network by leveraging Tor onion services (no use of Tor exit nodes/clearnet)
  - This creates end-to-end encrypted connections which makes the Bitcoin transactions more private
  - Traffic is mixed with the other Tor users which makes Bitcoin traffic more anonymous (you can't be anonymous on your own)
  - Plus Tor has built-in properties that make it an effective censorship circumvention tool.

License:
- Consider the code to be public domain. If you or your jurisdiction do not accept that then consider the code to be released under Creative Commons 0 (CC0). If you or your jurisdiction do not accept that... well then settle for the MIT license. What we mean to say is that you are free to copy, modify and relicense the code by all means. But don't hold us liable for any damages incurred by using or abusing the software.
- Code which is copied from other projects remains under the original license.

Ok... how do I get it up and running?
- Get a Raspberry Pi 2 (not tested on Raspberry Pi 1 – let us know if it works)
- Install Raspbian on a micro SD card with 64 gigabyte storage or more (storage for 32+ GB Bitcoin blockchain)
- Start the Raspberry Pi
- You will be presented with the blue 'Raspberry Pi Software Configuration Tool' screen
- On this screen select: '1 Expand Filesystem'
- It is highly recommended to change the user password: Select: '2 Change User Password'
- Select: 'Finish' 
- Select: 'Yes' to reboot the system
- The Raspberry Pi will now reboot
- Login as the user 'pi'
- On your clean Raspbian install run: 'sudo git clone https://www.github.com/garlicgambit/onion-node.git /etc/onion-node/'
- To install and configure your node run: 'sudo /etc/onion-node/install.sh'
- Wait for 1 to 1.5 hours (yep, it is compiling Bitcoin from source... so be patient)
- After the installation the system will automatically reboot. So you should be presented with a login prompt
- Login as the user 'pi'
- Check if the Bitcoin process is running with the command: 'bitcoin-cli getinfo'. It should output that your node has more then 1 connection.
- Let your node sync for a couple of hours/days 
- After a couple of hours/days run 'bitcoin-cli getinfo'
- The total number of connections should be more then 8. This means that you are contributing to the Bitcoin network.
- That's it

Like this project? Help us out! Lots of work still needs to be done and any sort of help is appreciated:
- We really need more testers. Just grab the code, install it, run it, break it and send us feedback
- Contributions in all forms and sizes are greatly appreciated: ideas, comments, code, suggestions, donations, infrastructure, etc

If you have any questions, comments or suggestions you can contact us at:
jmercier@openmailbox (dot) org

GPG key:
0xF7698FEE3295ABB5

Bitcoin donation address:
1CgVbpriVS9yG5ZZZZ6mGG4WBWkgKVaqqd
