# Requirements

IBM 7.2 with technology refresh 7 or higher. For more details concerning the Slack interface used, please see [Slack Chat Post Message Method](https://api.slack.com/methods/chat.postMessage). 

### SLKMSG - Send a message to a slack channel using a bot
```
BOTH            COMP              'Company code'                   3A
BOTH            CHANNEL           'Slack Channel'                100A
BOTH            MESSAGE           'Message to send'            32000A
```
Please note that the message program -- SLKMSG -- currently requires that the channel and message fields be terminated by a '*'. Basic usage example:
```
call slkmsg parm('TOM' 'Updates*' 'This is an update sent to the Updates channel by <@tom>.*') 
```
