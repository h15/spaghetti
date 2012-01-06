package Forum;
use Mojo::Base 'Mojolicious';
    
    use lib '../pony/lib/';
    use Pony::Stash;
    use Pony::Crud::Dbh::MySQL;
    
    # This method will run once at server start
    sub startup
        {
            my $this = shift;
            
            Pony::Stash->new('./resources/stash.dat');
            Pony::Crud::Dbh::MySQL->new({
                host     => 'localhost',
                dbname   => 'pony',
                user     => 'pony',
                password => 'pony secret'
            });
            
            $this->plugin('user');
            $this->plugin('I18N');
            
            # Routes
            my $r = $this->routes->namespace('Forum::Controller');;
            
            # User
            #
            
            $r->route('/user/home')
              ->to('user#home')
                ->name('user_home');
            $r->route('/user/profile/:id', id => qr/\d+/)
                ->to('user#profile')
                  ->name('user_profile');
            $r->route('/user/login')
                ->to('user#login')
                  ->name('user_login');
            $r->route('/user/logout')
                ->to('user#logout')
                  ->name('user_logout');
            $r->route('/user/registration')
                ->to('user#registration')
                  ->name('user_registration');
            
            # Forum
            #
            
            $r->route('/forum/new')
                ->to('thread#create')
                  ->name('thread_create');
            $r->route('/forum/new/topic')
                ->to('thread#createTopic')
                  ->name('thread_createTopic');
            $r->route('/forum')
                ->to('thread#show')
                  ->name('thread_index');
            $r->route('/forum/:url')
                ->to('thread#show')
                  ->name('thread_show');
            $r->route('/forum/:url/:page', page => qr/\d+/)
                ->to('thread#show')
                  ->name('thread_show');
            
            $this->helper
            (
                render_datetime => sub
                {
                    my ($self, $val) = @_;
                    
                    my ( $s, $mi, $h, $d, $mo, $y ) = localtime;
                    my ( $sec, $min, $hour, $day, $mon, $year )
                            = map { $_ < 10 ? "0$_" : $_ } localtime($val);
                    
                    # Pretty time.
                    my $str = (
                        $year == $y ?
                            $mon == $mo ?
                                $day == $d ?
                                    $hour == $h ?
                                        $min == $mi ?
                                            $sec == $s ?
                                                $self->l('now')
                                            : $self->l('a few seconds ago')
                                        : ago( min => $mi - $min, $self )
                                    : ago( hour => $h - $hour, $self )
                                : "$hour:$min, $day.$mon"
                            : "$hour:$min, $day.$mon"
                        : "$hour:$min, $day.$mon." . ($year + 1900)
                    );
                    
                    $year += 1900;
                    
                    return new Mojo::ByteStream
                           ( qq[<time datetime="$year-$mon-${day}T$hour:]
                             . qq[$min:${sec}Z">$str</time>] );
                    
                    sub ago
                        {
                            my ( $type, $val, $self ) = @_;
                            my $a = $val % 10;
                            
                            # Different word for 1; 2-4; 0, 5-9
                            # (in Russian it's true).
                            
                            $a = (
                                $a != 1 ?
                                    $a > 4 ?
                                        5
                                    : 2
                                : 1
                            );
                            
                            return $val ." ". $self->l("${type}s$a") ." "
                                   . $self->l('ago');
                    }
                }
            );
        }

1;
