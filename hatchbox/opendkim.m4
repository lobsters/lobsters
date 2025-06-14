INPUT_MAIL_FILTER(`opendkim',
        `S=local:/var/spool/postfix/opendkim/opendkim.socket, F=, T=S:4m;R:4m;E:10m')dnl
