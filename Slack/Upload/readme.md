
# Requirements

IBM 7.2 with technology refresh 7 or higher. For more details concerning the Slack interface used, please see the [Slack File Upload Method](https://api.slack.com/methods/files.upload).

### SLKUPL - Upload a file to a slack channel using a bot
```
BOTH            COMP              'Company code'                   3A
BOTH            FILE              'File path and name'           255A
BOTH            EXTENSION         'File extension'                 3A
```
Please note that the file upload program -- SLKUPL -- does *NOT* require that the file or extension fields be terminated by a '*'. Basic usage example:
```
call slkupl parm('TOM' '/TOM/home/updates.txt' 'txt') 
```
