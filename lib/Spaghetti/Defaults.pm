package Spaghetti::Defaults;
use Pony::Object;

    # Default config.
    #
    
    public conf =>
        {
            dbDriver => 'MySQL',
            thread =>
            {
              size => 20
            },
            news =>
            {
              size => 20
            },
            git =>
            {
              all => 1,
              dir => '/home/git/repositories'
            },
            mail =>
            {
              from => 'no-reply@lorcode.org',
              site => 'http://codewars.ru',
            },
            user =>
            {
              cookies => 'some random string',
              salt => 'some random string',
              expiration => 86400,
              enable_registration => 1,
              attempts => 3,
              mailAttempts => 3,
              expairMail => 86400,
              sshKeyLimit => 5,
            },
            defaultUserConf =>
            {
              isTreeView => 1,
              lang => 'ru',
              langs => [ qw/ru/ ],
            },
            project =>
            {
              repos => 10,
              topic => 1,
            },
            site =>
            {
              isAkismet => 0,
              akismetApi => '',
              root => 'http://codewars.ru',
            },
            accessFilter =>
            {
              1  => {'192.168.105.*', 'allow'},
              99 => {'*.*.*.*', 'deny'}
            }
        };

1;
