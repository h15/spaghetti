package Spaghetti::SQL;

our $thread =
{
    show => q{SELECT th.id, th.createAt, th.modifyAt, th.parentId,
                th.topicId, th.userId, t.`text`, t1.title,
                t1.url, u.name, u.mail, u.banId,
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
            LEFT OUTER JOIN `user`    u    ON ( th.userId    = u.id  )
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
};

1;
