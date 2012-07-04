package Spaghetti::SQL;

our $thread =
{
    search =>
        q{
            SELECT th.id, th.createAt, th.modifyAt, th.parentId, t1.prioritet,
                th.topicId, th.author, th.owner, t.`text`, t1.title,
                t1.url, u.name, u.mail, u.banId
            FROM `thread` th
                LEFT OUTER JOIN `text`    t    ON ( th.textId    = t.id  )
                LEFT OUTER JOIN `topic`   t1   ON ( t1.threadId  = th.id )
                LEFT OUTER JOIN `user`    u    ON ( th.author    = u.id  )
            WHERE th.id IN (%s)
                ORDER BY th.id ASC
        },
    
    index =>
        q{
            SELECT th.id, th.createAt, th.modifyAt, th.parentId, t1.prioritet,
                th.topicId, th.author, th.owner, t.`text`, t1.title,
                t1.url, u.name, u.mail, u.banId, th.author
            FROM `thread` th
            LEFT OUTER JOIN `text`    t    ON ( th.textId    = t.id  )
            LEFT OUTER JOIN `topic`   t1   ON ( t1.threadId  = th.id )
            LEFT OUTER JOIN `user`    u    ON ( th.author    = u.id  )
                WHERE ( th.topicId = ? )
                    AND th.id IN
                        (
                            SELECT `threadId` FROM `threadToDataType`
                            WHERE `dataTypeId` IN
                            (
                                SELECT `dataTypeId` FROM `access`
                                WHERE `RWCD` & 1 != 0 AND `groupId` IN
                                (
                                    SELECT `groupId` FROM `userToGroup`
                                    WHERE `userId` = 0
                                )
                            )
                        )
                ORDER BY t1.prioritet DESC
                LIMIT ?, ?
        },
    
    show => q{SELECT th.id, th.createAt, th.modifyAt, th.parentId, t1.prioritet,
                th.topicId, th.author, th.owner, t.`text`, t1.title,
                t1.url, u.name, u.mail, u.banId, th.author,
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
                WHERE ( th.topicId = ? )
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
    
    show_desc =>
        q{
            SELECT th.id, th.createAt, th.modifyAt, th.parentId,
                th.topicId, th.author, th.owner, t.`text`, t1.title,
                t1.url, u.name, u.mail, u.banId, th.author,
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
                WHERE ( th.topicId = ? )
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
                ORDER BY th.id DESC
                LIMIT ?, ?
        },

    show_topic => q{
            SELECT th.id, th.createAt, th.modifyAt, th.parentId,
                th.topicId, th.author, th.owner, t.`text`, t1.title,
                t1.url, t1.treeOfTree, u.name, u.mail, u.banId, n.legend,
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
                WHERE ( th.id = ? )
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
                LIMIT 1
        },
    
    show_admin => q{SELECT th.id, th.createAt, th.modifyAt, th.parentId,
                        th.topicId, th.author, t.`text`, t1.title,
                        t1.url, u.name, u.mail, u.banId
                    FROM `thread` th
                    LEFT OUTER JOIN `text`    t    ON ( th.textId    = t.id  )
                    LEFT OUTER JOIN `topic`   t1   ON ( t1.threadId  = th.id )
                    LEFT OUTER JOIN `user`    u    ON ( th.author    = u.id  )
                        ORDER BY t1.threadId, th.id DESC
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
                    WHERE thr.topicId = th.id OR thr.id = th.id ) AS latest,
                ( SELECT CONCAT(u.id , ',' , u.name, ',' , u.mail)
                    FROM `thread` AS last
                    INNER JOIN `user` AS u ON ( last.author = u.id  )
                        WHERE last.topicId = th.id OR last.id = th.id
                        ORDER BY last.id DESC LIMIT 1 ) AS luser
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

our $user =
{
    private_thread =>
    q{
        SELECT th.id, th.createAt, th.modifyAt, th.parentId,
            th.topicId, th.author, t.`text`, t1.title, t1.url
        FROM `thread` th
        LEFT OUTER JOIN `text`    t    ON ( th.textId    = t.id  )
        LEFT OUTER JOIN `topic`   t1   ON ( t1.threadId  = th.id )
            WHERE ( th.topicId = ? or th.id = ? )
            ORDER BY t1.threadId, th.id DESC
            LIMIT ?, ?
    },
    
    responses =>
    q{
        SELECT r.id AS rid, r.createAt AS rcreateAt, rt.`text` AS rtext,
               m.id AS mid, m.createAt, m.modifyAt, mt.`text`,
               u.name, u.mail, u.id AS userId, u.banId,
               t1.title, t1.url,
               resp.id
        FROM responses AS resp
            INNER JOIN `thread` r ON (r.id = resp.response)
                INNER JOIN `text` rt ON (rt.id = r.textId)
            INNER JOIN `thread` m ON (m.id = resp.message)
                INNER JOIN `text` mt ON (mt.id = m.textId)
            INNER JOIN `user`   u ON (u.id = r.author)
            LEFT OUTER JOIN `topic` t1 ON (t1.threadId  = r.topicId)
        WHERE resp.userId = ?
            ORDER BY resp.id ASC
            LIMIT ?, ?
    },
    
    private_thread_count =>
    q{
        SELECT COUNT(*) AS count
        FROM `thread` th
            WHERE th.topicId = ? or th.id = ?
    },
    
    inc_responses =>
    q{
        UPDATE `userInfo` SET `responses` = `responses` + 1 WHERE `id` = ?
    },
    
    my_projects =>
    q{
        SELECT p.id, p.title, p.repos, p.url,
               th.createAt, th.modifyAt, th.parentId,
               th.topicId, th.owner, th.author
        FROM `project` AS p
        INNER JOIN `thread` AS th ON ( p.id = th.id )
        WHERE th.owner = ?
        ORDER BY th.modifyAt DESC
    },
    
    my_items =>
    q{
        SELECT i.id, i.name, i.desc
        FROM `item` AS i
        WHERE i.id IN
        (
            SELECT itemId
            FROM `userToItem`
            WHERE userId = ?
        )
        ORDER BY i.name ASC
    },
};

our $project =
{
    read =>
    q{
        SELECT p.id, p.title, p.repos, p.maxRepo, p.url,
               th.createAt, th.modifyAt, th.parentId,
               th.topicId, th.owner, th.textId, th.author,
               tx.`text`,
               u.`name`, u.mail, u.banId
        FROM `project` AS p
            INNER JOIN `thread` AS th ON ( p.id = th.id )
            INNER JOIN `text`   AS tx ON ( th.textId = tx.id )
            INNER JOIN `user`   AS u  ON ( u.id = th.owner )
        WHERE p.url = ?
    },
    listByAbc =>
    q{
        SELECT p.id, p.title, p.repos, p.url,
               th.createAt, th.modifyAt
        FROM `project` AS p
            INNER JOIN `thread` AS th ON ( p.id = th.id )
        WHERE p.url LIKE ?
        ORDER BY p.title LIMIT ?, ?
    },
};

our $repo =
{
    list =>
    q{
        SELECT th.id, th.modifyAt, th.createAt, th.owner, th.author,
               tx.text,
               r.title, r.url,
               u.name, u.mail, u.banId
        FROM `repo` AS r
            INNER JOIN `thread` AS th ON ( r.id = th.id )
            INNER JOIN `text`   AS tx ON ( th.textId = tx.id )
            INNER JOIN `user`   AS u  ON ( u.id = th.owner )
        WHERE th.parentId = ?
        ORDER BY th.modifyAt DESC
    },
    
    read =>
    q{
        SELECT r.id, r.title, r.url,
               th.createAt, th.modifyAt, th.parentId,
               th.topicId, th.textId, th.owner, th.author,
               tx.text,
               p.url AS projectUrl,
               u.name, u.mail, u.banId
        FROM `repo` AS r
            INNER JOIN `thread` AS th ON ( r.id = th.id )
            INNER JOIN `text`   AS tx ON ( th.textId = tx.id )
            INNER JOIN `user`   AS u  ON ( u.id = th.owner )
            INNER JOIN `project`AS p  ON ( p.id = th.topicId )
        WHERE r.url = ? AND p.url = ?
    },
    
    userAccessList =>
    q{
        SELECT a.rwpcd, a.userId,
               u.`name`, u.mail, u.banId, u.id
        FROM `repoRightsViaUser` AS a
            INNER JOIN `user` AS u ON ( u.id = a.userId )
        WHERE a.repoId = ?
            ORDER BY u.`name`
    },
};

1;
