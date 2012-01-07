package Forum;
use Mojo::Base 'Mojolicious';
    
    use lib '../pony/lib/';
    use Pony::Stash;
    use Pony::Crud::Dbh::MySQL;
    
    # This method will run once at server start
    sub startup
        {
            my $this = shift;
            
            ##
            ##  Configs
            ##
            
            Pony::Stash->new('./resources/stash.dat');
            Pony::Crud::Dbh::MySQL->new({
                host     => 'localhost',
                dbname   => 'pony',
                user     => 'pony',
                password => 'pony secret'
            });
            
            ##
            ##  Plugins
            ##
            
            $this->plugin('user');
            $this->plugin('I18N');
            
            ##
            ##  Routes
            ##
            
            my $r = $this->routes->namespace('thread::Controller');
            my $a = $r->bridge->to('admin#auth')->route('/admin')
                      ->to( namespace => 'thread::Controller::Admin' );
            
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
            
            # thread
            #
            
            $r->route('/thread/create')
                ->to('thread#create')
                  ->name('thread_create');
            $r->route('/thread/new/topic')
                ->to('thread#createTopic')
                  ->name('thread_createTopic');
            $r->route('/thread')
                ->to('thread#show')
                  ->name('thread_index');
            $r->route('/thread/:url')
                ->to('thread#show')
                  ->name('thread_show');
            $r->route('/thread/:url/:page', page => qr/\d+/)
                ->to('thread#show')
                  ->name('thread_show');
            $r->route('/thread/edit/:id')
                ->to('thread#edit')
                  ->name('thread_edit');
            $r->route('/topic/edit/:id')
                ->to('thread#editTopic')
                  ->name('topic_edit');
            
            $a->route('/thread/edit/:id')
                ->to('thread#edit')
                  ->name('admin_thread_edit');
            
            # Groups
            #
            
            $a->route('/group')
                ->to('group#list')
                  ->name('admin_group_list');
            $a->route('/group/:page', page => qr/\d*/)
                ->to('group#list')
                  ->name('admin_group_list');
            $a->route('/group/new')
                ->to('group#create')
                  ->name('admin_group_create');
            $a->route('/group/show/:id', page => qr/\d+/)
                ->to('group#show')
                  ->name('admin_group_show');
            $a->route('/group/edit/:id', id => qr/\d+/)
                ->to('group#edit')
                  ->name('admin_group_edit');
            $a->route('/group/delete/:id', id => qr/\d+/)
                ->to('group#delete')
                  ->name('admin_group_delete');
            
            # Data Types
            #
            
            $a->route('/type')
                ->to('data_type#list')
                  ->name('admin_dataType_list');
            $a->route('/type/:page', page => qr/\d*/)
                ->to('data_type#list')
                  ->name('admin_dataType_list');
            $a->route('/type/new')
                ->to('data_type#create')
                  ->name('admin_dataType_create');
            $a->route('/type/show/:id', page => qr/\d+/)
                ->to('data_type#show')
                  ->name('admin_dataType_show');
            $a->route('/type/edit/:id', id => qr/\d+/)
                ->to('data_type#edit')
                  ->name('admin_dataType_edit');
            $a->route('/type/delete/:id', id => qr/\d+/)
                ->to('data_type#delete')
                  ->name('admin_dataType_delete');
            
            ##
            ##  Helpers
            ##
            
            $this->helper
            (
                format_datetime => sub
                {
                    my ( $self, $val ) = @_;
                    my ( $str ) = $this->getDateTime($val);
                    
                    return $str;
                }
            );
            
            $this->helper
            (
                render_datetime => sub
                {
                    my ($self, $val) = @_;
                    
                    my ($str,$year,$mon,$day,$hour,$min,$sec) = $this->getDateTime($val);
                    
                    return new Mojo::ByteStream
                           ( qq[<time datetime="$year-$mon-${day}T$hour:]
                             . qq[$min:${sec}Z">$str</time>] );
                }
            );
            
            $this->helper
            (
                # FIXME: can't use I18N plugin here:
                #        $self->stash->{I18N} is undef.
                
                getDateTime => sub
                {
                    my ($self, $val) = @_;
                    
                    my ( $s, $mi, $h, $d, $mo, $y ) = localtime;
                    my ( $sec, $min, $hour, $day, $mon, $year )
                            = map { $_ < 10 ? "0$_" : $_ } localtime($val);
                    
                    # Some peoples dislike null-month :)
                    ++$mon; ++$mo;
                    
                    # Pretty time.
                    my $str = (
                        $year == $y ?
                            $mon == $mo ?
                                $day == $d ?
                                    $hour == $h ?
                                        $min == $mi ?
                                            $sec == $s ?
                                                $thread::I18N::ru::Lexicon{'now'}
                                            : $thread::I18N::ru::Lexicon{'a few seconds ago'}
                                        : ago( min => $mi - $min, $self )
                                    : ago( hour => $h - $hour, $self )
                                : "$hour:$min, $day.$mon"
                            : "$hour:$min, $day.$mon"
                        : "$hour:$min, $day.$mon." . ($year + 1900)
                    );
                    
                    $year += 1900;
                    
                    return ( $str, $year, $mon, $day, $hour, $min, $sec );
               
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
                            
                            return $val ." ". $thread::I18N::ru::Lexicon{"${type}s$a"}
                                        ." ". $thread::I18N::ru::Lexicon{ago};
                        }
                }
            );
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

