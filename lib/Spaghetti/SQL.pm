package Spaghetti::SQL;

our $thread =
{
    show => q{SELECT th.id, th.createAt, th.modifyAt, th.parentId,
                th.topicId, th.author, th.owner, t.`text`, t1.title,
                t1.url, u.name, u.mail, u.banId, n.legend, th.author,
                (
                SELECT COUNT(*) FROM `thread` a 
                    WHERE ( a.id = th.id )
                        AND a.id IN
                        (
                            SELECT `threadId` FROM `threadToDataType`
                            WHERE `dataTypeId` IN
                            (
                                SELECT `dataTypeId` FROM `access`
                                WHERE `RWCD` & 2 != 0 AND `groupId` IN
                                (
                                    SELECT `groupId` FROM `userToGroup`
                                    WHERE `userId` = ?
                                )
                            )
                        ) 
                ) as W
            FROM `thread` th
            LEFT OUTER JOIN `text`    t    ON ( th.textId    = t.id  )
            LEFT OUTER JOIN `topic`   t1   ON ( t1.threadId  = th.id )
            LEFT OUTER JOIN `user`    u    ON ( th.author    = u.id  )
            LEFT OUTER JOIN `news`    n    ON ( n.threadId   = th.id )
                WHERE ( th.topicId = ? or th.id = ? )
                    AND th.id IN
                        (
                            SELECT `threadId` FROM `threadToDataType`
                            WHERE `dataTypeId` IN
                            (
                                SELECT `dataTypeId` FROM `access`
                                WHERE `RWCD` & 1 != 0 AND `groupId` IN
                                (
                                    SELECT `groupId` FROM `userToGroup`
                                    WHERE `userId` = ?
                                )
                            )
                        )
                ORDER BY th.id ASC
                LIMIT ?, ?},
    showCount =>
    q{
        SELECT COUNT(*) AS count FROM `thread` th
            WHERE ( th.topicId = ? or th.id = ? )
                AND th.id IN
                    (
                        SELECT `threadId` FROM `threadToDataType`
                        WHERE `dataTypeId` IN
                        (
                            SELECT `dataTypeId` FROM `access`
                            WHERE `RWCD` & 1 != 0 AND `groupId` IN
                            (
                                SELECT `groupId` FROM `userToGroup`
                                WHERE `userId` = ?
                            )
                        )
                    )
    },
    tracker =>
    q{
        SELECT  th.id, th.createAt, th.modifyAt, th.parentId,
                th.topicId, th.owner, th.author, t1.title,
                t1.url, u.name, u.mail, u.banId,
                ( SELECT COUNT(thr.id)     FROM `thread`AS thr WHERE thr.topicId = th.id ) as count,
                ( SELECT MAX(thr.modifyAt) FROM `thread`AS thr
                    WHERE thr.topicId = th.id OR thr.id = th.id ) as latest
            FROM `thread` AS th
            INNER JOIN `topic` AS t1   ON ( t1.threadId  = th.id )
            INNER JOIN `user`  AS u    ON ( th.author    = u.id  )
                WHERE th.id IN
                (
                    SELECT `threadId` FROM `threadToDataType`
                    WHERE `dataTypeId` IN
                    (
                        SELECT `dataTypeId` FROM `access`
                        WHERE `RWCD` & 1 != 0 AND `groupId` IN
                        (
                            SELECT `groupId` FROM `userToGroup`
                            WHERE `userId` = ?
                        )
                    )
                )
                ORDER BY latest DESC
                LIMIT ?, ?
    },
    trackerCount =>
    q{
        SELECT COUNT(*) AS count FROM `thread` AS th
        INNER JOIN `topic` AS t1 ON ( t1.threadId  = th.id )
        WHERE th.id IN
        (
            SELECT `threadId` FROM `threadToDataType`
            WHERE `dataTypeId` IN
            (
                SELECT `dataTypeId` FROM `access`
                WHERE `RWCD` & 1 != 0 AND `groupId` IN
                (
                    SELECT `groupId` FROM `userToGroup`
                    WHERE `userId` = ?
                )
            )
        )
    },
};

our $news =
{   
    count =>
    q{
        SELECT COUNT(*) AS count FROM `thread` th
            WHERE th.topicId = ?
                AND th.id IN
                    (
                        SELECT `threadId` FROM `threadToDataType`
                        WHERE `dataTypeId` IN
                        (
                            SELECT `dataTypeId` FROM `access`
                            WHERE `RWCD` & 1 != 0 AND `groupId` IN
                            (
                                SELECT `groupId` FROM `userToGroup`
                                WHERE `userId` = ?
                            )
                        )
                    )
    },
    
    list =>
    q{
        SELECT th.id, th.createAt, th.modifyAt, th.parentId, t1.title,
                t1.url, n.legend,
                ( SELECT COUNT(*) FROM `thread` a WHERE ( a.topicId = th.id ) ) AS count
            FROM `news` n
            LEFT OUTER JOIN `thread`  th   ON ( n.threadId   = th.id )
            LEFT OUTER JOIN `topic`   t1   ON ( t1.threadId  = th.id )
                ORDER BY th.modifyAt DESC
                LIMIT ?, ?
    },
};

1;
