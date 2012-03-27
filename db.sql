SET SQL_MODE="NO_AUTO_VALUE_ON_ZERO";

drop table if exists `user`;
create table `user`
(
    `id`        int(11) unsigned auto_increment primary key,
    `mail`      varchar(255) character set utf8 collate utf8_general_ci   not null,
    `password`  varchar(32)  character set ascii collate ascii_general_ci not null,
    `name`      varchar(255) character set utf8 collate utf8_general_ci   not null,
    `createAt`  int(11) not null,
    `modifyAt`  int(11) not null,
    `accessAt`  int(11) not null,
    `banId`     int(11) not null default 0,
    `banTime`   int(11) not null default 0,
    `attempts`  int(1)  unsigned not null default 0,
    `threadId`  int(11) unsigned not null,
    `sshKeyCount` tinyint(4) unsigned not null default 0,
    
    unique (`mail`),
    unique (`name`),
    
    FOREIGN KEY (`threadId`) REFERENCES `thread`(`id`),
    FOREIGN KEY (`banId`)    REFERENCES `ban`(`id`)
);

drop table if exists `sshKey`;
create table `sshKey`
(
    `id`        int(11) unsigned auto_increment primary key,
    `userId`    int(11) unsigned not null,
    `status`    tinyint(4) unsigned not null default 0,
    `key`       varchar(4096) character set ascii collate ascii_general_ci not null,

    FOREIGN KEY (`userId`) REFERENCES `user`(`id`)
);

INSERT INTO `user` (`id`, `mail`, `password`, `name`, `createAt`, `modifyAt`, `accessAt`, `banId`, `banTime`) VALUES
(0,'anonymous@lorcode.org','','anonymous',0,0,0,0,0),
(1,'admin@lorcode.org','eaf959d9e23b7a07bf6364f50efd6007','admin',0,0,0,0,0);

drop table if exists `item`;
create table `item`
(
    `id`        int(11) unsigned auto_increment primary key,
    `name`      varchar(32)  character set ascii collate ascii_general_ci not null,
    `desc`      varchar(255) character set ascii collate ascii_general_ci not null,
    `trade`     tinyint(4)   not null default 0,
    `effect`    varchar(16)  character set ascii collate ascii_general_ci,
    `params`    varchar(32)  character set ascii collate ascii_general_ci
);

INSERT INTO `item` (`id`, `name`, `desc`, `trade`, `effect`, `params`) VALUES
(1,'nil', 'nothing',1,NULL,NULL),
(2,'Project ticket', 'Free ticket for one project',0,'CreateProject',1);

drop table if exists `userToItem`;
create table `userToItem`
(
    `id`     int(11) unsigned auto_increment primary key,
    `userId` int(11) unsigned not null,
    `itemId` int(11) unsigned not null,
    
    FOREIGN KEY (`userId`) REFERENCES `user`(`id`),
    FOREIGN KEY (`itemId`) REFERENCES `item`(`id`)
);

drop table if exists `userInfo`;
create table `userInfo`
(
    `id`        int(11) unsigned not null default 0,
    `desc`      varchar(9999) character set utf8 collate utf8_general_ci not null,
    `conf`      blob,
    `responses` tinyint(4) unsigned not null default 0,
    
    FOREIGN KEY (`id`)  REFERENCES `user`(`id`)
);

drop table if exists `task`
(
      
);

drop table if exists `mailConfirm`;
create table `mailConfirm`
(
    `expair`    int(11) unsigned not null default 0,
    `mail`      varchar(255) character set utf8 collate utf8_general_ci not null,
    `secret`    varchar(32) character set ascii collate ascii_general_ci not null,
    `attempts`  int(1) unsigned not null default 0
);

drop table if exists `ban`;
create table `ban`
(
    `id`        int(11) unsigned not null auto_increment primary key,
    `desc`      varchar(255) character set utf8 collate utf8_general_ci not null,
    `userId`    int(11) unsigned not null,
    `time`      int(11) unsigned not null default 0,
    `expair`    int(11) unsigned not null,
    
    FOREIGN KEY (`userId`)  REFERENCES `user`(`id`)
);

drop table if exists `group`;
create table `group`
(
    `id`        int(11) unsigned not null auto_increment primary key,
    `name`      varchar(64) character set utf8 collate utf8_general_ci not null,
    `desc`      varchar(1024) character set utf8 collate utf8_general_ci not null,
    `prioritet` int(11) unsigned not null default 0
);

INSERT INTO `group` (`id`, `name`, `desc`, `prioritet`) VALUES
(0,'Anonymous','',0),
(1,'Admin','',0),
(2,'Archon','Gifts, carma',1),
(998, 'Project leader', '', 100),
(999, 'User', 'Simple user', 9999);

drop table if exists `userToGroup`;
create table `userToGroup`
(
    `userId`    int(11) unsigned not null,
    `groupId`   int(11) unsigned not null,
    
    FOREIGN KEY (`userId`)  REFERENCES `user`(`id`),
    FOREIGN KEY (`groupId`) REFERENCES `group`(`id`)
);

INSERT INTO `userToGroup` (`userId`, `groupId`) VALUES
(0,0),
(1,1);

drop table if exists `access`;
create table `access`
(
    `groupId`   int(11) unsigned not null,
    `dataTypeId`int(11) unsigned not null,
    `RWCD`      int(11) unsigned not null default 0,
    
    FOREIGN KEY (`groupId`)    REFERENCES `group`(`id`),
    FOREIGN KEY (`dataTypeId`) REFERENCES `dataType`(`id`)
);

drop table if exists `dataType`;
create table `dataType`
(
    `id`        int(11) unsigned not null auto_increment primary key,
    `name`      varchar(64) character set utf8 collate utf8_general_ci not null,
    `desc`      varchar(1024) character set utf8 collate utf8_general_ci not null,
    `prioritet` int(11) unsigned not null default 0
);

drop table if exists `threadToDataType`;
create table `threadToDataType`
(
    `threadId`  int(11) unsigned not null,
    `dataTypeId`int(11) unsigned not null,
    
    FOREIGN KEY (`threadId`)   REFERENCES `thread`(`id`),
    FOREIGN KEY (`dataTypeId`) REFERENCES `dataType`(`id`)
);

drop table if exists `thread`;
create table `thread`
(
    `id`        int(11) unsigned not null auto_increment primary key,
    `owner`     int(11) unsigned not null default 1,
    `author`    int(11) unsigned not null default 1,
    `createAt`  int(11) unsigned not null default 0,
    `modifyAt`  int(11) unsigned not null default 0,
    `parentId`  int(11) unsigned not null default 0,
    `topicId`   int(11) unsigned not null default 0,
    `textId`    int(11) unsigned not null default 0,
    
    FOREIGN KEY (`author`)   REFERENCES `user`(`id`),
    FOREIGN KEY (`owner`)    REFERENCES `user`(`id`),
    FOREIGN KEY (`parentId`) REFERENCES `thread`(`id`),
    FOREIGN KEY (`topicId`)  REFERENCES `topic`(`id`),
    FOREIGN KEY (`textId`)   REFERENCES `text`(`id`)
);

drop table if exists `text`;
create table `text`
(
    `id`        int(11) unsigned not null auto_increment primary key,
    `threadId`  int(11) unsigned not null,
    `text`      varchar(60000) character set utf8 collate utf8_general_ci not null,
    
    FOREIGN KEY (`threadId`)  REFERENCES `thread`(`id`)
);

drop table if exists `topic`;
create table `topic`
(
    `threadId`  int(11) unsigned not null,
    `title`     varchar(64) character set utf8 collate utf8_general_ci not null,
    `url`       varchar(64) character set ascii collate ascii_general_ci not null primary key,
    
    FOREIGN KEY (`threadId`)  REFERENCES `thread`(`id`)
);

drop table if exists `threadToTag`;
create table `threadToTag`
(
    `threadId`  int(11) unsigned not null,
    `tagId`     int(11) unsigned not null,
    
    FOREIGN KEY (`threadId`) REFERENCES `thread`(`id`),
    FOREIGN KEY (`tagId`)    REFERENCES `tag`(`id`)
);

drop table if exists `tag`;
create table `tag`
(
    `id`        int(11) unsigned not null auto_increment primary key,
    `url`       varchar(64) character set ascii collate ascii_general_ci not null,
    `name`      varchar(64) character set utf8 collate utf8_general_ci not null,
    
    unique(`url`)
);

drop table if exists `news`;
create table `news`
(
    `threadId`  int(11) unsigned not null,
    `legend`    varchar(140) character set utf8 collate utf8_general_ci not null,
    
    FOREIGN KEY (`threadId`)  REFERENCES `thread`(`id`)
);

drop table if exists `project`;
create table `project`
(
    `id`        int(11) unsigned not null,
    `url`       varchar(128) character set ascii collate ascii_general_ci not null,
    `title`     varchar(256) character set utf8 collate utf8_general_ci not null,
    `repos`     tinyint(4) unsigned not null default 0,
    `maxRepo`   tinyint(4) unsigned not null default 1,
    
    UNIQUE(`url`),
    FOREIGN KEY (`id`)    REFERENCES `thread`(`id`)
);

drop table if exists `repo`;
create table `repo`
(
    `id`        int(11) unsigned not null,
    `title`     varchar(256) character set utf8 collate utf8_general_ci not null,
    `url`       varchar(128) character set ascii collate ascii_general_ci not null,
    
    FOREIGN KEY (`id`)    REFERENCES `thread`(`id`)
);

drop table if exists `repoGroup`;
create table `repoGroup`
(
    `id`        int(11) unsigned not null auto_increment primary key,
    `name`      varchar(256) character set utf8 collate utf8_general_ci not null,
    `desc`      varchar(1024) character  set utf8 collate utf8_general_ci not null
);

drop table if exists `repoRights`;
create table `repoRights`
(
    `repoId`    int(11)     unsigned not null,
    `groupId`   int(11)     unsigned not null,
    `rwpcd`     tinyint(4)  unsigned not null default 0,
    
    FOREIGN KEY (`repoId`)  REFERENCES `repo`(`id`),
    FOREIGN KEY (`groupId`) REFERENCES `repoGroup`(`id`)
);

drop table if exists `repoRightsViaUser`;
create table `repoRightsViaUser`
(
    `repoId`    int(11)     unsigned not null,
    `userId`    int(11)     unsigned not null,
    `rwpcd`     tinyint(4)  unsigned not null default 0,
    
    FOREIGN KEY (`repoId`) REFERENCES `repo`(`id`),
    FOREIGN KEY (`userId`) REFERENCES `user`(`id`)
);

drop table if exists `userToRepoGroup`;
create table `userToRepoGroup`
(
    `userId`    int(11) unsigned not null,
    `groupId`   int(11) unsigned not null,
    
    FOREIGN KEY (`userId`)  REFERENCES `user`(`id`),
    FOREIGN KEY (`groupId`) REFERENCES `repoGroup`(`id`)
);
