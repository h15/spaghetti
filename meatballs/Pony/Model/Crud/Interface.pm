package Pony::Model::Crud::Interface;
use Pony::Object -abstract;

    sub create  : Abstract {};
    sub read    : Abstract {};
    sub update  : Abstract {};
    sub delete  : Abstract {};
    sub list    : Abstract {};
    sub count   : Abstract {};

1;
