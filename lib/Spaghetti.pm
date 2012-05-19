package Spaghetti;
use Mojo::Base 'Mojolicious';
    
    our $VERSION = '0.000012';
    our $COMMIT  = '';
    
    use Pony::Model::Crud;
    use Pony::Model::Dbh::MySQL;
    use Spaghetti::SQL;
    use Module::Load;
    
    # This method will run once at server start
    sub startup
        {
            my $this = shift;
            
            # Get commit id
            #
            
            if ( open C, './Changes' )
            {
                my $line = <C>;
                $COMMIT = [ split ' ', $line ]->[1];
                
                close C;
            }
            
            # Preload lang hashes.
            #
            
            for my $l (split /\W/,Pony::Stash->get('defaultUserConf')->{langs})
            {
                my $class = "Spaghetti::I18N::$l";
                load $class;
                Pony::View::Translate->new->Lexicon->{$l} = $class->Lexicon;
            }
            
            # Database
            #
            
            my $db = Pony::Stash->get('database');
            Pony::Model::Dbh::MySQL->new($db);
            
            ##
            ##  Plugins
            ##
            
            $this->plugin('B');
            $this->plugin('StripTags');
            $this->plugin('MkPath');
            $this->plugin('user');
            $this->plugin('access');
            $this->plugin('message');
            $this->plugin('mail');
            $this->plugin('thread');
            
            ##
            ##  Routes
            ##
            
            my $r = $this->routes->namespace('Spaghetti::Controller');
            my $a = $r->bridge->to('admin#auth')->route('/admin')
                      ->to( namespace => 'Spaghetti::Controller::Admin' );
            
            $a->route('/')
                ->to('admin#index')
                  ->name('admin_admin_index');
            
            $r->route('/404')
                ->to('#notFound')
                  ->name('404');
            
            # Config
            #
            
            $a->route('/config/edit')
                ->to('config#edit')
                  ->name('admin_config_edit');
            $a->route('/config/save')
                ->to('config#save')
                  ->name('admin_config_save');
            
            # User
            #
            
            $r->route('/user/home')
              ->to('user#home')
                ->name('user_home');
            $r->route('/user/home/thread')
              ->to('user#thread')
                ->name('user_thread');
            $r->route('/user/home/projects')
              ->to('user#projects')
                ->name('user_projects');
            $r->route('/user/createPrivateThread')
              ->to('user#createPrivateThread')
                ->name('user_createPrivateThread');
            $r->route('/user/profile/:id', id => qr/\d+/)
                ->to('user#profile')
                  ->name('user_profile');
            $r->route('/user/login')
                ->to('user#login')
                  ->name('user_login');
            $r->route('/user/login/mail')
                ->to('user#loginViaMail')
                  ->name('user_loginViaMail');
            $r->route('/user/login/mail/confirm')
                ->to('user#mailConfirm')
                  ->name('user_mailConfirm');
            $r->route('/user/logout')
                ->to('user#logout')
                  ->name('user_logout');
            $r->route('/user/registration')
                ->to('user#registration')
                  ->name('user_registration');
            $r->route('/user/change/password')
                ->to('user#changePassword')
                  ->name('user_change_password');
            $r->route('/user/change/mail')
                ->to('user#changeMail')
                  ->name('user_change_mail');
            $r->route('/user/config')
                ->to('user#config')
                  ->name('user_config');
            $r->route('/user/items')
                ->to('user#items')
                  ->name('user_items');
            $r->route('/user/ssh')
                ->to('user#ssh')
                  ->name('user_ssh');
            $r->route('/user/home/responses')
                ->to('user#responses')
                  ->name('user_responses');
            $r->route('/user/ssh/:id', id => qr/\d+/)
                ->to('user#sshEdit')
                  ->name('user_sshEdit');
            
            $a->route('/user')
                ->to('user#list')
                  ->name('admin_user_list');
            $a->route('/user/:page')
                ->to('user#list')
                  ->name('admin_user_list');
            $a->route('/user/show/:id')
                ->to('user#show')
                  ->name('admin_user_show');
            $a->route('/user/:id/group/:group/add')
                ->to('user#addGroup')
                  ->name('admin_user_addGroup');
            $a->route('/user/:id/group/:group/remove')
                ->to('user#removeGroup')
                  ->name('admin_user_removeGroup');
            $a->route('/user/delete/:id')
                ->to('user#delete')
                  ->name('admin_user_delete');
            
            # Thread
            #
            
            $r->route('/thread/create')
                ->to('thread#create')
                  ->name('thread_create');
            $r->route('/thread/new/topic')
                ->to('thread#createTopic')
                  ->name('thread_createTopic');
            $r->route('/thread/edit/:id')
                ->to('thread#edit')
                  ->name('thread_edit');
            $r->route('/topic/edit/:id')
                ->to('thread#editTopic')
                  ->name('topic_edit');
            $r->route('/thread')
                ->to('thread#show')
                  ->name('thread_index');
            $r->route( '/thread/:url/page/:page',
                       url => qr/[\w\d\-]+/, page => qr/\d+/ )
                ->to('thread#show')
                  ->name('thread_show_p');
            $r->route('/thread/tracker')
                ->to('thread#tracker')
                  ->name('thread_tracker_index');
            $r->route('/thread/tracker/:page', page => qr/\d/)
                ->to('thread#tracker')
                  ->name('thread_tracker');
            $r->route('/thread/:url')
                ->to('thread#show')
                  ->name('thread_show');
            
            $a->route('/thread/edit/:id')
                ->to('thread#edit')
                  ->name('admin_thread_edit');
            $a->route('/thread/:id/type/:type/add')
                ->to('thread#addType')
                  ->name('admin_thread_addType');
            $a->route('/thread/:id/type/:type/remove')
                ->to('thread#removeType')
                  ->name('admin_thread_removeType');
            $a->route('/thread')
                ->to('thread#list')
                  ->name('admin_thread_list');
            $a->route('/thread/:page', page => qr/\d+/)
                ->to('thread#list')
                  ->name('admin_thread_list_p');
            $a->route('/thread/show/:id')
                ->to('thread#show')
                  ->name('admin_thread_show');
            
            # News
            #
            
            $r->route('/news/:url')
                ->to('news#show')
                  ->name('news_show');
            $r->route('/news/:url/page/:page', page => qr/\d*/)
                ->to('news#show')
                  ->name('news_show_p');
            $r->route('/news/page/:page', page => qr/\d*/)
                ->to('news#list')
                  ->name('news_list');
            $r->route('/news')
                ->to('news#list')
                  ->name('news_index');
            
            $a->route('/news/from/topic/:id', id => qr/\d+/)
                ->to('news#topicToNews')
                  ->name('admin_news_topicToNews');
            $a->route('/news/edit/:id', id => qr/\d+/)
                ->to('news#edit')
                  ->name('admin_news_edit');
            
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
            $a->route('/group/:group/access/type/:type',
                        group => qr/\d+/, type => qr/\d+/)
                ->to('group#access')
                  ->name('admin_group_access');
            
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
            
            # Projects
            #
            
            $a->route('/project')
                ->to('project#list')
                  ->name('admin_project_list');
            $a->route('/project/:page', page => qr/\d+/)
                ->to('project#list')
                  ->name('admin_project_list');
            $a->route('/project/read/:id', id => qr/\d+/)
                ->to('project#read')
                  ->name('admin_project_read');
            $a->route('/project/edit/:id', id => qr/\d+/)
                ->to('project#edit')
                  ->name('admin_project_edit');
            $a->route('/project/delete/:id', id => qr/\d+/)
                ->to('project#delete')
                  ->name('admin_project_delete');
            $a->route('/project/create')
                ->to('project#create')
                  ->name('admin_project_create');
            
            $r->route('/project/:url')
                ->to('project#read')
                  ->name('project_read');
            $r->route('/project/edit/:url')
                ->to('project#update')
                  ->name('project_update');
            $r->route('/projects' )
                ->to('project#list')
                  ->name('project_list');
            $r->route('/project')
                ->to('project#list')
                  ->name('project_list');
            
            # Items
            #
            
            $r->route('/item/give/:item/to/:user',
                        item => qr/\d+/, user => qr/\d+/)
                ->to('item#giveByArchon')
                  ->name('item_giveByArchon');
            $r->route('/item/activate/:item', item => qr/\d+/)
                ->to('item#activate')
                  ->name('item_activate');
            
            # Repos
            #
            
            $r->route('/repo/create/:id', id => qr/\d+/)
                ->to('repo#create')
                  ->name('repo_create');
            $r->route('/:project/:repo')
                ->to('repo#read')
                  ->name('repo_read');
            $r->route('/:project/:repo/edit')
                ->to('repo#update')
                  ->name('repo_update');
            $r->route('/:project/:repo/access')
                ->to('repo#changeAccess')
                  ->name('repo_changeAccess');
            $r->route('/:project/:repo/:object')
                ->to('repo#readObject')
                  ->name('repo_readObject');
            #$r->route('/:project/:repo/:object/tree')
            #    ->to('repo#readTree', format => '0')
            #      ->name('repo_readTree');
            $r->route('/:project/:repo/:object/tree*dir')
                ->to('repo#readTreePath', format => '0')
                  ->name('repo_readTreePath');
            #$r->route('/:project/:repo/:object/blob')
            #    ->to('repo#readBlob', format => '0')
            #      ->name('repo_readBlob');
            $r->route('/:project/:repo/:object/blob*dir')
                ->to('repo#readBlobPath', format => '0')
                  ->name('repo_readBlobPath');
            
            ##
            ##  Helpers
            ##
            
            use Pony::View::Translate;
            
            my $translate = new Pony::View::Translate;
            
            $this->helper
            (
                l => sub
                {
                    my ( $self, @param ) = @_;
                    $translate->t( @param );
                }
            );
            
            $this->helper
            (
                paginator => sub
                {
                    my ( $self, $urlName, $cur, $count, $size, $params ) = @_;
                    my $html = '';
                    
                    return '' if not defined $count or $count <= $size;
                    
                    my $last = int ( $count / $size );
                     ++$last if $count % $size;
                    
                    # Render first page.
                    #
                    $html .= sprintf '<a href="%s">&lArr;</a>',
                             $self->url_for($urlName, page => 1) if $cur != 1;
                    
                    for my $i ( $cur - 5 .. $cur + 5 )
                    {
                        next if $i < 1 || $i > $last;
                        
                        $params = [] unless defined $params;
                        
                        $html .= ( $i == $cur ?
                                    sprintf '<span>%s</span>', $cur :
                                    sprintf '<a href="%s">%s</a>',
                                    $self->url_for( $urlName, @$params,
                                                    page => $i), $i );
                    }
                    
                    # Render last page.
                    #
                    $html .= sprintf '<a href="%s">&rArr;</a>',
                             $self->url_for($urlName, page => $last)
                                if $cur != $last;
                    
                    new Mojo::ByteStream("<div class=\"paginator\">$html</div>")
                }
            );
            
            $this->helper
            (
                format_datetime => sub
                {
                    my ( $self, $val ) = @_;
                    
                    return '' unless defined $val;
                    
                    my ( $str ) = $this->getDateTime($val);
                    
                    return $str;
                }
            );
            
            $this->helper
            (
                render_datetime => sub
                {
                    my ($self, $val) = @_;
                    
                    return '' unless defined $val;
                    
                    my ($str,$year,$mon,$day,$hour,$min,$sec) =
                                                    $this->getDateTime($val);
                    
                    $str ||= '';
                    
                    return new Mojo::ByteStream
                           ( qq[<time datetime="$year-$mon-${day}T$hour:]
                             . qq[$min:${sec}Z">$str</time>] );
                }
            );
            
            $this->helper
            (
                getDateTime => sub
                {
                    my ($self, $val) = @_;
                    
                    return ('never',0,0,0,0,0,0) if $val == 0;
                    
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
                                                $self->l('now')
                                            : $self->l('a few seconds ago')
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
                            
                            return $val ." ". $self->l("${type}s$a")
                                        ." ". $self->l('ago');
                        }
                }
            );
        }

    sub notFound
        {
            shift->render('not_found');
        }

1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

