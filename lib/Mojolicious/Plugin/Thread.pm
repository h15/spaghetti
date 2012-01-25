package Mojolicious::Plugin::Thread;
use Pony::Object 'Mojolicious::Plugin';

    use Pony::Stash;

    our $VERSION = '0.000001';

    sub register
        {
            my ( $self, $app ) = @_;
            
            $app->helper
            (
                render_thread => sub
                {
                    my $html = subTree(@_);
                    
                    return new Mojo::ByteStream( $html );
                }
            );
        }
    
    # I'll burn in hell for that >.<
    #
    
    sub subTree
        {
            my ( $this, $ids, $threads, $topicForm, $form, $create ) = @_;
            my $html = '';
            my $b = new Mojo::ByteStream;
            
            for my $id ( @$ids )
            {
                my $t = $threads->{$id};
                
                $html .= sprintf qq{<article class="post" id="thread-%d">
                                    <a name="thread-%d"></a>
                                    <nav>
                                        <div class="sefl">
                                            <a href="%s#thread-%d">#</a>
                                            <a href="%s">%s</a>
                                        </div>
                                        <div class="parents">
                                            <a href="%s">&uarr;</a>
                                            <a href="%s">&uArr;</a>
                                        </div>
                                        <div class="time">},
                            
                            $t->{id},
                            $t->{id},
                            $this->url_for('thread_show', url => $t->{topicId} ), $t->{id},
                            ($this->url_for('thread_show', url => ( $t->{url} ? $t->{url} : $t->{id} ) )), ($t->{title} || '&rarr;'),
                            $this->url_for('thread_show', url => $t->{parentId}),
                            $this->url_for('thread_show', url => $t->{topicId});
                        
                if ( $t->{modifyAt} == $t->{createAt} )
                {
                    $html .= $this->render_datetime($t->{modifyAt});
                }
                else
                {
                    $html .= sprintf qq{<acronym title="%s">
                                            %s
                                        </acronym>},
                                     $this->format_datetime($t->{createAt}),
                                     $this->render_datetime($t->{modifyAt});
                }
                
                $html .= sprintf qq{</div><div class="user">%s</div>},
                         $this->render_user({ id    => $t->{author},
                                              name  => $t->{name},
                                              mail  => $t->{mail},
                                              banId => $t->{banId} });
                    
                if ( $t->{owner} == $this->user->{id} || $t->{W} > 0 )
                {
                    $html .= sprintf qq{<div class="controlls"><div class="editThread">
                                        <a href="%s">%s</a>
                                        </div></div>},
                             (
                                defined $t->{title} ?
                                    $this->url_for('topic_edit', id => $t->{id} ) :
                                    $this->url_for('thread_edit', id => $t->{id} )
                             ),
                             $this->l('edit');
                }
                 
                $html .= sprintf qq{<div class=cb></div></nav><div class="postContent">%s</div>},
                                 $t->{text};

                if ( $create )
                {
                    $form->elements->{parentId}->value = $t->{id};
                    $form->elements->{topicId}->value  = $t->{topicId};
                    $topicForm->elements->{parentId}->value = $t->{id};
                    $topicForm->elements->{topicId}->value  = $t->{topicId};
                    
                    $html .= sprintf qq{
                                <a href="#" class=showButton id="showButton-%d">%s</a>
                                <a href="#" class="hidden hideButton" id="hideButton-%d">%s</a>
                                
                                <a href="#" class=showButton id="showButton-createTopic%d">%s</a>
                                <a href="#" class="hidden hideButton" id="hideButton-createTopic%d">%s</a>
                                
                                <div class=hidden id="hiddenArea-%d">%s</div>
                                <div class=hidden id="hiddenArea-createTopic%d">%s</div>
                            },
                            $t->{id}, $this->l('response'),
                            $t->{id}, $this->l('hide'),
                            $t->{id}, $this->l('create topic'),
                            $t->{id}, $this->l('hide'),
                            $t->{id}, Mojo::ByteStream->new( $form->render ),
                            $t->{id}, Mojo::ByteStream->new( $topicForm->render );
                }
                
                if ( defined $t->{childs} && @{ $t->{childs} })
                {
                    $html .= sprintf qq{<div style="margin:5px 5px 5px 20px">%s</div>},
                             subTree($this, $t->{childs}, $threads, $topicForm, $form, $create);
                }
                
                $html .= '</article>';
            }
                
            return $html;
        }
1;

__END__

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012, Georgy Bazhukov.

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

=cut

