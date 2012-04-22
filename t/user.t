#!/usr/bin/env perl

use Test::More tests => 48;
use Test::Mojo;

use lib './lib';

use_ok 'Mojolicious';
use_ok 'Spaghetti';
use_ok 'Pony::Object';

package Test;
use Pony::Object;
    
    sub init
        {
            my $t = Test::Mojo->new('Spaghetti');
            
               $t->get_ok('/user/registration')
                 ->status_is(200)
                 ->text_is(h1 => 'Registration');
               
               $t->get_ok('/user/profile/1')
                 ->status_is(200)
                 ->text_is(h1 => 'Profile admin');
               
               $t->get_ok('/user/login/mail')
                 ->status_is(200)
                 ->text_is(h1 => 'Login via mail');
               
               $t->post_form_ok('/user/registration' =>
               {
                   name     => 'test',
                   mail     => 'test@example.com',
                   password => 'testopassword',
                   show     => 'on',
                   notbot   => 'on'
               })->status_is(302);
               
               $t->post_form_ok('/user/registration' =>
               {
                   name     => 'test',
                   mail     => 'test@example.com',
                   password => 'testopassword',
                   show     => 'on',
                   notbot   => 'on'
               })->status_is(200)
                 ->content_like( qr/Mail is already used/ );
               
               $t->get_ok('/user/login')
                 ->status_is(200)
                 ->text_is(h1 => 'Login');
               
               $t->post_form_ok('/user/login' =>
               {
                   mail     => 'test@example.com',
                   password => 'testopassword',
               })->status_is(302);
               
               $t->get_ok('/user/home')
                 ->status_is(200)
                 ->text_is(h1 => 'Profile test');
              
               $t->get_ok('/user/home/thread')
                 ->status_is(200)
                 ->text_is(h1 => 'Private thread');
                 
               $t->get_ok('/user/home/projects')
                 ->status_is(200)
                 ->text_is(h1 => 'My projects');
                 
               $t->get_ok('/user/items')
                 ->status_is(200)
                 ->text_is(h1 => 'My items');
                 
               $t->get_ok('/user/change/mail')
                 ->status_is(200)
                 ->text_is(h1 => 'Change mail');
              
               $t->post_form_ok('/user/change/mail' =>
               {
                   mail     => 'test@example.com',
                   password => 'testopassword'
               })->status_is(200)
                 ->content_like( qr/E-mail is already used/ );
              
               $t->post_form_ok('/user/change/mail' =>
               {
                   mail     => 'test@example.net',
                   password => 'testopassword'
               })->status_is(302);
               
               $t->post_form_ok('/user/change/password' =>
               {
                   oldPassword => 'testopassword',
                   newPassword => 'testopassword'
               })->status_is(302);
               
               $t->get_ok('/user/logout')
                 ->status_is(200);
               
               $t->post_ok('/user/logout')
                 ->status_is(302);
        }
    
1;

package main;

    new Test;

    # Clean up before she comes.
    #
    
    use Pony::Model::Crud::MySQL;
    
    my $model = new Pony::Model::Crud::MySQL('user');
    my $user  = $model->read({mail => 'test@example.net'});
    
    $model->delete({ id => $user->{id} });
    
    Pony::Model::Crud::MySQL->new('thread')->delete({ id => $user->{threadId} });
    
