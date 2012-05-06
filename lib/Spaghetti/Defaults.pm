package Spaghetti::Defaults;

    use Pony::Stash;
    
    sub import
        {
            ##
            ##  Configs
            ##
            
            # Init configs in stash if they did not define.
            #
            
            Pony::Stash->new('./resources/stash.dat');
            Pony::Stash->findOrCreate(dbDriver => 'MySQL');
            Pony::Stash->findOrCreate(thread => {size => 20});
            Pony::Stash->findOrCreate(news => {size => 20});
            Pony::Stash->findOrCreate(gitdir => '/home/git/repositories');
            
            Pony::Stash->findOrCreate
            ( git =>
              {
                all => 1,
                dir => '/home/git/repositories',
              }
            );
            
            Pony::Stash->findOrCreate
            ( mail =>
              {
                from => 'no-reply@lorcode.org',
                site => 'http://lorcode.org:3000',
              }
            );
            
            Pony::Stash->findOrCreate
            ( user =>
              {
                cookies      => 'some random string',
                salt         => 'some random string',
                enable_registration => 1,
                attempts     => 3,
                mailAttempts => 3,
                expairMail   => 86400,
                sshKeyLimit  => 5,
              }
            );
            
            Pony::Stash->findOrCreate
            ( defaultUserConf =>
              {
                isTreeView => 0,
                lang  => 'en',
                langs => 'en ru'
              }
            );
            
            Pony::Stash->findOrCreate
            ( project =>
              {
                repos => 10,
                topic => 1,
              }
            );
            
            Pony::Stash->findOrCreate
            ( site =>
              {
                isAkismet => 0,
                akismetApi => '',
                root => 'http://lorcode.org/',
              }
            );
        }

1;
