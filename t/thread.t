#!/usr/bin/env perl

use Test::More tests => 62;
use Test::Mojo;

use lib './lib';

use_ok 'Mojolicious';
use_ok 'Spaghetti';
use_ok 'Pony::Object';
use_ok 'Pony::Stash';
use_ok 'Pony::Crud::MySQL';
use_ok 'Pony::Crud::Dbh::MySQL';

use Pony::Crud::Dbh::MySQL;
use Pony::Stash;

package Test;
use Pony::Object;
    
    sub init
        {
            my $this = shift;
            
            my $t = Test::Mojo->new('Spaghetti');
            
               $t->get_ok('/thread/tracker')
                 ->status_is(200)
                 ->text_is(h1 => 'Tracker');
            
               $t->get_ok( '/thread/' . (10_000_000 + $this->getLastId) )
                 #->status_is(404)
                 ->text_is(h1 => 'Not found');
               
               # Before create new thread
               # We should create new user (test).
               
               $t->post_form_ok('/user/registration' =>
               {
                   name     => 'test',
                   mail     => 'test@example.com',
                   password => 'testopassword',
                   show     => 'on',
                   notbot   => 'on'
               })->status_is(302);
            
            my $user = Pony::Crud::MySQL->new('user')->read({mail => 'test@example.com'});
               
               $t->post_form_ok('/thread/new/topic' =>
               {
                   title    => 'Hello!',
                   text     => 'World!',
                   parentId => 0,
                   topicId  => 0
               })#->status_is(403)
                 ->text_is(h1 => 'Forbidden');
               
               $t->post_ok('/user/logout')
                 ->status_is(302);
               
               $t->post_form_ok('/user/login' =>
               {
                   mail     => 'admin@lorcode.org',
                   password => 'gfhjkm=0;'
               })->status_is(302);
               
               $t->post_ok('/user/home')
                 ->status_is(200);
               
               $t->post_form_ok('/thread/new/topic' =>
               {
                   title    => 'Hello!',
                   text     => 'World!',
                   parentId => 0,
                   topicId  => 0
               })->status_is(302);
               
            my $rootTopicId = $this->getLastId;
               
               # mk group
               #
               
               $t->post_form_ok('/admin/type/new' =>
               {
                   name     => 'Simple',
                   desc     => 'R,C - user group',
                   prioritet=> 1
               })->status_is(302);
               
               # bind user-group to type-group
               #
               
               $t->post_form_ok('/admin/group/999/access/type/1' =>
               {
                   read     => 'on',
                   create   => 'on'
               })->status_is(302);
               
               # Add thread to thread DataType group.
               #
               
               $t->post_ok("/admin/thread/$rootTopicId/type/1/add")
                 ->status_is(302);
               
               # Login as simple user
               #
               
               $t->post_form_ok('/user/login' =>
               {
                   mail     => 'test@example.com',
                   password => 'testopassword',
               })->status_is(302);
               
               $t->post_form_ok('/thread/new/topic' =>
               {
                   title    => 'Hello yourself!',
                   text     => 'World!',
                   parentId => $rootTopicId,
                   topicId  => $rootTopicId
               })->status_is(302);
               
            my $topicId = $this->getLastId;
               
               $t->post_form_ok('/thread/new/topic' =>
               {
                   title    => 'Hello yourself!',
                   text     => 'World!',
                   parentId => $topicId,
                   topicId  => $topicId
               })->status_is(302);
               
               $t->post_form_ok('/thread/create' =>
               {
                   text     => 'Hello World!',
                   parentId => $topicId,
                   topicId  => $topicId
               })->status_is(302);
               
               $t->get_ok('/topic/edit/' . $rootTopicId)
                 #->status_is(403)
                 ->text_is(h1 => 'Forbidden');
               
               $t->get_ok('/thread/edit/' . $rootTopicId)
                 #->status_is(403)
                 ->text_is(h1 => 'Forbidden');
               
               $t->get_ok('/thread/edit/' . $topicId)
                 ->status_is(200);
               
               $t->post_form_ok('/thread/edit/' . $topicId =>
               {
                   text     => 'CHanged',
                   parentId => $rootTopicId,
                   threadId => $rootTopicId,
               })->status_is(302);
               
               $t->get_ok('/thread/edit/' . $topicId)
                 ->content_like( qr/CHanged/ );
               
               # Move thread by user.
               # Does not realized yet.
               
               #$t->post_form_ok('/thread/edit/' . $topicId =>
               #{
               #    text     => 'CHanged',
               #    parentId => 0,
               #    threadId => 0,
               #})->status_is(403);
               
               $t->post_ok('/topic/edit/' . $rootTopicId =>
               {
                   title    => 'Try to change topic',
                   text     => 'Try to change topic',
               })#->status_is(403)
                 ->text_is(h1 => 'Forbidden');
               
               $t->get_ok('/topic/edit/' . $topicId)
                 ->status_is(200)
                 ->text_is(h1 => 'Edit topic');
               
               $t->post_ok('/topic/edit/' . $topicId =>
               {
                   title    => 'Try to change topic 2',
                   text     => 'Try to change topic 2',
               })->status_is(200);
               
               $t->get_ok('/thread/tracker')
                 ->status_is(200)
                 ->text_is(h1 => 'Tracker');
               
               $t->get_ok('/thread')
                 ->status_is(200)
                 ->content_like( qr/Hello/ );
               
               $t->get_ok('/topic/edit/' . (10_000_000 + $this->getLastId))
                 #->status_is(404)
                 ->text_is(h1 => 'Forbidden');
        }
        
    sub getLastId
        {
            my $this = shift;
            my $data = shift;
            my $dbh  = Pony::Crud::Dbh::MySQL->new->dbh;
            
            my $sth = $dbh->prepare("SELECT LAST_INSERT_ID()");
               $sth->execute();
            
            my $row = $sth->fetchrow_hashref();
            
            return $row->{'LAST_INSERT_ID()'};
        }
    
1;

package main;

    # Init stash.
    #
    
    Pony::Stash->new('./resources/stash.dat');

    # Database.
    #
    
    my $db = Pony::Stash->get('database');
    Pony::Crud::Dbh::MySQL->new($db);
    
    # Run tests.
    #
    
    new Test;

